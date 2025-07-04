import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

part 'app_config_provider.g.dart';

const _prefsKey = 'app_config';

@riverpod
class AppConfigNotifier extends _$AppConfigNotifier {
  @override
  Future<AppConfig> build() async {
    // 从本地存储加载配置
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString(_prefsKey);

    // 如果有保存的配置则解析，否则返回默认值
    if (savedData != null) {
      try {
        final jsonMap = jsonDecode(savedData) as Map<String, dynamic>;
        return AppConfig.fromMap(jsonMap);
      } catch (e) {
        // 解析失败时使用默认配置
        return AppConfig.defaultConfig();
      }
    }
    return AppConfig.defaultConfig();
  }

  // 更新整个配置
  Future<void> updateConfig(AppConfig newConfig) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _saveConfig(newConfig);
      return newConfig;
    });
  }

  // 更新语言
  Future<void> updateLanguage(Locale newLanguage) async {
    final current = state.valueOrNull ?? AppConfig.defaultConfig();
    await updateConfig(current.copyWith(language: newLanguage));
  }

  // 更新主题模式
  Future<void> updateThemeMode(bool isDark) async {
    final current = state.valueOrNull ?? AppConfig.defaultConfig();
    await updateConfig(current.copyWith(isDarkMode: isDark));
  }

  // 更新主题色
  Future<void> updatePrimaryColor(int newColor) async {
    final current = state.valueOrNull ?? AppConfig.defaultConfig();
    await updateConfig(current.copyWith(primaryColor: newColor));
  }

  // 保存配置到本地存储
  Future<void> _saveConfig(AppConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(config.toMap()),
    );
  }
}
