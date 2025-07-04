import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum AppRoute {
  root('/'),
  deviceDiscoverPage('/device_discover'),
  deviceDetailPage('/device_detail/:deviceId'),
  deviceHomePage('/device_home/:deviceId'),
  deviceSavePage('/device_save'),
  ;

  const AppRoute(this.path);
  final String path;
}

extension AppRouteNavigation on AppRoute {
  void go(BuildContext context) => context.go(path);
  void push(BuildContext context) => context.push(path);
  // 获取带参数的路由路径
  String location([Map<String, String> params = const {}]) {
    String result = path;
    params.forEach((key, value) {
      result = result.replaceAll(':$key', value);
    });
    return result;
  }
}
