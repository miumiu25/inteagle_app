import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AnimatedWifiIcon extends HookWidget {
  const AnimatedWifiIcon({super.key});

  @override
  Widget build(BuildContext context) {
    // 创建动画控制器
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: false);

    final iconSequence = useMemoized(() => [
          Icons.wifi_1_bar_outlined,
          Icons.wifi_2_bar_outlined,
          Icons.wifi,
          Icons.wifi,
        ]);

    final currentIndex = useAnimation(
        IntTween(begin: 0, end: iconSequence.length - 1).animate(controller));

    return Icon(
      iconSequence[currentIndex],
    );
  }
}
