import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

@immutable
class AppConfig {
  final Locale language;
  final bool isDarkMode;
  final int primaryColor;

  const AppConfig({
    required this.language,
    required this.isDarkMode,
    required this.primaryColor,
  });

  // 默认配置
  factory AppConfig.defaultConfig() => const AppConfig(
        language: Locale('zh', 'CN'),
        isDarkMode: false,
        primaryColor: 0xFF2c66ff,
      );

  // 支持的语言选项列表
  static const List<Map<String, dynamic>> supportedLanguages = [
    {
      'value': Locale('zh', 'CN'),
      'label': '中文',
      'icon': '🇨🇳',
    },
    {
      'value': Locale('en', 'US'),
      'label': 'English',
      'icon': '🇺🇸',
    },
  ];
  // 获取当前语言的显示标签
  String get currentLanguageLabel {
    final current = language;
    for (var lang in supportedLanguages) {
      final value = lang['value'] as Locale;
      if (value.languageCode == current.languageCode &&
          value.countryCode == current.countryCode) {
        return lang['label'] as String;
      }
    }
    return '中文'; // 默认
  }

  // 转换为Map (用于本地存储)
  Map<String, dynamic> toMap() => {
        'language': _localeToString(language),
        'isDarkMode': isDarkMode,
        'primaryColor': primaryColor,
      };

  // 从Map创建 (用于从存储加载)
  factory AppConfig.fromMap(Map<String, dynamic> map) {
    return AppConfig(
      language: _stringToLocale(map['language'] as String?),
      isDarkMode: map['isDarkMode'] as bool? ?? false,
      primaryColor: map['primaryColor'] as int? ?? 0xFF2c66ff,
    );
  }

  // 复制方法
  AppConfig copyWith({
    Locale? language,
    bool? isDarkMode,
    int? primaryColor,
  }) {
    return AppConfig(
      language: language ?? this.language,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      primaryColor: primaryColor ?? this.primaryColor,
    );
  }

  // Locale 转 String
  static String _localeToString(Locale locale) {
    return '${locale.languageCode}_${locale.countryCode}';
  }

  // String 转 Locale
  static Locale _stringToLocale(String? localeString) {
    if (localeString == null) return const Locale('zh', 'CN');

    final parts = localeString.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return const Locale('zh', 'CN');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          runtimeType == other.runtimeType &&
          language == other.language &&
          isDarkMode == other.isDarkMode &&
          primaryColor == other.primaryColor;

  @override
  int get hashCode => Object.hash(language, isDarkMode, primaryColor);
}
