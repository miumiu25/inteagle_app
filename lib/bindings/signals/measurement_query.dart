// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class MeasurementQuery {
  const MeasurementQuery({
    required this.databasePath,
    required this.queryType,
    this.startTs,
    this.endTs,
    this.limit,
  });

  static MeasurementQuery deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = MeasurementQuery(
      databasePath: deserializer.deserializeString(),
      queryType: MeasurementQueryType.deserialize(deserializer),
      startTs: TraitHelpers.deserializeOptionI64(deserializer),
      endTs: TraitHelpers.deserializeOptionI64(deserializer),
      limit: TraitHelpers.deserializeOptionI32(deserializer),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static MeasurementQuery bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = MeasurementQuery.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final String databasePath;
  final MeasurementQueryType queryType;
  final int? startTs;
  final int? endTs;
  final int? limit;

  MeasurementQuery copyWith({
    String? databasePath,
    MeasurementQueryType? queryType,
    int? Function()? startTs,
    int? Function()? endTs,
    int? Function()? limit,
  }) {
    return MeasurementQuery(
      databasePath: databasePath ?? this.databasePath,
      queryType: queryType ?? this.queryType,
      startTs: startTs == null ? this.startTs : startTs(),
      endTs: endTs == null ? this.endTs : endTs(),
      limit: limit == null ? this.limit : limit(),
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeString(databasePath);
    queryType.serialize(serializer);
    TraitHelpers.serializeOptionI64(startTs, serializer);
    TraitHelpers.serializeOptionI64(endTs, serializer);
    TraitHelpers.serializeOptionI32(limit, serializer);
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

    return other is MeasurementQuery
      && databasePath == other.databasePath
      && queryType == other.queryType
      && startTs == other.startTs
      && endTs == other.endTs
      && limit == other.limit;
  }

  @override
  int get hashCode => Object.hash(
        databasePath,
        queryType,
        startTs,
        endTs,
        limit,
      );

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'databasePath: $databasePath, '
        'queryType: $queryType, '
        'startTs: $startTs, '
        'endTs: $endTs, '
        'limit: $limit'
        ')';
      return true;
    }());

    return fullString ?? 'MeasurementQuery';
  }
}

extension MeasurementQueryDartSignalExt on MeasurementQuery {
  /// Sends the signal to Rust.
  /// Passing data from Rust to Dart involves a memory copy
  /// because Rust cannot own data managed by Dart's garbage collector.
  void sendSignalToRust() {
    final messageBytes = bincodeSerialize();
    final binary = Uint8List(0);
    sendDartSignal(
      'rinf_send_dart_signal_measurement_query',
      messageBytes,
      binary,
    );
  }
}
