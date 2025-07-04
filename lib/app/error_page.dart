import 'package:flutter/material.dart';
import 'package:inteagle_app/utils/constants.dart';

class ErrorPage extends StatelessWidget {
  final Object? error;

  const ErrorPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: UnitColor.errorColor,
              ),
              const SizedBox(height: 20),
              const Text(
                '应用启动失败',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                error?.toString() ?? '未知错误',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // 可以添加重试逻辑
                },
                child: const Text('联系管理员'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
