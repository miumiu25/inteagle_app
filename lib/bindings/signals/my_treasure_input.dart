// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class MyTreasureInput {
  const MyTreasureInput(
  );

  static MyTreasureInput deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = MyTreasureInput(
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static MyTreasureInput bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = MyTreasureInput.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
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

    return other is MyTreasureInput;
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

    return fullString ?? 'MyTreasureInput';
  }
}

extension MyTreasureInputDartSignalExt on MyTreasureInput {
  /// Sends the signal to Rust.
  /// Passing data from Rust to Dart involves a memory copy
  /// because Rust cannot own data managed by Dart's garbage collector.
  void sendSignalToRust() {
    final messageBytes = bincodeSerialize();
    final binary = Uint8List(0);
    sendDartSignal(
      'rinf_send_dart_signal_my_treasure_input',
      messageBytes,
      binary,
    );
  }
}
