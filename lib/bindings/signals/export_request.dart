// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class ExportRequest {
  const ExportRequest({
    required this.format,
    required this.databasePath,
    required this.outputFilePath,
    required this.targets,
    this.startTs,
    this.endTs,
  });

  static ExportRequest deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = ExportRequest(
      format: ExportFormatExtension.deserialize(deserializer),
      databasePath: deserializer.deserializeString(),
      outputFilePath: deserializer.deserializeString(),
      targets: TraitHelpers.deserializeVectorStr(deserializer),
      startTs: TraitHelpers.deserializeOptionI64(deserializer),
      endTs: TraitHelpers.deserializeOptionI64(deserializer),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static ExportRequest bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = ExportRequest.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final ExportFormat format;
  final String databasePath;
  final String outputFilePath;
  final List<String> targets;
  final int? startTs;
  final int? endTs;

  ExportRequest copyWith({
    ExportFormat? format,
    String? databasePath,
    String? outputFilePath,
    List<String>? targets,
    int? Function()? startTs,
    int? Function()? endTs,
  }) {
    return ExportRequest(
      format: format ?? this.format,
      databasePath: databasePath ?? this.databasePath,
      outputFilePath: outputFilePath ?? this.outputFilePath,
      targets: targets ?? this.targets,
      startTs: startTs == null ? this.startTs : startTs(),
      endTs: endTs == null ? this.endTs : endTs(),
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    format.serialize(serializer);
    serializer.serializeString(databasePath);
    serializer.serializeString(outputFilePath);
    TraitHelpers.serializeVectorStr(targets, serializer);
    TraitHelpers.serializeOptionI64(startTs, serializer);
    TraitHelpers.serializeOptionI64(endTs, serializer);
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

    return other is ExportRequest
      && format == other.format
      && databasePath == other.databasePath
      && outputFilePath == other.outputFilePath
      && listEquals(targets, other.targets)
      && startTs == other.startTs
      && endTs == other.endTs;
  }

  @override
  int get hashCode => Object.hash(
        format,
        databasePath,
        outputFilePath,
        targets,
        startTs,
        endTs,
      );

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'format: $format, '
        'databasePath: $databasePath, '
        'outputFilePath: $outputFilePath, '
        'targets: $targets, '
        'startTs: $startTs, '
        'endTs: $endTs'
        ')';
      return true;
    }());

    return fullString ?? 'ExportRequest';
  }
}
