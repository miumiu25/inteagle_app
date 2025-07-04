// ignore_for_file: type=lint, type=warning
part of 'signals.dart';
class TraitHelpers {
  static void serializeOptionI32(int? value, BinarySerializer serializer) {
    if (value == null) {
        serializer.serializeOptionTag(false);
    } else {
        serializer.serializeOptionTag(true);
        serializer.serializeInt32(value);
    }
  }

  static int? deserializeOptionI32(BinaryDeserializer deserializer) {
    final tag = deserializer.deserializeOptionTag();
    if (tag) {
        return deserializer.deserializeInt32();
    } else {
        return null;
    }
  }

  static void serializeOptionI64(int? value, BinarySerializer serializer) {
    if (value == null) {
        serializer.serializeOptionTag(false);
    } else {
        serializer.serializeOptionTag(true);
        serializer.serializeInt64(value);
    }
  }

  static int? deserializeOptionI64(BinaryDeserializer deserializer) {
    final tag = deserializer.deserializeOptionTag();
    if (tag) {
        return deserializer.deserializeInt64();
    } else {
        return null;
    }
  }

  static void serializeOptionStr(String? value, BinarySerializer serializer) {
    if (value == null) {
        serializer.serializeOptionTag(false);
    } else {
        serializer.serializeOptionTag(true);
        serializer.serializeString(value);
    }
  }

  static String? deserializeOptionStr(BinaryDeserializer deserializer) {
    final tag = deserializer.deserializeOptionTag();
    if (tag) {
        return deserializer.deserializeString();
    } else {
        return null;
    }
  }

  static void serializeVectorDisplacementRecordModel(List<DisplacementRecordModel> value, BinarySerializer serializer) {
    serializer.serializeLength(value.length);
    for (final item in value) {
        item.serialize(serializer);
    }
  }

  static List<DisplacementRecordModel> deserializeVectorDisplacementRecordModel(BinaryDeserializer deserializer) {
    final length = deserializer.deserializeLength();
    return List.generate(length, (_) => DisplacementRecordModel.deserialize(deserializer));
  }

  static void serializeVectorStr(List<String> value, BinarySerializer serializer) {
    serializer.serializeLength(value.length);
    for (final item in value) {
        serializer.serializeString(item);
    }
  }

  static List<String> deserializeVectorStr(BinaryDeserializer deserializer) {
    final length = deserializer.deserializeLength();
    return List.generate(length, (_) => deserializer.deserializeString());
  }

}

