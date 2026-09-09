import '../entities/sync_clipboard_item.dart';
import '../entities/sync_hub_state.dart';
import '../entities/sync_peer.dart';

abstract class SyncRepository {
  Stream<SyncHubState> get hubStates;
  Future<SyncHubState> startHub();
  Future<void> stopHub();
  Future<List<SyncPeer>> discoverHubs();
  Future<SyncPeer> inspectHub(String host);
  Future<SyncPeer> pair(SyncPeer peer, String code);
  Future<SyncPeer?> savedPeer();
  Future<List<SyncClipboardItem>> localHistory();
  Future<List<SyncClipboardItem>> remoteHistory(SyncPeer peer);
  Future<void> publishLocalHistory(SyncPeer peer);
  Future<int> pushToRemote(SyncPeer peer, Set<String> ids);
  Future<int> pullFromRemote(
      SyncPeer peer, List<SyncClipboardItem> items, Set<String> ids);
  Future<SyncClipboardItem> importAsset({
    required String name,
    required List<int> bytes,
    required String type,
  });
  Future<void> queueForPairedDevices(SyncClipboardItem item);
  Future<int> receiveQueued(SyncPeer peer);
}
