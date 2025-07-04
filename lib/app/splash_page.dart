import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:inteagle_app/utils/constants.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        ColorfulText(),
                        ImageIcon(
                          AssetImage('assets/images/inteagle.png'),
                          size: 60.0,
                          color: UnitColor.primaryColor,
                        ),
                      ],
                    ),
                    Text(
                      '鹰腾监测机器人',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: UnitColor.primaryColor),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16),
                child: Text("· 2025 ·  @INTEAGLE VISION ",
                    style: UnitTextStyle.splashShadows),
              )
              // // 副标题
              // const Text(
              //   '连接 · 管理 · 控制',
              //   style: TextStyle(
              //     fontSize: 16,
              //     color: Colors.grey,
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class ColorfulText extends StatelessWidget {
  const ColorfulText({super.key});

  @override
  Widget build(BuildContext context) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        const Offset(22, 0),
        [Colors.red, Colors.yellow, Colors.blue, Colors.green],
        [1 / 4, 2 / 4, 3 / 4, 1],
        TileMode.mirror,
        Matrix4.rotationZ(pi / 4).storage,
      );
    return Text(
      "U",
      style: TextStyle(
          fontSize: 26,
          height: 1,
          fontWeight: FontWeight.bold,
          foreground: paint),
    );
  }
}
