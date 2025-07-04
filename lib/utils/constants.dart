import 'package:flutter/material.dart';
import 'dart:io';

bool get isDesktop {
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

class SizeUnit {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;

  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 12.0;

  // 文字相关
  static const double inputHitSize = 13;
  static const double inputTextSize = 13;

  // 大文字大小
  static const double textSizeLarge = 22;
  // 小文字大小
  static const double textSizeSmall = 12;

  // 标题文字大小
  static const double titleTextSize = 14;

  // 头文字大小
  static const double headTextSize = 18;
}

class UnitColor {
  // 收藏夹提供的颜色
  static const collectColorSupport = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFFF5F7FA),
    Color(0xFFf8f9fa),
    Color(0xFF343a40),
    Color(0xFF6c757d),
    Colors.black,
    Color(0xFFdc3545),
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Color(0xFF2c66ff),
    Colors.indigo,
    Colors.purple,
    Color(0xFF17a2b8),
    Color(0xffd1d08f),
    Colors.pink,
    Color(0xFFffc107),
    Colors.lime,
    Colors.teal,
    Colors.cyan,
    Color(0xff586CF2),
    Colors.purpleAccent,
  ];
  // 文字相关
  static const Color inputBorderColor = Color(0xffD0D7DD);
  static const Color textColor = Color(0xff323C47);
  static const Color inputHitColor = Color(0xff939EA7);
  static const Color headTextColor = Color(0xff666666);
  static const Color scaffoldBgLight = Color(0xffF3F4F6);
  // 缺省相关
  static const Color primaryColor = Color(0xFF2c66ff);
  static const Color errorColor = Color(0xFFdc3545);
  static const Color warningColor = Color(0xFFffc107);
  static const Color successColor = Colors.green;
}

class UnitTextStyle {
  // 标题加黑
  static const labelBold = TextStyle(fontWeight: FontWeight.bold, fontSize: 16);
  static TextStyle headlineLarge = const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.25,
  );

  static TextStyle headlineMedium = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.15,
  );

  static TextStyle headlineSmall = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.1,
  );

  static TextStyle bodyLarge = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
  );

  static TextStyle bodySmall = const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
  );

  // 闪屏页文字阴影样式
  static const splashShadows = TextStyle(
      color: Colors.grey,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 0.5, offset: Offset(0.1, 0.1))
      ],
      fontSize: 12);

  static const shadowTextStyle = TextStyle(color: Colors.grey, shadows: [
    Shadow(color: Colors.white, offset: Offset(.5, .5), blurRadius: .5)
  ]);

  static const commonChip = TextStyle(
    fontSize: 12,
    color: Colors.white,
  );

  static const TextStyle hintStyle = TextStyle(
      color: UnitColor.inputHitColor, fontSize: SizeUnit.inputHitSize);

  static const TextStyle primary =
      TextStyle(color: UnitColor.textColor, fontSize: SizeUnit.inputTextSize);

  static const TextStyle headTextStyle = TextStyle(
      color: UnitColor.headTextColor, fontSize: SizeUnit.headTextSize);

  static const TextStyle smallSubTextStyle = TextStyle(
      color: UnitColor.inputHitColor, fontSize: SizeUnit.textSizeSmall);

  static const TextStyle bigTextStyle =
      TextStyle(color: UnitColor.textColor, fontSize: SizeUnit.textSizeLarge);
}
