// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class MyAmazingNumber {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _myAmazingNumberStreamController.stream.asBroadcastStream();

  const MyAmazingNumber({
    required this.currentNumber,
  });

  static MyAmazingNumber deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = MyAmazingNumber(
      currentNumber: deserializer.deserializeInt32(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static MyAmazingNumber bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = MyAmazingNumber.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final int currentNumber;

  MyAmazingNumber copyWith({
    int? currentNumber,
  }) {
    return MyAmazingNumber(
      currentNumber: currentNumber ?? this.currentNumber,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeInt32(currentNumber);
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

    return other is MyAmazingNumber
      && currentNumber == other.currentNumber;
  }

  @override
  int get hashCode => currentNumber.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'currentNumber: $currentNumber'
        ')';
      return true;
    }());

    return fullString ?? 'MyAmazingNumber';
  }
}

final _myAmazingNumberStreamController =
    StreamController<RustSignalPack<MyAmazingNumber>>();
