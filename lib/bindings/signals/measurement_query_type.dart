// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


abstract class MeasurementQueryType {
  const MeasurementQueryType();

  void serialize(BinarySerializer serializer);

  static MeasurementQueryType deserialize(BinaryDeserializer deserializer) {
    int index = deserializer.deserializeVariantIndex();
    switch (index) {
      case 0: return MeasurementQueryTypeDisplacement.load(deserializer);
      case 1: return MeasurementQueryTypeEnvironment.load(deserializer);
      default: throw Exception('Unknown variant index for MeasurementQueryType: ' + index.toString());
    }
  }

  Uint8List bincodeSerialize() {
      final serializer = BincodeSerializer();
      serialize(serializer);
      return serializer.bytes;
  }

  static MeasurementQueryType bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = MeasurementQueryType.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }
}


@immutable
class MeasurementQueryTypeDisplacement extends MeasurementQueryType {
  const MeasurementQueryTypeDisplacement({
    this.targetId,
  }) : super();

  static MeasurementQueryTypeDisplacement load(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = MeasurementQueryTypeDisplacement(
      targetId: TraitHelpers.deserializeOptionStr(deserializer),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  final String? targetId;

  MeasurementQueryTypeDisplacement copyWith({
    String? Function()? targetId,
  }) {
    return MeasurementQueryTypeDisplacement(
      targetId: targetId == null ? this.targetId : targetId(),
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeVariantIndex(0);
    TraitHelpers.serializeOptionStr(targetId, serializer);
    serializer.decreaseContainerDepth();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is MeasurementQueryTypeDisplacement
      && targetId == other.targetId;
  }

  @override
  int get hashCode => targetId.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'targetId: $targetId'
        ')';
      return true;
    }());

    return fullString ?? 'MeasurementQueryTypeDisplacement';
  }
}

@immutable
class MeasurementQueryTypeEnvironment extends MeasurementQueryType {
  const MeasurementQueryTypeEnvironment(
  ) : super();

  static MeasurementQueryTypeEnvironment load(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = MeasurementQueryTypeEnvironment(
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeVariantIndex(1);
    serializer.decreaseContainerDepth();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is MeasurementQueryTypeEnvironment;
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        ')';
      return true;
    }());

    return fullString ?? 'MeasurementQueryTypeEnvironment';
  }
}
