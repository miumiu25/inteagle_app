import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inteagle_app/app/error_page.dart';
import 'package:inteagle_app/providers/app_init_provider.dart';
import 'splash_page.dart';
import 'main_app.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听应用初始化状态
    final initState = ref.watch(appInitializerProvider);

    return initState.when(
      loading: () => const SplashPage(),
      error: (error, stack) => ErrorPage(error: error),
      data: (_) => const MainApp(),
    );
  }
}
