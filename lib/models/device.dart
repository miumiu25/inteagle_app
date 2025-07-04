/// 设备模型类，对应数据库中的 device 表
class Device {
  final String deviceId;
  final String name;
  final String status;
  final String? ipAddress;
  final int? port;
  final String? connectionType;
  final String? cloud1;
  final String? cloud2;
  final int lastConnectionTime;
  final int createTime;

  Device({
    required this.deviceId,
    required this.name,
    required this.status,
    this.ipAddress,
    this.port,
    this.connectionType,
    this.cloud1,
    this.cloud2,
    required this.lastConnectionTime,
    required this.createTime,
  });

  /// 从数据库记录创建 Device 实例
  factory Device.fromMap(Map<String, dynamic> map) {
    return Device(
      deviceId: map['device_id'],
      name: map['name'],
      status: map['status'],
      ipAddress: map['ip_address'],
      port: map['port'],
      connectionType: map['connection_type'],
      cloud1: map['cloud1'],
      cloud2: map['cloud2'],
      lastConnectionTime: map['last_connection_time'],
      createTime: map['create_time'],
    );
  }

  /// 转换为数据库记录
  Map<String, dynamic> toMap() {
    return {
      'device_id': deviceId,
      'name': name,
      'status': status,
      'ip_address': ipAddress,
      'port': port,
      'connection_type': connectionType,
      'cloud1': cloud1,
      'cloud2': cloud2,
      'last_connection_time': lastConnectionTime,
      'create_time': createTime,
    };
  }

  /// 创建具有相同 ID 但更新了部分属性的新实例
  Device copyWith({
    String? deviceId,
    String? name,
    String? status,
    String? ipAddress,
    int? port,
    String? connectionType,
    String? cloud1,
    String? cloud2,
    int? lastConnectionTime,
    int? createTime,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      name: name ?? this.name,
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      connectionType: connectionType ?? this.connectionType,
      cloud1: cloud1 ?? this.cloud1,
      cloud2: cloud2 ?? this.cloud2,
      lastConnectionTime: lastConnectionTime ?? this.lastConnectionTime,
      createTime: createTime ?? this.createTime,
    );
  }

  @override
  String toString() {
    return 'Device{deviceId: $deviceId, name: $name, status: $status, ipAddress: $ipAddress, port: $port, connectionType: $connectionType, lastConnectionTime: $lastConnectionTime}';
  }
}
