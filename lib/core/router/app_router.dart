import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:unique_health/features/water/pages/water_page.dart';
import 'package:unique_health/features/water/pages/water_record_page.dart';
part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter goRouter(GoRouterRef ref) {
  return GoRouter(
    initialLocation: '/water',
    routes: [
      // GoRoute(
      //   path: '/',
      //   name: 'home',
      //   builder: (context, state) => const HomePage(),
      // ),
      GoRoute(
        path: '/water',
        name: 'water',
        builder: (context, state) => const WaterPage(),
      ),
      GoRoute(
        path: '/water/record',
        name: 'waterRecord',
        builder: (context, state) => const WaterRecordPage(),
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
