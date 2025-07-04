// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_discovery_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deviceDiscoveryServiceHash() =>
    r'17bdf4d37053a3f3f721ffa58b185ea207baace6';

/// See also [deviceDiscoveryService].
@ProviderFor(deviceDiscoveryService)
final deviceDiscoveryServiceProvider =
    AutoDisposeProvider<DeviceDiscoveryService>.internal(
  deviceDiscoveryService,
  name: r'deviceDiscoveryServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceDiscoveryServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeviceDiscoveryServiceRef
    = AutoDisposeProviderRef<DeviceDiscoveryService>;
String _$deviceDiscoveryNotifierHash() =>
    r'3794ba494e5253913da7275cb28dee6c8b4225ce';

/// See also [DeviceDiscoveryNotifier].
@ProviderFor(DeviceDiscoveryNotifier)
final deviceDiscoveryNotifierProvider = AutoDisposeAsyncNotifierProvider<
    DeviceDiscoveryNotifier, List<DiscoveredDevice>>.internal(
  DeviceDiscoveryNotifier.new,
  name: r'deviceDiscoveryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deviceDiscoveryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$DeviceDiscoveryNotifier
    = AutoDisposeAsyncNotifier<List<DiscoveredDevice>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
