// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


enum SyncServiceControlMsgType {
  stop,
  start,
}

extension SyncServiceControlMsgTypeExtension on SyncServiceControlMsgType {
  static SyncServiceControlMsgType deserialize(BinaryDeserializer deserializer) {
    final index = deserializer.deserializeVariantIndex();
    switch (index) {
      case 0: return SyncServiceControlMsgType.stop;
      case 1: return SyncServiceControlMsgType.start;
      default: throw Exception('Unknown variant index for SyncServiceControlMsgType: ' + index.toString());
    }
  }

  void serialize(BinarySerializer serializer) {
    switch (this) {
      case SyncServiceControlMsgType.stop: return serializer.serializeVariantIndex(0);
      case SyncServiceControlMsgType.start: return serializer.serializeVariantIndex(1);
    }
  }

  Uint8List bincodeSerialize() {
      final serializer = BincodeSerializer();
      serialize(serializer);
      return serializer.bytes;
  }

  static SyncServiceControlMsgType bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = SyncServiceControlMsgTypeExtension.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }
}

