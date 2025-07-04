import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:inteagle_app/router/routes.dart';
import 'package:inteagle_app/layout/layout_page.dart';
import 'package:inteagle_app/pages/device_discover/device_save_page.dart';
import 'package:inteagle_app/pages/device_discover/device_discover_page.dart';
import 'package:inteagle_app/pages/device_detail/device_detail_page.dart';
import 'package:inteagle_app/pages/device_home/device_home_page.dart';

final GoRouter router = GoRouter(
  navigatorKey: GlobalKey<NavigatorState>(),
  initialLocation: AppRoute.deviceDiscoverPage.path,
  routes: [
    // 根路由使用响应式布局
    GoRoute(
      path: AppRoute.root.path,
      redirect: (_, __) => AppRoute.deviceDiscoverPage.path,
    ),
    ShellRoute(
      builder: (context, state, child) {
        return ResponsiveLayout(child: child);
      },
      routes: [
        // 设备发现页面
        GoRoute(
          path: AppRoute.deviceDiscoverPage.path,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DeviceDiscoverPage(),
          ),
        ),
        // 添加设备页面
        GoRoute(
          path: AppRoute.deviceSavePage.path,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DeviceSavePage(),
          ),
        ),

        // 设备详情页面
        GoRoute(
          path: AppRoute.deviceDetailPage.path,
          pageBuilder: (context, state) {
            final deviceId = state.pathParameters['deviceId']!;
            return NoTransitionPage(
              child: DeviceDetailPage(deviceId: deviceId),
            );
          },
        ),
        // 设备初始化主页面
        GoRoute(
          path: AppRoute.deviceHomePage.path,
          pageBuilder: (context, state) {
            final deviceId = state.pathParameters['deviceId']!;
            return NoTransitionPage(
              child: DeviceHomePage(deviceId: deviceId),
            );
          },
        ),
      ],
    )
  ],
);
