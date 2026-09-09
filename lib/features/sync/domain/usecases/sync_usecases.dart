import '../entities/sync_clipboard_item.dart';
import '../entities/sync_peer.dart';
import '../repositories/sync_repository.dart';

class PairDevice {
  const PairDevice(this.repository);
  final SyncRepository repository;
  Future<SyncPeer> call(SyncPeer peer, String code) =>
      repository.pair(peer, code);
}

class SyncSelectedItems {
  const SyncSelectedItems(this.repository);
  final SyncRepository repository;
  Future<int> push(SyncPeer peer, Set<String> ids) =>
      repository.pushToRemote(peer, ids);
  Future<int> pull(
          SyncPeer peer, List<SyncClipboardItem> items, Set<String> ids) =>
      repository.pullFromRemote(peer, items, ids);
}
