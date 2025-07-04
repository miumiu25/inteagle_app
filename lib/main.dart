import 'package:inteagle_app/app/app.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() async {
  runApp(ProviderScope(
    child: App(),
  ));
}

// class MyApp extends HookConsumerWidget {
//   const MyApp({super.key});
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final initState = ref.watch(appInitializerProvider);

//     return initState.when(
//       loading: () => _buildSplashScreen(),
//       error: (error, stack) => _buildErrorScreen(error),
//       data: (_) => _buildMainApp(ref),
//     );
//   }

//   Widget _buildMainApp(WidgetRef ref) {
//     final appConfigAsync = ref.watch(appConfigNotifierProvider);

//     return appConfigAsync.when(
//       data: (config) => DynamicColorBuilder(
//         builder: (lightDynamic, darkDynamic) {
//           final lightColor = ColorScheme.fromSeed(
//               dynamicSchemeVariant: DynamicSchemeVariant.rainbow,
//               seedColor: Color(config.primaryColor),
//               brightness: Brightness.light);
//           final darkColor = ColorScheme.fromSeed(
//               dynamicSchemeVariant: DynamicSchemeVariant.rainbow,
//               seedColor: Color(config.primaryColor),
//               brightness: Brightness.dark);
//           return MaterialApp.router(
//             debugShowCheckedModeBanner: false,
//             routerConfig: router,
//             theme: ThemeData(
//                 colorScheme: lightColor,
//                 brightness: Brightness.light,
//                 useMaterial3: true),
//             darkTheme: ThemeData(
//                 colorScheme: darkColor,
//                 brightness: Brightness.dark,
//                 useMaterial3: true),
//             themeMode: config.isDarkMode ? ThemeMode.dark : ThemeMode.light,
//             locale: config.language,
//             localizationsDelegates: const [
//               T.delegate,
//               GlobalMaterialLocalizations.delegate,
//               GlobalWidgetsLocalizations.delegate,
//               GlobalCupertinoLocalizations.delegate,
//             ],
//             supportedLocales: T.delegate.supportedLocales,
//             localeResolutionCallback: (locale, supportedLocales) {
//               if (locale != null && T.delegate.isSupported(locale)) {
//                 return locale;
//               }
//               return config.language;
//             },
//           );
//         },
//       ),
//       loading: () => _buildSplashScreen(),
//       error: (e, _) => _buildErrorScreen(e),
//     );
//   }

//   Widget _buildSplashScreen() {
//     return MaterialApp(
//       home: Scaffold(
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(height: 20),
//               Text('应用初始化中...'),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorScreen(dynamic error) {
//     return MaterialApp(
//       home: Scaffold(
//         body: Center(
//           child: Text('初始化失败: $error'),
//         ),
//       ),
//     );
//   }
// }
