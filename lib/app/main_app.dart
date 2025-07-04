import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inteagle_app/app/error_page.dart';
import 'package:inteagle_app/app/splash_page.dart';
import 'package:inteagle_app/providers/app_config_provider.dart';
import 'package:inteagle_app/l10n/generated/l10n.dart';
import 'package:inteagle_app/router/index.dart';

class MainApp extends HookConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appConfigAsync = ref.watch(appConfigNotifierProvider);
    return appConfigAsync.when(
      data: (config) => DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: _buildTheme(Brightness.light, config.primaryColor),
            darkTheme: _buildTheme(Brightness.dark, config.primaryColor),
            themeMode: config.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            locale: config.language,
            localizationsDelegates: const [
              T.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: T.delegate.supportedLocales,
            localeResolutionCallback: (locale, supportedLocales) {
              if (locale != null && T.delegate.isSupported(locale)) {
                return locale;
              }
              return config.language;
            },
          );
        },
      ),
      loading: () => SplashPage(),
      error: (error, _) => ErrorPage(error: error),
    );
  }

  ThemeData _buildTheme(Brightness brightness, int primaryColor) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        dynamicSchemeVariant: DynamicSchemeVariant.rainbow,
        seedColor: Color(primaryColor),
        brightness: brightness,
      ),
      useMaterial3: true,
    );
  }
}
