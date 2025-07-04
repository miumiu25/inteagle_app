class DiscoveredDevice {
  final String name;
  final String id;
  final String ipAddress;
  final int port;
  final bool isSaved;
  final DateTime discoveredAt;
  final bool isPendingDiscovery; // 新增字段，标记等待发现IP的设备

  DiscoveredDevice({
    required this.name,
    required this.id,
    required this.ipAddress,
    required this.port,
    this.isSaved = false,
    DateTime? discoveredAt,
    this.isPendingDiscovery = false,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  String get wsUrl => 'ws://$ipAddress:$port/ws';

  DiscoveredDevice copyWith({
    String? name,
    String? id,
    String? ipAddress,
    int? port,
    bool? isSaved,
    DateTime? discoveredAt,
    bool? isPendingDiscovery,
  }) {
    return DiscoveredDevice(
      name: name ?? this.name,
      id: id ?? this.id,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      isSaved: isSaved ?? this.isSaved,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      isPendingDiscovery: isPendingDiscovery ?? this.isPendingDiscovery,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'ipAddress': ipAddress,
      'port': port,
      'isSaved': isSaved,
      'discoveredAt': discoveredAt.millisecondsSinceEpoch,
    };
  }

  factory DiscoveredDevice.fromJson(Map<String, dynamic> json) {
    return DiscoveredDevice(
      name: json['name'] ?? '未命名设备',
      id: json['id'] ?? '',
      ipAddress: json['ipAddress'] ?? '',
      port: json['port'] ?? 9999,
      isSaved: json['isSaved'] ?? false,
      discoveredAt: json['discoveredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['discoveredAt'])
          : DateTime.now(),
    );
  }
}
