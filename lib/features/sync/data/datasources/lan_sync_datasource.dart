import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';
import 'package:clipboard/features/macos/index/domain/repositories/clipboard_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/sync_clipboard_item.dart';
import '../../domain/entities/sync_hub_state.dart';
import '../../domain/entities/sync_peer.dart';
import '../mappers/sync_clipboard_mapper.dart';

class LanSyncDatasource {
  LanSyncDatasource({
    required this.clipboardRepository,
    required this.preferences,
  });

  static const protocolVersion = 1;
  static const servicePort = 48482;
  static const discoveryPort = 48483;
  static const _discoveryMessage = 'CLIPSYNC_DISCOVER_V1';
  static const _savedPeerKey = 'sync.saved_peer.v1';
  static const _trustedClientsKey = 'sync.trusted_clients.v1';

  final ClipboardRepository clipboardRepository;
  final SharedPreferences preferences;
  final _hubController = StreamController<SyncHubState>.broadcast();
  final Map<String, SyncPeer> _clients = {};
  final Map<String, List<SyncClipboardItem>> _clientHistories = {};
  final Map<String, List<SyncClipboardItem>> _outboxes = {};
  final String _hubId = _randomToken(12);
  final String _pairCode =
      (100000 + Random.secure().nextInt(900000)).toString();
  HttpServer? _server;
  RawDatagramSocket? _discoverySocket;
  List<String> _addresses = const [];

  Stream<SyncHubState> get hubStates => _hubController.stream;

  Future<SyncHubState> startHub() async {
    if (_server != null) return _state;
    _loadTrustedClients();
    _addresses = await _localAddresses();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, servicePort);
    _server!.listen(_handleRequest);
    _discoverySocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      discoveryPort,
      reuseAddress: true,
      reusePort: Platform.isMacOS,
    );
    _discoverySocket!.listen(_handleDiscovery);
    _emitState();
    return _state;
  }

  Future<void> stopHub() async {
    _discoverySocket?.close();
    _discoverySocket = null;
    await _server?.close(force: true);
    _server = null;
    _emitState();
  }

  SyncHubState get _state => SyncHubState(
        running: _server != null,
        pairCode: _pairCode,
        addresses: _addresses,
        connectedPeers: _clients.values.toList(growable: false),
        peerHistories: Map.unmodifiable(_clientHistories),
      );

  void _emitState() => _hubController.add(_state);

  void _handleDiscovery(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _discoverySocket?.receive();
    if (datagram == null || utf8.decode(datagram.data) != _discoveryMessage)
      return;
    final response = utf8.encode(jsonEncode(_hubInfo()));
    _discoverySocket?.send(response, datagram.address, datagram.port);
  }

  Future<List<SyncPeer>> discoverHubs() async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    final peers = <String, SyncPeer>{};
    final subscription = socket.listen((event) {
      if (event != RawSocketEvent.read) return;
      final datagram = socket.receive();
      if (datagram == null) return;
      try {
        final json =
            jsonDecode(utf8.decode(datagram.data)) as Map<String, dynamic>;
        final peer = SyncPeer.fromJson(json, datagram.address.address);
        peers[peer.id] = peer;
      } catch (_) {}
    });
    socket.send(utf8.encode(_discoveryMessage),
        InternetAddress('255.255.255.255'), discoveryPort);
    final localAddresses = await _localAddresses();
    for (final address in localAddresses) {
      final parts = address.split('.');
      if (parts.length == 4) {
        parts[3] = '255';
        socket.send(utf8.encode(_discoveryMessage),
            InternetAddress(parts.join('.')), discoveryPort);
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    await subscription.cancel();
    socket.close();
    if (peers.isNotEmpty) return peers.values.toList();

    for (final address in localAddresses) {
      final discovered = await _scan24Subnet(address);
      for (final peer in discovered) {
        peers[peer.id] = peer;
      }
    }
    return peers.values.toList();
  }

  Future<List<SyncPeer>> _scan24Subnet(String localAddress) async {
    final parts = localAddress.split('.');
    if (parts.length != 4) return const [];
    final prefix = '${parts[0]}.${parts[1]}.${parts[2]}';
    final peers = <SyncPeer>[];
    const batchSize = 32;
    for (var start = 1; start <= 254; start += batchSize) {
      final end = min(start + batchSize - 1, 254);
      final results = await Future.wait([
        for (var suffix = start; suffix <= end; suffix++)
          _probeHub('$prefix.$suffix'),
      ]);
      peers.addAll(results.whereType<SyncPeer>());
    }
    return peers;
  }

  Future<SyncPeer?> _probeHub(String host) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 450)
      ..findProxy = (_) => 'DIRECT';
    try {
      final request = await client
          .getUrl(Uri.parse('http://$host:$servicePort/v1/info'))
          .timeout(const Duration(milliseconds: 550));
      final response = await request.close().timeout(
            const Duration(milliseconds: 550),
          );
      if (response.statusCode != HttpStatus.ok) return null;
      final json = jsonDecode(await utf8.decoder.bind(response).join())
          as Map<String, dynamic>;
      if (json['protocol'] != protocolVersion) return null;
      return SyncPeer.fromJson(json, host);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  Future<SyncPeer> inspectHub(String host) async {
    final json = await _request(host, servicePort, 'GET', '/v1/info');
    return SyncPeer.fromJson(json, host);
  }

  Future<SyncPeer> pair(SyncPeer peer, String code) async {
    final response =
        await _request(peer.host, peer.port, 'POST', '/v1/pair', body: {
      'code': code,
      'device': {
        'id': _deviceId,
        'name': Platform.localHostname,
        'platform': Platform.operatingSystem,
      }
    });
    final paired = peer.copyWith(token: response['token'] as String);
    await preferences.setString(_savedPeerKey, jsonEncode(paired.toJson()));
    return paired;
  }

  Future<SyncPeer?> savedPeer() async {
    final value = preferences.getString(_savedPeerKey);
    if (value == null) return null;
    try {
      return SyncPeer.fromStoredJson(jsonDecode(value) as Map<String, dynamic>);
    } catch (_) {
      await preferences.remove(_savedPeerKey);
      return null;
    }
  }

  Future<List<SyncClipboardItem>> remoteHistory(SyncPeer peer) async {
    final response = await _request(peer.host, peer.port, 'GET', '/v1/history',
        token: peer.token);
    return (response['items'] as List)
        .map((item) => SyncClipboardItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> push(SyncPeer peer, List<SyncClipboardItem> items) async {
    final response = await _request(peer.host, peer.port, 'POST', '/v1/sync',
        token: peer.token,
        body: {'items': items.map((item) => item.toJson()).toList()});
    return (response['accepted'] as num).toInt();
  }

  Future<List<SyncClipboardItem>> fetch(SyncPeer peer, Set<String> ids) async {
    final response = await _request(peer.host, peer.port, 'POST', '/v1/fetch',
        token: peer.token, body: {'ids': ids.toList()});
    return (response['items'] as List)
        .map((item) => SyncClipboardItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> queueForPairedDevices(SyncClipboardItem item) async {
    final payload = await _withPayload(item);
    for (final clientKey in _clients.keys) {
      _outboxes.putIfAbsent(clientKey, () => []).add(payload);
    }
  }

  Future<List<SyncClipboardItem>> receiveQueued(SyncPeer peer) async {
    final response = await _request(peer.host, peer.port, 'GET', '/v1/inbox',
        token: peer.token);
    return (response['items'] as List)
        .map((item) => SyncClipboardItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> publishHistory(
      SyncPeer peer, List<SyncClipboardItem> items) async {
    await _request(peer.host, peer.port, 'POST', '/v1/catalog',
        token: peer.token,
        body: {'items': items.map((item) => item.toJson()).toList()});
  }

  Future<Map<String, dynamic>> _request(
      String host, int port, String method, String path,
      {String? token, Map<String, dynamic>? body}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 4)
      ..findProxy = (_) => 'DIRECT';
    try {
      final request =
          await client.openUrl(method, Uri.parse('http://$host:$port$path'));
      request.headers.contentType = ContentType.json;
      if (token != null) request.headers.set('Authorization', 'Bearer $token');
      if (body != null) request.write(jsonEncode(body));
      final response =
          await request.close().timeout(const Duration(minutes: 2));
      final text = await utf8.decoder.bind(response).join();
      final json = text.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(text) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        throw SyncNetworkException(json['message'] as String? ?? '连接失败');
      }
      return json;
    } on SocketException catch (error) {
      throw SyncNetworkException(
          '无法连接 $host:$port（${error.osError?.message ?? error.message}）。请确认使用 Mac 当前 Wi-Fi IP，并关闭两端 VPN 或代理后重试');
    } on TimeoutException {
      throw SyncNetworkException(
          '连接 $host:$port 超时。请确认 iPhone 与 Mac 在同一 Wi-Fi，且路由器未开启设备隔离');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.method == 'GET' && request.uri.path == '/v1/info') {
        return _json(request.response, 200, _hubInfo());
      }
      if (request.method == 'POST' && request.uri.path == '/v1/pair') {
        final body = await _readBody(request);
        if (body['code'] != _pairCode) {
          return _json(request.response, 403, {'message': '配对码错误'});
        }
        final device = body['device'] as Map<String, dynamic>;
        final token = _randomToken(32);
        final peer = SyncPeer(
          id: device['id'] as String,
          name: device['name'] as String,
          platform: device['platform'] as String,
          host: request.connectionInfo?.remoteAddress.address ?? '',
          port: 0,
        );
        _clients[_tokenHash(token)] = peer;
        await _saveTrustedClients();
        _emitState();
        return _json(request.response, 200, {'token': token});
      }
      if (!_authorized(request)) {
        return _json(request.response, 401, {'message': '设备未配对'});
      }
      if (request.method == 'GET' && request.uri.path == '/v1/history') {
        final entries = await clipboardRepository.getActiveEntries(
            filter: 'all', keyword: '', limit: 200);
        final items = entries
            .map((entry) => entry.toSyncItem())
            .map((e) => e.toJson())
            .toList();
        return _json(request.response, 200, {'items': items});
      }
      if (request.method == 'GET' && request.uri.path == '/v1/inbox') {
        final token = request.headers.value('Authorization')!.substring(7);
        final items = _outboxes.remove(_tokenHash(token)) ?? const [];
        return _json(request.response, 200,
            {'items': items.map((item) => item.toJson()).toList()});
      }
      if (request.method == 'POST' && request.uri.path == '/v1/catalog') {
        final body = await _readBody(request);
        final token = request.headers.value('Authorization')!.substring(7);
        final peer = _clients[_tokenHash(token)]!;
        _clientHistories[peer.id] = (body['items'] as List)
            .map((item) =>
                SyncClipboardItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _emitState();
        return _json(request.response, 200, {'published': true});
      }
      if (request.method == 'POST' && request.uri.path == '/v1/fetch') {
        final body = await _readBody(request);
        final ids = Set<String>.from(body['ids'] as List);
        final entries = await clipboardRepository.getActiveEntries(
            filter: 'all', keyword: '', limit: 200);
        final items = <Map<String, dynamic>>[];
        for (final entry in entries.where((entry) => ids.contains(entry.id))) {
          items.add((await _withPayload(entry.toSyncItem())).toJson());
        }
        return _json(request.response, 200, {'items': items});
      }
      if (request.method == 'POST' && request.uri.path == '/v1/sync') {
        final body = await _readBody(request);
        final items = (body['items'] as List)
            .map((e) => SyncClipboardItem.fromJson(e as Map<String, dynamic>));
        var accepted = 0;
        for (final item in items.where((item) => item.canTransfer)) {
          await saveRemoteItem(item);
          accepted++;
        }
        return _json(request.response, 200, {'accepted': accepted});
      }
      _json(request.response, 404, {'message': '接口不存在'});
    } catch (error) {
      _json(request.response, 500, {'message': error.toString()});
    }
  }

  bool _authorized(HttpRequest request) {
    final header = request.headers.value('Authorization');
    return header?.startsWith('Bearer ') == true &&
        _clients.containsKey(_tokenHash(header!.substring(7)));
  }

  void _loadTrustedClients() {
    final value = preferences.getString(_trustedClientsKey);
    if (value == null) return;
    try {
      final entries = jsonDecode(value) as List;
      for (final entry in entries.cast<Map<String, dynamic>>()) {
        _clients[entry['tokenHash'] as String] =
            SyncPeer.fromStoredJson(entry['peer'] as Map<String, dynamic>);
      }
    } catch (_) {
      preferences.remove(_trustedClientsKey);
    }
  }

  Future<void> _saveTrustedClients() => preferences.setString(
        _trustedClientsKey,
        jsonEncode(_clients.entries
            .map((entry) => {
                  'tokenHash': entry.key,
                  'peer': entry.value.toJson(includeToken: false),
                })
            .toList()),
      );

  Future<SyncClipboardItem> _withPayload(SyncClipboardItem item) async {
    if (item.type == 'text') return item;
    final path = item.filePath;
    if (path == null) throw const SyncNetworkException('文件不存在');
    final resolvedPath = path.startsWith('/')
        ? path
        : '${(await getApplicationSupportDirectory()).path}/$path';
    final file = File(resolvedPath);
    if (!await file.exists()) throw const SyncNetworkException('文件不存在');
    return item.copyWith(dataBase64: base64Encode(await file.readAsBytes()));
  }

  Future<List<SyncClipboardItem>> withPayloads(
      List<SyncClipboardItem> items) async {
    final result = <SyncClipboardItem>[];
    for (final item in items) {
      result.add(await _withPayload(item));
    }
    return result;
  }

  Future<void> saveRemoteItem(SyncClipboardItem item) async {
    final bytes = item.type == 'text'
        ? utf8.encode(item.textContent!)
        : base64Decode(item.dataBase64 ?? '');
    if (bytes.isEmpty) throw const SyncNetworkException('收到的文件内容为空');
    final hash = sha256.convert(bytes).toString();
    final now = DateTime.now().millisecondsSinceEpoch;
    String? filePath;
    if (item.type != 'text') {
      final root = await getApplicationSupportDirectory();
      final directory = Directory('${root.path}/sync_files');
      await directory.create(recursive: true);
      final safeName = (item.fileName ?? item.title).split('/').last;
      filePath = '${directory.path}/$hash-$safeName';
      await File(filePath).writeAsBytes(bytes, flush: true);
    }
    await clipboardRepository.insertEntry(ClipboardEntry(
      id: 'sync-$hash',
      seq: await clipboardRepository.getMaxSeq() + 1,
      type: item.type,
      title: item.title,
      preview: item.type == 'text' ? item.textContent : item.fileName,
      textContent: item.type == 'text' ? item.textContent : null,
      hash: hash,
      sizeBytes: bytes.length,
      favorite: 0,
      sourceDevice: item.sourceDevice ?? '局域网设备',
      createdAt: now,
      updatedAt: now,
      deleted: 0,
      filePath: filePath,
    ));
  }

  Future<Map<String, dynamic>> _readBody(HttpRequest request) async =>
      jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>;

  Map<String, dynamic> _hubInfo() => {
        'protocol': protocolVersion,
        'id': _hubId,
        'name': Platform.localHostname,
        'platform': Platform.operatingSystem,
        'port': servicePort,
      };

  void _json(HttpResponse response, int status, Map<String, dynamic> body) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    response.close();
  }

  static String get _deviceId =>
      '${Platform.operatingSystem}-${Platform.localHostname}';

  static String _randomToken(int bytes) {
    final random = Random.secure();
    return base64Url
        .encode(List.generate(bytes, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }

  static String _tokenHash(String token) =>
      sha256.convert(utf8.encode(token)).toString();

  static Future<List<String>> _localAddresses() async {
    final interfaces =
        await NetworkInterface.list(type: InternetAddressType.IPv4);
    final candidates = <({String interface, String address})>[];
    for (final interface in interfaces) {
      final name = interface.name.toLowerCase();
      if (name.startsWith('bridge') ||
          name.startsWith('utun') ||
          name.startsWith('awdl') ||
          name.startsWith('llw') ||
          name.startsWith('anpi') ||
          name == 'lo0') {
        continue;
      }
      for (final address in interface.addresses) {
        final value = address.address;
        if (!address.isLoopback && _isPrivateAddress(value)) {
          candidates.add((interface: name, address: value));
        }
      }
    }
    candidates.sort((a, b) {
      final aPriority = a.interface == 'en0' ? 0 : 1;
      final bPriority = b.interface == 'en0' ? 0 : 1;
      return aPriority.compareTo(bPriority);
    });
    return candidates.map((item) => item.address).toSet().toList();
  }

  static bool _isPrivateAddress(String address) {
    final parts = address.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final first = parts[0]!;
    final second = parts[1]!;
    return first == 10 ||
        (first == 172 && second >= 16 && second <= 31) ||
        (first == 192 && second == 168);
  }
}

class SyncNetworkException implements Exception {
  const SyncNetworkException(this.message);
  final String message;
  @override
  String toString() => message;
}
