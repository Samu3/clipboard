import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:clipboard/features/macos/index/pages/mac_index.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter goRouter(GoRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const MacIndex(),
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
