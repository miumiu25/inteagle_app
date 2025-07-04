import 'dart:async';
import 'package:inteagle_app/models/discovered_device.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/device_discover_service.dart';

part 'device_discovery_provider.g.dart';

@riverpod
DeviceDiscoveryService deviceDiscoveryService(DeviceDiscoveryServiceRef ref) {
  final service = DeviceDiscoveryService();
  ref.onDispose(() => service.dispose());
  return service;
}

@riverpod
class DeviceDiscoveryNotifier extends _$DeviceDiscoveryNotifier {
  StreamSubscription? _deviceSubscription;
  @override
  Future<List<DiscoveredDevice>> build() async {
    final service = ref.watch(deviceDiscoveryServiceProvider);
    // 取消之前的订阅（如果存在）
    _deviceSubscription?.cancel();
    // 设置新的订阅
    _deviceSubscription = service.devicesStream.listen((devices) {
      // 当设备列表更新时，同步更新状态
      state = AsyncValue.data(devices);
    });

    // 注册清理函数
    ref.onDispose(() {
      _deviceSubscription?.cancel();
    });

    // 初始加载前显示加载状态
    state = const AsyncValue.loading();

    try {
      await service.loadSavedDevices();
      return service.discoveredDevices;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> startDiscovery() async {
    final service = ref.read(deviceDiscoveryServiceProvider);
    await service.startDiscovery();
  }

  Future<void> stopDiscovery() async {
    final service = ref.read(deviceDiscoveryServiceProvider);
    service.stopDiscovery();
  }

  Future<void> saveDevice(String deviceId) async {
    final service = ref.read(deviceDiscoveryServiceProvider);
    await service.saveDevice(deviceId);
  }

  Future<void> unsaveDevice(String deviceId) async {
    final service = ref.read(deviceDiscoveryServiceProvider);
    await service.unsaveDevice(deviceId);
  }

  Future<void> addManualDevice(String ipAddress, {int port = 9999}) async {
    final service = ref.read(deviceDiscoveryServiceProvider);
    await service.addManualDevice(ipAddress, port: port);
  }

  Future<void> deleteDevice(String deviceId) async {
    final service = ref.read(deviceDiscoveryServiceProvider);
    await service.removeDevice(deviceId);
  }

  Future<void> addDeviceByIdentifier(String identifier,
      {String? name, String? ipAddress, int port = 9999}) async {
    final service = ref.read(deviceDiscoveryServiceProvider);
    await service.addDeviceByIdentifier(identifier,
        name: name, ipAddress: ipAddress, port: port);
  }
}
