import 'dart:async';
import 'package:inteagle_app/models/device.dart';
import 'package:inteagle_app/repository/database.dart';
import 'package:sqflite/sqflite.dart';

class DeviceRepository {
  DeviceRepository();

  get database async {
    await DeviceDatabase().database;
  }

  // 获取所有设备
  Future<List<Device>> getSavedDevices() async {
    final db = await DeviceDatabase().database;
    final List<Map<String, dynamic>> maps = await db.query('device');

    return List.generate(maps.length, (i) {
      return Device.fromMap(maps[i]);
    });
  }

  // 添加设备
  Future<int> saveDevice(Device device) async {
    final db = await DeviceDatabase().database;
    return await db.insert(
      'device',
      device.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 更新设备
  Future<int> updateDevice(Device device) async {
    final db = await DeviceDatabase().database;
    return await db.update(
      'device',
      device.toMap(),
      where: 'device_id = ?',
      whereArgs: [device.deviceId],
    );
  }

  // 删除设备
  Future<int> deleteDevice(String deviceId) async {
    final db = await DeviceDatabase().database;
    return await db.delete(
      'device',
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }
}
