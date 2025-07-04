import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DeviceHomePage extends HookConsumerWidget {
  const DeviceHomePage({super.key, required this.deviceId});
  final String deviceId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}
