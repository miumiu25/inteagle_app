import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../utils/database_helper.dart';

class DeviceDatabase {
  static final DeviceDatabase _instance = DeviceDatabase._internal();
  static Database? _database;

  factory DeviceDatabase() {
    return _instance;
  }

  DeviceDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasePath(), 'main.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // 版本升级时执行
        if (oldVersion < 2) {
          debugPrint(
              'Upgrading database from version $oldVersion to $newVersion');
          await db.execute('ALTER TABLE device ADD COLUMN sn TEXT');
        }
      },
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // 创建设备设置表
    await db.execute('''
          CREATE TABLE IF NOT EXISTS device_attribute (
            device_id TEXT NOT NULL,
            key TEXT NOT NULL,
            value TEXT NOT NULL,
            type TEXT NOT NULL,
            update_time INTEGER NOT NULL,
            PRIMARY KEY (device_id, key)
          );
    ''');

    // 创建设备表
    await db.execute('''
    CREATE TABLE IF NOT EXISTS device (
      device_id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      status TEXT NOT NULL,
      sn TEXT ,
      ip_address TEXT,
      port INTEGER,
      connection_type TEXT,
      cloud1 TEXT,
      cloud2 TEXT,
      last_connection_time INTEGER NOT NULL,
      create_time INTEGER NOT NULL
    );
  ''');
  }

  // 辅助方法：关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // 辅助方法：清空所有数据（测试用）
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('device_attribute');
      await txn.delete('device');
    });
  }

  // 辅助方法：清空指定设备的数据
  Future<void> clearDeviceData(String deviceId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('targets', where: 'deviceId = ?', whereArgs: [deviceId]);
      await txn.delete('device_settings',
          where: 'deviceId = ?', whereArgs: [deviceId]);
    });
  }
}
