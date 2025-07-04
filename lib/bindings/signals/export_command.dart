// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


abstract class ExportCommand {
  const ExportCommand();

  void serialize(BinarySerializer serializer);

  static ExportCommand deserialize(BinaryDeserializer deserializer) {
    int index = deserializer.deserializeVariantIndex();
    switch (index) {
      case 0: return ExportCommandStart.load(deserializer);
      case 1: return ExportCommandStop.load(deserializer);
      default: throw Exception('Unknown variant index for ExportCommand: ' + index.toString());
    }
  }

  Uint8List bincodeSerialize() {
      final serializer = BincodeSerializer();
      serialize(serializer);
      return serializer.bytes;
  }

  static ExportCommand bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = ExportCommand.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }
}


@immutable
class ExportCommandStart extends ExportCommand {
  const ExportCommandStart({
    required this.value,
  }) : super();

  static ExportCommandStart load(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = ExportCommandStart(
      value: ExportRequest.deserialize(deserializer),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  final ExportRequest value;

  ExportCommandStart copyWith({
    ExportRequest? value,
  }) {
    return ExportCommandStart(
      value: value ?? this.value,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeVariantIndex(0);
    value.serialize(serializer);
    serializer.decreaseContainerDepth();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    return other is ExportCommandStart
      && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'value: $value'
        ')';
      return true;
    }());

    return fullString ?? 'ExportCommandStart';
  }
}

@immutable
class ExportCommandStop extends ExportCommand {
  const ExportCommandStop(
  ) : super();

  static ExportCommandStop load(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = ExportCommandStop(
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

    return other is ExportCommandStop;
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

    return fullString ?? 'ExportCommandStop';
  }
}

extension ExportCommandDartSignalExt on ExportCommand {
  /// Sends the signal to Rust.
  /// Passing data from Rust to Dart involves a memory copy
  /// because Rust cannot own data managed by Dart's garbage collector.
  void sendSignalToRust() {
    final messageBytes = bincodeSerialize();
    final binary = Uint8List(0);
    sendDartSignal(
      'rinf_send_dart_signal_export_command',
      messageBytes,
      binary,
    );
  }
}
