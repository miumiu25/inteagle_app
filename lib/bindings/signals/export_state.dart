// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


enum ExportState {
  running,
  stop,
  finished,
}

extension ExportStateExtension on ExportState {
  static ExportState deserialize(BinaryDeserializer deserializer) {
    final index = deserializer.deserializeVariantIndex();
    switch (index) {
      case 0: return ExportState.running;
      case 1: return ExportState.stop;
      case 2: return ExportState.finished;
      default: throw Exception('Unknown variant index for ExportState: ' + index.toString());
    }
  }

  void serialize(BinarySerializer serializer) {
    switch (this) {
      case ExportState.running: return serializer.serializeVariantIndex(0);
      case ExportState.stop: return serializer.serializeVariantIndex(1);
      case ExportState.finished: return serializer.serializeVariantIndex(2);
    }
  }

  Uint8List bincodeSerialize() {
      final serializer = BincodeSerializer();
      serialize(serializer);
      return serializer.bytes;
  }

  static ExportState bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = ExportStateExtension.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }
}

