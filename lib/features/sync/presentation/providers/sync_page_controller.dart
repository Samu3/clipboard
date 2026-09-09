import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../../domain/entities/sync_clipboard_item.dart';
import '../../domain/entities/sync_peer.dart';
import 'sync_providers.dart';

class SyncPageState {
  const SyncPageState({
    this.discovered = const [],
    this.peer,
    this.localItems = const [],
    this.remoteItems = const [],
    this.selectedLocal = const {},
    this.selectedRemote = const {},
    this.busy = false,
    this.message,
  });

  final List<SyncPeer> discovered;
  final SyncPeer? peer;
  final List<SyncClipboardItem> localItems;
  final List<SyncClipboardItem> remoteItems;
  final Set<String> selectedLocal;
  final Set<String> selectedRemote;
  final bool busy;
  final String? message;

  SyncPageState copyWith({
    List<SyncPeer>? discovered,
    SyncPeer? peer,
    List<SyncClipboardItem>? localItems,
    List<SyncClipboardItem>? remoteItems,
    Set<String>? selectedLocal,
    Set<String>? selectedRemote,
    bool? busy,
    String? message,
    bool clearMessage = false,
  }) =>
      SyncPageState(
        discovered: discovered ?? this.discovered,
        peer: peer ?? this.peer,
        localItems: localItems ?? this.localItems,
        remoteItems: remoteItems ?? this.remoteItems,
        selectedLocal: selectedLocal ?? this.selectedLocal,
        selectedRemote: selectedRemote ?? this.selectedRemote,
        busy: busy ?? this.busy,
        message: clearMessage ? null : message ?? this.message,
      );
}

class SyncPageController extends StateNotifier<SyncPageState> {
  SyncPageController(this.ref) : super(const SyncPageState());
  final Ref ref;

  Future<void> restoreSavedConnection() {
    if (state.peer != null || state.busy) return Future.value();
    return _run(() async {
      final repository = ref.read(syncRepositoryProvider);
      final peer = await repository.savedPeer();
      if (peer == null) return;
      await repository.receiveQueued(peer);
      final local = await repository.localHistory();
      final remote = await repository.remoteHistory(peer);
      await repository.publishLocalHistory(peer);
      state = state.copyWith(
        peer: peer,
        localItems: local,
        remoteItems: remote,
        selectedLocal: {},
        selectedRemote: {},
        message: '已自动连接 ${peer.name}',
      );
    });
  }

  Future<void> discover() => _run(() async {
        final peers = await ref.read(syncRepositoryProvider).discoverHubs();
        state = state.copyWith(
            discovered: peers,
            message: peers.isEmpty
                ? '未发现服务中心，可输入 Mac IP'
                : '已发现 ${peers.length} 台设备');
      });

  Future<void> connect(String host, String code, {SyncPeer? discovered}) {
    if (host.trim().isEmpty || code.trim().length != 6) {
      state = state.copyWith(message: '请输入 Mac IP 和 6 位配对码');
      return Future.value();
    }
    return _run(() async {
      final repository = ref.read(syncRepositoryProvider);
      final target = discovered ?? await repository.inspectHub(host.trim());
      final paired = await repository.pair(target, code.trim());
      await repository.receiveQueued(paired);
      final local = await repository.localHistory();
      final remote = await repository.remoteHistory(paired);
      await repository.publishLocalHistory(paired);
      state = state.copyWith(
        peer: paired,
        localItems: local,
        remoteItems: remote,
        selectedLocal: {},
        selectedRemote: {},
        message: '已连接 ${paired.name}',
      );
    });
  }

  void toggleLocal(String id) =>
      state = state.copyWith(selectedLocal: _toggle(state.selectedLocal, id));

  void toggleRemote(String id) =>
      state = state.copyWith(selectedRemote: _toggle(state.selectedRemote, id));

  Future<void> push() => _run(() async {
        final count = await ref
            .read(syncRepositoryProvider)
            .pushToRemote(state.peer!, state.selectedLocal);
        state = state.copyWith(
            selectedLocal: {}, message: '已向 ${state.peer!.name} 同步 $count 条文本');
        await refresh();
      });

  Future<void> pull() => _run(() async {
        final count = await ref.read(syncRepositoryProvider).pullFromRemote(
            state.peer!, state.remoteItems, state.selectedRemote);
        state =
            state.copyWith(selectedRemote: {}, message: '已保存 $count 条文本到本机');
        await refresh();
      });

  Future<void> chooseAndSend({required bool images}) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: images ? FileType.image : FileType.any,
      withData: Platform.isIOS,
    );
    if (result == null || result.files.isEmpty) return;
    await _run(() async {
      final repository = ref.read(syncRepositoryProvider);
      final importedIds = <String>{};
      for (final picked in result.files) {
        final bytes = picked.bytes ??
            (picked.path == null
                ? null
                : await File(picked.path!).readAsBytes());
        if (bytes == null) continue;
        final item = await repository.importAsset(
            name: picked.name, bytes: bytes, image: images);
        importedIds.add(item.id);
      }
      final count = await repository.pushToRemote(state.peer!, importedIds);
      state = state.copyWith(message: '已发送 $count 个${images ? '图片' : '文件'}');
      await refresh();
    });
  }

  Future<void> refresh() async {
    final peer = state.peer;
    if (peer == null) return;
    final repository = ref.read(syncRepositoryProvider);
    final received = await repository.receiveQueued(peer);
    state = state.copyWith(
      localItems: await repository.localHistory(),
      remoteItems: await repository.remoteHistory(peer),
    );
    await repository.publishLocalHistory(peer);
    if (received > 0) {
      state = state.copyWith(message: '已接收 $received 个来自 ${peer.name} 的项目');
    }
  }

  Future<void> _run(Future<void> Function() operation) async {
    if (state.busy) return;
    state = state.copyWith(busy: true, clearMessage: true);
    try {
      await operation();
    } catch (error) {
      state = state.copyWith(message: error.toString());
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Set<String> _toggle(Set<String> source, String id) {
    final result = Set<String>.from(source);
    result.contains(id) ? result.remove(id) : result.add(id);
    return result;
  }
}

final syncPageControllerProvider =
    StateNotifierProvider<SyncPageController, SyncPageState>(
        (ref) => SyncPageController(ref));
