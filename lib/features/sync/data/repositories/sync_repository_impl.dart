import 'package:clipboard/features/macos/index/domain/entities/clipboard_entry.dart';
import 'package:clipboard/features/macos/index/domain/repositories/clipboard_repository.dart';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/sync_clipboard_item.dart';
import '../../domain/entities/sync_hub_state.dart';
import '../../domain/entities/sync_peer.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/lan_sync_datasource.dart';
import '../mappers/sync_clipboard_mapper.dart';

class SyncRepositoryImpl implements SyncRepository {
  const SyncRepositoryImpl({
    required this.datasource,
    required this.clipboardRepository,
  });

  final LanSyncDatasource datasource;
  final ClipboardRepository clipboardRepository;

  @override
  Stream<SyncHubState> get hubStates => datasource.hubStates;

  @override
  Future<SyncHubState> startHub() => datasource.startHub();

  @override
  Future<void> stopHub() => datasource.stopHub();

  @override
  Future<List<SyncPeer>> discoverHubs() => datasource.discoverHubs();

  @override
  Future<SyncPeer> inspectHub(String host) => datasource.inspectHub(host);

  @override
  Future<SyncPeer> pair(SyncPeer peer, String code) =>
      datasource.pair(peer, code);

  @override
  Future<SyncPeer?> savedPeer() => datasource.savedPeer();

  @override
  Future<List<SyncClipboardItem>> localHistory() async {
    final entries = await clipboardRepository.getActiveEntries(
        filter: 'all', keyword: '', limit: 200);
    return entries.map((entry) => entry.toSyncItem()).toList();
  }

  @override
  Future<List<SyncClipboardItem>> remoteHistory(SyncPeer peer) =>
      datasource.remoteHistory(peer);

  @override
  Future<void> publishLocalHistory(SyncPeer peer) async {
    await datasource.publishHistory(peer, await localHistory());
  }

  @override
  Future<int> pushToRemote(SyncPeer peer, Set<String> ids) async {
    final local = await localHistory();
    final selected = local
        .where((item) => ids.contains(item.id) && item.canTransfer)
        .toList();
    return datasource.push(peer, await datasource.withPayloads(selected));
  }

  @override
  Future<int> pullFromRemote(
      SyncPeer peer, List<SyncClipboardItem> items, Set<String> ids) async {
    var accepted = 0;
    final selected = items
        .where((item) => ids.contains(item.id) && item.canTransfer)
        .toList();
    final fetched = peer.token == null
        ? selected.where((item) => item.type == 'text').toList()
        : await datasource.fetch(peer, selected.map((e) => e.id).toSet());
    for (final item in fetched) {
      await datasource.saveRemoteItem(item);
      accepted++;
    }
    return accepted;
  }

  @override
  Future<SyncClipboardItem> importAsset({
    required String name,
    required List<int> bytes,
    required String type,
  }) async {
    final hash = sha256.convert(bytes).toString();
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/sync_files');
    await directory.create(recursive: true);
    final safeName = name.split('/').last;
    final path = '${directory.path}/$hash-$safeName';
    await File(path).writeAsBytes(bytes, flush: true);
    final now = DateTime.now().millisecondsSinceEpoch;
    final entry = ClipboardEntry(
      id: 'import-$hash',
      seq: await clipboardRepository.getMaxSeq() + 1,
      type: type,
      title: safeName,
      preview: safeName,
      hash: hash,
      sizeBytes: bytes.length,
      favorite: 0,
      sourceDevice: Platform.isIOS ? 'iPhone' : Platform.localHostname,
      createdAt: now,
      updatedAt: now,
      deleted: 0,
      filePath: path,
    );
    await clipboardRepository.insertEntry(entry);
    return entry.toSyncItem();
  }

  @override
  Future<void> queueForPairedDevices(SyncClipboardItem item) =>
      datasource.queueForPairedDevices(item);

  @override
  Future<int> receiveQueued(SyncPeer peer) async {
    final items = await datasource.receiveQueued(peer);
    for (final item in items) {
      await datasource.saveRemoteItem(item);
    }
    return items.length;
  }
}
