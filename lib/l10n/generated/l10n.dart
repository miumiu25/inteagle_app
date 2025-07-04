// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class T {
  T();

  static T? _current;

  static T get current {
    assert(
      _current != null,
      'No instance of T was loaded. Try to initialize the T delegate before accessing T.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<T> load(Locale locale) {
    final name =
        (locale.countryCode?.isEmpty ?? false)
            ? locale.languageCode
            : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = T();
      T._current = instance;

      return instance;
    });
  }

  static T of(BuildContext context) {
    final instance = T.maybeOf(context);
    assert(
      instance != null,
      'No instance of T present in the widget tree. Did you add T.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static T? maybeOf(BuildContext context) {
    return Localizations.of<T>(context, T);
  }

  /// `中`
  String get lang {
    return Intl.message('中', name: 'lang', desc: '', args: []);
  }

  /// `鹰腾微视`
  String get appName {
    return Intl.message('鹰腾微视', name: 'appName', desc: '', args: []);
  }

  /// `视觉位移计设备发现`
  String get discoverTitle {
    return Intl.message('视觉位移计设备发现', name: 'discoverTitle', desc: '', args: []);
  }

  /// `设备发现`
  String get deviceDiscover {
    return Intl.message('设备发现', name: 'deviceDiscover', desc: '', args: []);
  }

  /// `搜索设备`
  String get searchDevice {
    return Intl.message('搜索设备', name: 'searchDevice', desc: '', args: []);
  }

  /// `添加设备`
  String get addDevice {
    return Intl.message('添加设备', name: 'addDevice', desc: '', args: []);
  }

  /// `开始扫描`
  String get startScan {
    return Intl.message('开始扫描', name: 'startScan', desc: '', args: []);
  }

  /// `停止扫描`
  String get stopScan {
    return Intl.message('停止扫描', name: 'stopScan', desc: '', args: []);
  }

  /// `未发现设备`
  String get noDevice {
    return Intl.message('未发现设备', name: 'noDevice', desc: '', args: []);
  }

  /// `正在扫描...`
  String get scanning {
    return Intl.message('正在扫描...', name: 'scanning', desc: '', args: []);
  }

  /// `点击搜索按钮开始扫描`
  String get clickToScanning {
    return Intl.message(
      '点击搜索按钮开始扫描',
      name: 'clickToScanning',
      desc: '',
      args: [],
    );
  }

  /// `发现 {count} 个设备`
  String discoverFound(int count) {
    return Intl.message(
      '发现 $count 个设备',
      name: 'discoverFound',
      desc: 'discoverFound message',
      args: [count],
    );
  }

  /// `重试`
  String get retry {
    return Intl.message('重试', name: 'retry', desc: '', args: []);
  }

  /// `未知状态`
  String get unknown {
    return Intl.message('未知状态', name: 'unknown', desc: '', args: []);
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<T> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'zh'),
      Locale.fromSubtags(languageCode: 'en'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<T> load(Locale locale) => T.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
