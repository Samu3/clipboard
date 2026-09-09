import 'dart:io';
import 'package:clipboard/features/ios/iphone_clipboard_page.dart';
import 'package:clipboard/features/sync/presentation/pages/sync_page.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:clipboard/features/macos/index/pages/mac_index.dart';
import 'package:clipboard/features/macos/settings/pages/settings_page.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter goRouter(GoRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) =>
            Platform.isIOS ? const IphoneClipboardPage() : const MacIndex(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/sync',
        name: 'sync',
        builder: (context, state) => const SyncPage(),
      ),
    ],
  );
}

final goRouterStackDepthProvider = Provider<int>((ref) {
  final goRouter = ref.watch(goRouterProvider);
  // matches：路由匹配栈，每push一个页面数量+1
  final matches = goRouter.routerDelegate.currentConfiguration.matches;
  return matches.length;
});
