import 'sync_peer.dart';
import 'sync_clipboard_item.dart';

class SyncHubState {
  const SyncHubState({
    required this.running,
    required this.pairCode,
    required this.addresses,
    required this.connectedPeers,
    required this.peerHistories,
  });

  const SyncHubState.stopped()
      : running = false,
        pairCode = '',
        addresses = const [],
        connectedPeers = const [],
        peerHistories = const {};

  final bool running;
  final String pairCode;
  final List<String> addresses;
  final List<SyncPeer> connectedPeers;
  final Map<String, List<SyncClipboardItem>> peerHistories;
}
