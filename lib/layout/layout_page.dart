import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inteagle_app/l10n/generated/l10n.dart';
import 'package:inteagle_app/layout/custom_title_bar.dart';
import 'package:inteagle_app/layout/language_switch.dart';
import 'package:inteagle_app/layout/theme_switch.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';
import '../router/routes.dart';

class ResponsiveLayout extends HookConsumerWidget {
  final Widget child;

  const ResponsiveLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    if (Platform.isAndroid || Platform.isIOS) {
      return MobileLayout(child: child);
    } else if (isDesktop) {
      return DesktopLayout(child: child);
    } else {
      return MobileLayout(child: child);
    }
  }
}

class DesktopLayout extends StatelessWidget {
  final Widget child;

  const DesktopLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Row(
      children: [
        const NavigationRailSection(),
        Expanded(
          child: Column(
            children: [const CustomTitleBar(), Expanded(child: child)],
          ),
        )
      ],
    ));
  }
}

class MobileLayout extends StatelessWidget {
  final Widget child;

  const MobileLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: child);
  }
}

class NavigationRailSection extends StatelessWidget {
  const NavigationRailSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: Colors.black12),
          ),
        ),
        child: Column(
          children: [
            MenuBarLeading(),
            Expanded(
              child: NavigationRail(
                minWidth: 100,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.devices),
                    label: Text(T.of(context).deviceDiscover),
                  ),
                ],
                selectedIndex: 0,
                onDestinationSelected: (index) {
                  context.go(AppRoute.deviceDiscoverPage.path);
                },
              ),
            ),
            MenuBarTail()
          ],
        ));
  }
}

class MenuBarLeading extends StatelessWidget {
  const MenuBarLeading({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 20),
      child: Column(
        spacing: 6,
        children: [
          GestureDetector(
            onDoubleTap: () {},
            child: TDImage(
              assetUrl: 'assets/images/logo.png',
              width: 58,
              height: 58,
              type: TDImageType.circle,
            ),
          ),
          Text(T.of(context).appName),
        ],
      ),
    );
  }
}

class MenuBarTail extends StatelessWidget {
  const MenuBarTail({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 20),
      child: Column(
        children: [
          LanguageSwitch(),
          SizedBox(height: 20),
          ThemeSwitch(),
        ],
      ),
    );
  }
}
