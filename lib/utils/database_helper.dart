// utils/database_helper.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

Future<String> getDatabasePath() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    return documentsDirectory.path;
  }

  // 移动端使用默认实现
  return await getDatabasesPath();
}
