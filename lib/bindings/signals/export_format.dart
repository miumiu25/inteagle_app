// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


enum ExportFormat {
  csv,
  xlsx,
}

extension ExportFormatExtension on ExportFormat {
  static ExportFormat deserialize(BinaryDeserializer deserializer) {
    final index = deserializer.deserializeVariantIndex();
    switch (index) {
      case 0: return ExportFormat.csv;
      case 1: return ExportFormat.xlsx;
      default: throw Exception('Unknown variant index for ExportFormat: ' + index.toString());
    }
  }

  void serialize(BinarySerializer serializer) {
    switch (this) {
      case ExportFormat.csv: return serializer.serializeVariantIndex(0);
      case ExportFormat.xlsx: return serializer.serializeVariantIndex(1);
    }
  }

  Uint8List bincodeSerialize() {
      final serializer = BincodeSerializer();
      serialize(serializer);
      return serializer.bytes;
  }

  static ExportFormat bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = ExportFormatExtension.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }
}

