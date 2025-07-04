import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inteagle_app/utils/constants.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:media_kit/media_kit.dart';
import 'package:rinf/rinf.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import '../bindings/bindings.dart';

part 'app_init_provider.g.dart';

@Riverpod(keepAlive: true)
class AppInitializer extends _$AppInitializer {
  @override
  Future<void> build() async {
    final stopwatch = Stopwatch()..start();
    // final isDesktop =
    //     Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    // 确保 Widgets 绑定已初始化
    WidgetsFlutterBinding.ensureInitialized();

    // 窗口尺寸适配（仅桌面端）

    if (isDesktop && !_isSqfliteInitialized) {
      _initSqfliteForDesktop();
      // 初始化窗口管理器
    }
    // 手势优化
    GestureBinding.instance.resamplingEnabled = true;
    // 初始化媒体播放器
    // MediaKit.ensureInitialized();

    // 初始化 Rust
    initializeRust(assignRustSignal);

    // 初始化本地存储
    final prefs = await SharedPreferences.getInstance();

    // 初始化数据库
    await _initDb(prefs);

    // 其他初始化逻辑...
    if (isDesktop) {
      await _initDesktopWindow();
    }

    debugPrint('应用初始化完成，耗时: ${stopwatch.elapsedMilliseconds}ms');
  }

  static bool _isSqfliteInitialized = false;

  void _initSqfliteForDesktop() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    _isSqfliteInitialized = true;
  }

  Future<void> _initDb(SharedPreferences prefs) async {
    if (kIsWeb) return; // Web 环境不需要数据库初始化

    final dbPath = await getApplicationDocumentsDirectory();
    final fullPath = path.join(dbPath.path, 'flutter.db');

    // 检查是否需要复制数据库
    if (await _shouldCopyDb(fullPath, prefs)) {
      await _copyDbFromAssets(fullPath);
    }
  }

  Future<bool> _shouldCopyDb(String dbPath, SharedPreferences prefs) async {
    // 检查数据库是否存在
    final dbFile = File(dbPath);
    if (!await dbFile.exists()) return true;

    // 检查数据库版本
    final versionData = await rootBundle.loadString('assets/version.json');
    final currentVersion = json.decode(versionData)['dbVersion'] as int;
    final savedVersion = prefs.getInt('db_version') ?? 0;

    return currentVersion > savedVersion;
  }

  Future<void> _copyDbFromAssets(String dbPath) async {
    try {
      // 确保目录存在
      final dir = Directory(path.dirname(dbPath));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // 从 assets 复制数据库
      final data = await rootBundle.load('assets/flutter.db');
      final bytes = data.buffer.asUint8List();
      await File(dbPath).writeAsBytes(bytes);

      // 更新数据库版本
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('db_version', 1); // 设置当前版本号
    } catch (e) {
      debugPrint('Error copying database: $e');
    }
  }

  Future<void> _initDesktopWindow() async {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden, // 隐藏默认标题栏
      size: Size(1100, 700), // 初始窗口尺寸
      minimumSize: Size(1100, 700),
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setResizable(false);
    });
  }
}
