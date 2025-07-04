// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class DisplacementRecord {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _displacementRecordStreamController.stream.asBroadcastStream();

  const DisplacementRecord({
    required this.record,
  });

  static DisplacementRecord deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = DisplacementRecord(
      record: TraitHelpers.deserializeVectorDisplacementRecordModel(deserializer),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static DisplacementRecord bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = DisplacementRecord.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final List<DisplacementRecordModel> record;

  DisplacementRecord copyWith({
    List<DisplacementRecordModel>? record,
  }) {
    return DisplacementRecord(
      record: record ?? this.record,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    TraitHelpers.serializeVectorDisplacementRecordModel(record, serializer);
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

    return other is DisplacementRecord
      && listEquals(record, other.record);
  }

  @override
  int get hashCode => record.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'record: $record'
        ')';
      return true;
    }());

    return fullString ?? 'DisplacementRecord';
  }
}

final _displacementRecordStreamController =
    StreamController<RustSignalPack<DisplacementRecord>>();
