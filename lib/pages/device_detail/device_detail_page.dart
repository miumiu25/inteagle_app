import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DeviceDetailPage extends HookConsumerWidget {
  const DeviceDetailPage({super.key, required this.deviceId});
  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container();
  }
}
