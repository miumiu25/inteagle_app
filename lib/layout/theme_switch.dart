import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inteagle_app/providers/app_config_provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class ThemeSwitch extends HookConsumerWidget {
  const ThemeSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(
          appConfigNotifierProvider
              .select((config) => config.value?.isDarkMode),
        ) ??
        false;

    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
      initialValue: isDarkMode ? 0.0 : 1.0,
    );

    final animation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    useEffect(() {
      if (isDarkMode) {
        animationController.reverse();
      } else {
        animationController.forward();
      }
      return null;
    }, [isDarkMode]);
    return GestureDetector(
      onTap: () {
        ref
            .read(appConfigNotifierProvider.notifier)
            .updateThemeMode(!isDarkMode);
      },
      child: Container(
        width: 42,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode
              ? TDTheme.of(context).grayColor10
              : TDTheme.of(context).grayColor4,
        ),
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Positioned(
                  left: isDarkMode ? null : 0,
                  right: isDarkMode ? 0 : null,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode
                          ? TDTheme.of(context).grayColor12
                          : TDTheme.of(context).whiteColor1,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: isDarkMode
                          ? Icon(
                              Icons.dark_mode,
                              size: 14,
                              color: TDTheme.of(context).grayColor4,
                              key: ValueKey('dark'),
                            )
                          : Icon(
                              Icons.light_mode,
                              size: 14,
                              color: TDTheme.of(context).grayColor12,
                              key: ValueKey('light'),
                            ),
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
