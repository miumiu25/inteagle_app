import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inteagle_app/l10n/generated/l10n.dart';
import 'package:inteagle_app/layout/language_switch.dart';
import 'package:inteagle_app/models/discovered_device.dart';
import 'package:inteagle_app/pages/device_discover/widgets/device_item.dart';
import 'package:inteagle_app/pages/device_discover/widgets/wifi_icon.dart';
import 'package:inteagle_app/providers/device_discovery_provider.dart';
import 'package:inteagle_app/router/routes.dart';
import 'package:inteagle_app/widgets/empty.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class DeviceDiscoverPage extends HookConsumerWidget {
  const DeviceDiscoverPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveryState = ref.watch(deviceDiscoveryNotifierProvider);
    final isDiscovering = useState(false);
    final devices = useState<List<DiscoveredDevice>>([]);

    useEffect(() {
      // 页面加载时自动开始搜索
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(deviceDiscoveryNotifierProvider.notifier).startDiscovery();
        isDiscovering.value = true;
      });
      return null;
    }, []);

    useEffect(() {
      if (discoveryState is AsyncData) {
        devices.value = discoveryState.value ?? [];
      }
      return null;
    }, [discoveryState]);

    void changeDiscovering() {
      if (isDiscovering.value) {
        ref.read(deviceDiscoveryNotifierProvider.notifier).stopDiscovery();
      } else {
        ref.read(deviceDiscoveryNotifierProvider.notifier).startDiscovery();
      }
      isDiscovering.value = !isDiscovering.value;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(T.of(context).discoverTitle),
        centerTitle: true,
        leading: (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
            ? null
            : LanguageSwitch(),
        // 右侧按钮
        actions: [
          IconButton(
            onPressed: () {
              showSearch(
                context: context,
                delegate: DeviceSearchDelegate(ref: ref),
              );
            },
            icon: const Icon(Icons.search, size: 24),
          ),
          IconButton(
            onPressed: () {
              AppRoute.deviceSavePage.push(context);
            },
            icon: const Icon(Icons.add, size: 24),
          ),
          IconButton(
            onPressed: changeDiscovering,
            icon: isDiscovering.value
                ? AnimatedWifiIcon()
                : const Icon(Icons.wifi_off, size: 24),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (isDiscovering.value)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(
                minHeight: 4,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(T.of(context).discoverFound(devices.value.length),
                      style: Theme.of(context).textTheme.titleMedium),
                  if (isDiscovering.value)
                    TDText(T.of(context).scanning,
                        textColor: TDTheme.of(context).brandNormalColor)
                ],
              ),
            ),
          ),
          if (devices.value.isEmpty)
            SliverToBoxAdapter(
              child: Empty(
                icon: Icon(Icons.devices),
                message: T.of(context).noDevice,
                extras: [
                  if (!isDiscovering.value)
                    ElevatedButton(
                      onPressed: changeDiscovering,
                      child: Text(T.of(context).startScan),
                    ),
                  OutlinedButton(
                    child: Text(T.of(context).addDevice),
                    onPressed: () => AppRoute.deviceSavePage.push(context),
                  ),
                ],
              ),
            )
          else
            _buildDeviceList(devices.value)
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<DiscoveredDevice> devices) {
    return SliverPadding(
      padding: const EdgeInsets.all(12.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400, // 卡片最大宽度
          mainAxisSpacing: 12.0, // 垂直间距
          crossAxisSpacing: 12.0, // 水平间距
          mainAxisExtent: 170,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final device = devices[index];
            return DeviceItem(
              device: device,
            );
          },
          childCount: devices.length,
        ),
      ),
    );
  }
}

class DeviceSearchDelegate extends SearchDelegate<DiscoveredDevice?> {
  final WidgetRef ref;
  DeviceSearchDelegate({required this.ref});

  @override
  String get searchFieldLabel => '搜索设备名称或IP地址';

  @override
  TextStyle? get searchFieldStyle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      );

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          tooltip: '清除',
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: '返回',
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final discoveryState = ref.watch(deviceDiscoveryNotifierProvider);
    final devices = discoveryState.value ?? [];

    final filteredDevices = devices.where((device) {
      return device.name.toLowerCase().contains(query.toLowerCase()) ||
          device.id.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (filteredDevices.isEmpty) {
      return Empty(
        icon: Icon(Icons.search_off),
        message: query.isEmpty ? '请输入搜索关键词' : '未找到匹配的设备',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400, // 卡片最大宽度
        mainAxisSpacing: 12.0, // 垂直间距
        crossAxisSpacing: 12.0, // 水平间距
        mainAxisExtent: 170,
      ),
      itemCount: filteredDevices.length,
      itemBuilder: (context, index) {
        final device = filteredDevices[index];
        return DeviceItem(
          device: device,
        );
      },
    );
  }
}
