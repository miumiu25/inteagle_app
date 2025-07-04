// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class MyTreasureOutput {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _myTreasureOutputStreamController.stream.asBroadcastStream();

  const MyTreasureOutput({
    required this.currentValue,
  });

  static MyTreasureOutput deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = MyTreasureOutput(
      currentValue: deserializer.deserializeInt32(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static MyTreasureOutput bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = MyTreasureOutput.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final int currentValue;

  MyTreasureOutput copyWith({
    int? currentValue,
  }) {
    return MyTreasureOutput(
      currentValue: currentValue ?? this.currentValue,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeInt32(currentValue);
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

    return other is MyTreasureOutput
      && currentValue == other.currentValue;
  }

  @override
  int get hashCode => currentValue.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'currentValue: $currentValue'
        ')';
      return true;
    }());

    return fullString ?? 'MyTreasureOutput';
  }
}

final _myTreasureOutputStreamController =
    StreamController<RustSignalPack<MyTreasureOutput>>();
