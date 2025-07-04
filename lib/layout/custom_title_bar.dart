import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:window_manager/window_manager.dart';

class CustomTitleBar extends HookWidget {
  const CustomTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isMaximized = useState(false);

    useEffect(() {
      windowManager.isMaximized().then((value) {
        isMaximized.value = value;
      });

      windowManager.addListener(_WindowListener(isMaximized));
      return () => windowManager.removeListener(_WindowListener(isMaximized));
    }, []);

    return Container(
      height: 36, // 标题栏高度
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          // 左侧空白区域（可用于拖拽窗口）
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              child: Container(),
            ),
          ),

          // 窗口控制按钮
          Row(
            children: [
              _buildControlButton(
                icon: Icons.remove,
                hoverColor: Colors.grey[200],
                onPressed: () => windowManager.minimize(),
              ),
              _buildControlButton(
                icon: isMaximized.value ? Icons.filter_none : Icons.crop_square,
                hoverColor: Colors.grey[200],
                onPressed: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                  } else {
                    await windowManager.maximize();
                  }
                },
              ),
              _buildControlButton(
                icon: Icons.close,
                hoverColor: Colors.red[400],
                onPressed: () => windowManager.close(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 辅助方法：带悬停效果的按钮
  Widget _buildControlButton({
    required IconData icon,
    required Color? hoverColor,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: IconButton(
        // tooltip: label,
        icon: Icon(icon, size: 16),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          hoverColor: hoverColor,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

class _WindowListener extends WindowListener {
  final ValueNotifier<bool> isMaximized;

  _WindowListener(this.isMaximized);

  @override
  void onWindowMaximize() => isMaximized.value = true;

  @override
  void onWindowUnmaximize() => isMaximized.value = false;
}
