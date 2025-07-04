import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class Empty extends HookWidget {
  final Widget? icon;
  final String message;
  final List<Widget> extras;

  const Empty({
    super.key,
    this.icon,
    this.message = '暂无数据',
    this.extras = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            if (icon != null)
              IconTheme(
                data: IconThemeData(
                  size: 80,
                  color: Theme.of(context).disabledColor,
                ),
                child: icon!,
              ),

            // 自定义文案
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).disabledColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (extras.isNotEmpty) ...[
              ...extras,
            ]
          ],
        ),
      ),
    );
  }
}
