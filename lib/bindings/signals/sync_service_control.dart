// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class SyncServiceControl {
  const SyncServiceControl({
    required this.msgType,
    required this.databasePath,
    required this.baseApi,
    required this.pollInterval,
  });

  static SyncServiceControl deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = SyncServiceControl(
      msgType: SyncServiceControlMsgTypeExtension.deserialize(deserializer),
      databasePath: deserializer.deserializeString(),
      baseApi: deserializer.deserializeString(),
      pollInterval: deserializer.deserializeInt64(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static SyncServiceControl bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = SyncServiceControl.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final SyncServiceControlMsgType msgType;
  final String databasePath;
  final String baseApi;
  final int pollInterval;

  SyncServiceControl copyWith({
    SyncServiceControlMsgType? msgType,
    String? databasePath,
    String? baseApi,
    int? pollInterval,
  }) {
    return SyncServiceControl(
      msgType: msgType ?? this.msgType,
      databasePath: databasePath ?? this.databasePath,
      baseApi: baseApi ?? this.baseApi,
      pollInterval: pollInterval ?? this.pollInterval,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    msgType.serialize(serializer);
    serializer.serializeString(databasePath);
    serializer.serializeString(baseApi);
    serializer.serializeInt64(pollInterval);
    serializer.decreaseContainerDepth();
  }

  Uint8List bincodeSerialize() {
      final serializer = BincodeSerializer();
      serialize(serializer);
      return serializer.bytes;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is SyncServiceControl
      && msgType == other.msgType
      && databasePath == other.databasePath
      && baseApi == other.baseApi
      && pollInterval == other.pollInterval;
  }

  @override
  int get hashCode => Object.hash(
        msgType,
        databasePath,
        baseApi,
        pollInterval,
      );

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'msgType: $msgType, '
        'databasePath: $databasePath, '
        'baseApi: $baseApi, '
        'pollInterval: $pollInterval'
        ')';
      return true;
    }());

    return fullString ?? 'SyncServiceControl';
  }
}

extension SyncServiceControlDartSignalExt on SyncServiceControl {
  /// Sends the signal to Rust.
  /// Passing data from Rust to Dart involves a memory copy
  /// because Rust cannot own data managed by Dart's garbage collector.
  void sendSignalToRust() {
    final messageBytes = bincodeSerialize();
    final binary = Uint8List(0);
    sendDartSignal(
      'rinf_send_dart_signal_sync_service_control',
      messageBytes,
      binary,
    );
  }
}
