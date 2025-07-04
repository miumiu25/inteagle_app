import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inteagle_app/providers/app_config_provider.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class LanguageSwitch extends HookConsumerWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(
          appConfigNotifierProvider.select((config) => config.value?.language),
        ) ??
        const Locale('zh', 'CN');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: IconButton(
        onPressed: () {
          ref.read(appConfigNotifierProvider.notifier).updateLanguage(
              language == Locale('en', 'US')
                  ? Locale('zh', 'CN')
                  : Locale('en', 'US'));
        },
        icon: Icon(TDIcons.translate_1, size: 22),
      ),
    );
  }
}
