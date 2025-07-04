// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class DisplacementRecordModel {
  const DisplacementRecordModel({
    required this.targetId,
    required this.ts,
    required this.sigmaX,
    required this.sigmaY,
    required this.x,
    required this.y,
    required this.r,
    required this.filtered,
    required this.inserted,
  });

  static DisplacementRecordModel deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = DisplacementRecordModel(
      targetId: deserializer.deserializeString(),
      ts: deserializer.deserializeInt64(),
      sigmaX: deserializer.deserializeFloat64(),
      sigmaY: deserializer.deserializeFloat64(),
      x: deserializer.deserializeFloat64(),
      y: deserializer.deserializeFloat64(),
      r: deserializer.deserializeFloat64(),
      filtered: deserializer.deserializeBool(),
      inserted: deserializer.deserializeBool(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static DisplacementRecordModel bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = DisplacementRecordModel.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final String targetId;
  final int ts;
  final double sigmaX;
  final double sigmaY;
  final double x;
  final double y;
  final double r;
  final bool filtered;
  final bool inserted;

  DisplacementRecordModel copyWith({
    String? targetId,
    int? ts,
    double? sigmaX,
    double? sigmaY,
    double? x,
    double? y,
    double? r,
    bool? filtered,
    bool? inserted,
  }) {
    return DisplacementRecordModel(
      targetId: targetId ?? this.targetId,
      ts: ts ?? this.ts,
      sigmaX: sigmaX ?? this.sigmaX,
      sigmaY: sigmaY ?? this.sigmaY,
      x: x ?? this.x,
      y: y ?? this.y,
      r: r ?? this.r,
      filtered: filtered ?? this.filtered,
      inserted: inserted ?? this.inserted,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeString(targetId);
    serializer.serializeInt64(ts);
    serializer.serializeFloat64(sigmaX);
    serializer.serializeFloat64(sigmaY);
    serializer.serializeFloat64(x);
    serializer.serializeFloat64(y);
    serializer.serializeFloat64(r);
    serializer.serializeBool(filtered);
    serializer.serializeBool(inserted);
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

    return other is DisplacementRecordModel
      && targetId == other.targetId
      && ts == other.ts
      && sigmaX == other.sigmaX
      && sigmaY == other.sigmaY
      && x == other.x
      && y == other.y
      && r == other.r
      && filtered == other.filtered
      && inserted == other.inserted;
  }

  @override
  int get hashCode => Object.hash(
        targetId,
        ts,
        sigmaX,
        sigmaY,
        x,
        y,
        r,
        filtered,
        inserted,
      );

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'targetId: $targetId, '
        'ts: $ts, '
        'sigmaX: $sigmaX, '
        'sigmaY: $sigmaY, '
        'x: $x, '
        'y: $y, '
        'r: $r, '
        'filtered: $filtered, '
        'inserted: $inserted'
        ')';
      return true;
    }());

    return fullString ?? 'DisplacementRecordModel';
  }
}
