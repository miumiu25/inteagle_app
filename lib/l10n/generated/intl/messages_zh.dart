// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a zh locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'zh';

  static String m0(count) => "发现 ${count} 个设备";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "addDevice": MessageLookupByLibrary.simpleMessage("添加设备"),
    "appName": MessageLookupByLibrary.simpleMessage("鹰腾微视"),
    "clickToScanning": MessageLookupByLibrary.simpleMessage("点击搜索按钮开始扫描"),
    "deviceDiscover": MessageLookupByLibrary.simpleMessage("设备发现"),
    "discoverFound": m0,
    "discoverTitle": MessageLookupByLibrary.simpleMessage("视觉位移计设备发现"),
    "lang": MessageLookupByLibrary.simpleMessage("中"),
    "noDevice": MessageLookupByLibrary.simpleMessage("未发现设备"),
    "retry": MessageLookupByLibrary.simpleMessage("重试"),
    "scanning": MessageLookupByLibrary.simpleMessage("正在扫描..."),
    "searchDevice": MessageLookupByLibrary.simpleMessage("搜索设备"),
    "startScan": MessageLookupByLibrary.simpleMessage("开始扫描"),
    "stopScan": MessageLookupByLibrary.simpleMessage("停止扫描"),
    "unknown": MessageLookupByLibrary.simpleMessage("未知状态"),
  };
}
