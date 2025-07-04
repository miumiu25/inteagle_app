import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:inteagle_app/models/device.dart';
import 'package:inteagle_app/models/discovered_device.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repository/wy_device_repository.dart';

class DeviceDiscoveryService {
  static const String _savedDevicesKey = 'saved_devices';
  final String _serviceType = '_wydevice._tcp';
  final _devicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();
  final List<DiscoveredDevice> _discoveredDevices = [];
  final WyDeviceRepository _deviceRepository = WyDeviceRepository();

  MDnsClient? _mdns;
  Timer? _discoveryTimer;
  bool _isDiscovering = false;

  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;

  List<DiscoveredDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);

  bool get isDiscovering => _isDiscovering;

  Future<void> startDiscovery() async {
    if (_isDiscovering) return;
    _isDiscovering = true;
    await loadSavedDevices();

    try {
      _mdns = MDnsClient();

      await _mdns!.start(
        interfacesFactory: (InternetAddressType type) async {
          // 获取网络接口
          List<NetworkInterface> interfaces = await NetworkInterface.list(
            type: type,
            includeLoopback: false,
            includeLinkLocal: false,
          );
          // 过滤掉 windows hyper-v 的虚拟网络接口
          // List<NetworkInterface> selectedInterfaces = [];
          // for (var interface in interfaces) {
          //
          //   if (!interface.name.startsWith("vEthernet")) {
          //     selectedInterfaces.add(interface);
          //   }
          // }
          // return selectedInterfaces;
          return interfaces;
        },
      );

      // 定期查询设备
      _runDiscovery();
      _discoveryTimer =
          Timer.periodic(const Duration(seconds: 3), (_) => _runDiscovery());
    } catch (e) {
      _isDiscovering = false;
      rethrow;
    }
  }

  Future<void> _runDiscovery() async {
    if (_mdns == null) return;

    try {
      debugPrint('开始mDNS发现');
      await for (final PtrResourceRecord ptr
          in _mdns!.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_serviceType),
      )) {
        await for (final SrvResourceRecord srv
            in _mdns!.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          await for (final IPAddressResourceRecord ip
              in _mdns!.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            await for (final TxtResourceRecord txt
                in _mdns!.lookup<TxtResourceRecord>(
              ResourceRecordQuery.text(ptr.domainName),
            )) {
              final deviceData = Map<String, String>.fromEntries(
                (txt.text is List<String>
                        ? txt.text as List<String>
                        : (txt.text).split(','))
                    .map((item) {
                  final parts = item.split('=');
                  return parts.length > 1
                      ? MapEntry(parts[0], parts.sublist(1).join('='))
                      : MapEntry(parts[0], '');
                }),
              );

              var deviceId = "";
              var httpClient = HttpClient();
              final response = await (await httpClient.get(
                      ip.address.address, srv.port, "/api/attribute"))
                  .close();
              if (response.statusCode == 200) {
                String responseBody =
                    await response.transform(utf8.decoder).join();
                final body = jsonDecode(responseBody);
                final newDeviceId = body["data"]["client"]["deviceId"];
                if (newDeviceId != null) {
                  deviceId = newDeviceId;
                }
              }

              final deviceName = deviceData['name'] ??
                  ptr.domainName.replaceAll('.$_serviceType.local', '');

              final device = DiscoveredDevice(
                name: deviceName,
                id: deviceId,
                ipAddress: ip.address.address,
                port: srv.port,
              );
              _updateDeviceList(device);
            }
          }
        }
      }
    } catch (e) {
      print('mDNS discovery error: $e');
    }
  }

  void _updateDeviceList(DiscoveredDevice newDevice) {
    final existingIndex =
        _discoveredDevices.indexWhere((d) => d.id == newDevice.id);
    if (existingIndex >= 0) {
      final existing = _discoveredDevices[existingIndex];

      // 检查是否需要更新IP
      if (existing.isPendingDiscovery && newDevice.ipAddress.isNotEmpty) {
        // 发现了带IP的设备，更新设备信息并移除待发现标记
        final updatedDevice = existing.copyWith(
          ipAddress: newDevice.ipAddress,
          port: newDevice.port,
          isPendingDiscovery: false,
        );
        _discoveredDevices[existingIndex] = updatedDevice;

        // 保存到数据库
        _saveDeviceToDatabase(updatedDevice);
      } else {
        // 保留原有的isSaved状态和isPendingDiscovery状态
        final updatedDevice = newDevice.copyWith(
          isSaved: existing.isSaved,
          isPendingDiscovery: existing.isPendingDiscovery,
        );
        _discoveredDevices[existingIndex] = updatedDevice;
      }
    } else {
      _discoveredDevices.add(newDevice);
    }
    _devicesController.add(_discoveredDevices);
  }

  Future<void> saveDevice(String deviceId) async {
    final index = _discoveredDevices.indexWhere((d) => d.id == deviceId);
    if (index >= 0) {
      _discoveredDevices[index] =
          _discoveredDevices[index].copyWith(isSaved: true);
      _devicesController.add(_discoveredDevices);
      await _saveDevicesToStorage();
    }
  }

  Future<void> unsaveDevice(String deviceId) async {
    final index = _discoveredDevices.indexWhere((d) => d.id == deviceId);
    if (index >= 0) {
      _discoveredDevices[index] =
          _discoveredDevices[index].copyWith(isSaved: false);
      _devicesController.add(_discoveredDevices);
      // 从数据库删除
      await _deviceRepository.deleteDevice(deviceId);
    }
  }

  // 添加手动设备方法
  Future<DiscoveredDevice> addManualDevice(String ipAddress,
      {int port = 9999}) async {
    final deviceId = "manual_${ipAddress.replaceAll('.', '_')}";
    final deviceName = "设备 ($ipAddress)";

    final device = DiscoveredDevice(
      name: deviceName,
      id: deviceId,
      ipAddress: ipAddress,
      port: port,
      isSaved: true, // 默认保存手动添加的设备
    );

    _updateDeviceList(device);

    // 保存到数据库
    await _saveDeviceToDatabase(device);

    return device;
  }

  Future<void> loadSavedDevices() async {
    try {
      // 从数据库加载设备
      final savedDevices = await _deviceRepository.getSavedDevices();

      // 转换为DiscoveredDevice并添加到列表
      for (final device in savedDevices) {
        final discoveredDevice = DiscoveredDevice(
          name: device.name,
          id: device.deviceId,
          ipAddress: device.ipAddress ?? '192.168.1.150',
          port: device.port ?? 9999,
          isSaved: true,
          // 数据库中的设备都是已保存的
          discoveredAt: DateTime.fromMillisecondsSinceEpoch(device.createTime),
        );

        _updateDeviceList(discoveredDevice);
      }
    } catch (e) {
      print('加载保存的设备失败: $e');
    }
  }

  // 在 DeviceDiscoveryService 类中添加
  Future<DiscoveredDevice> addDeviceByIdentifier(String identifier,
      {String? name, String? ipAddress, int port = 9999}) async {
    // 根据标识符类型判断
    final bool isSerialNumber =
        identifier.startsWith('SN') || identifier.length == 12;
    final String deviceId =
        isSerialNumber ? identifier : "manual_id_$identifier";
    final String deviceName = name ?? "设备 ($identifier)";

    final device = DiscoveredDevice(
      name: deviceName,
      id: deviceId,
      ipAddress: ipAddress ?? '',
      // IP可能为空，后续通过mDNS发现
      port: port,
      isSaved: true,
      isPendingDiscovery: ipAddress == null, // 标记需要发现IP的设备
    );

    _updateDeviceList(device);

    // 保存到数据库
    await _saveDeviceToDatabase(device);

    // 如果没有提供IP，尝试立即搜索匹配
    if (ipAddress == null) {
      // run_d();
    }

    return device;
  }

  Future<void> _saveDeviceToDatabase(DiscoveredDevice discoveredDevice) async {
    final device = Device(
      deviceId: discoveredDevice.id,
      name: discoveredDevice.name,
      status: 'offline',
      // 初始状态为离线
      ipAddress: discoveredDevice.ipAddress,
      port: discoveredDevice.port,
      connectionType:
          discoveredDevice.id.startsWith('manual_') ? 'manual' : 'auto',
      lastConnectionTime: DateTime.now().millisecondsSinceEpoch,
      createTime: discoveredDevice.discoveredAt.millisecondsSinceEpoch,
    );

    final result = await _deviceRepository.saveDevice(device);
  }

  Future<void> _saveDevicesToStorage() async {
    try {
      final savedDevices = _discoveredDevices.where((d) => d.isSaved).toList();
      final prefs = await SharedPreferences.getInstance();

      final savedDevicesJson =
          savedDevices.map((device) => jsonEncode(device.toJson())).toList();

      await prefs.setStringList(_savedDevicesKey, savedDevicesJson);
    } catch (e) {
      print('保存设备到存储失败: $e');
    }
  }

  void stopDiscovery() {
    _isDiscovering = false;
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _mdns?.stop();
    _mdns = null;
  }

  void dispose() {
    stopDiscovery();
    _devicesController.close();
  }

  Future<void> removeDevice(String deviceId) async {
    // 从数据库删除设备
    await _deviceRepository.deleteDevice(deviceId);

    // 从内存中的设备列表移除
    final index = _discoveredDevices.indexWhere((d) => d.id == deviceId);
    if (index >= 0) {
      print("移除设备: ${_discoveredDevices[index].name}");
      _discoveredDevices.removeAt(index);
      print("设备列表: ${_discoveredDevices.length}");
      print("设备列表: $_discoveredDevices");
      _devicesController.add(_discoveredDevices);
    }

    // 重新从数据库加载已保存的设备
    await loadSavedDevices();
  }
}
