// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class ExportProgress {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _exportProgressStreamController.stream.asBroadcastStream();

  const ExportProgress({
    required this.state,
    required this.totalRows,
    required this.processedRows,
  });

  static ExportProgress deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = ExportProgress(
      state: ExportStateExtension.deserialize(deserializer),
      totalRows: deserializer.deserializeInt64(),
      processedRows: deserializer.deserializeInt64(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static ExportProgress bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = ExportProgress.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final ExportState state;
  final int totalRows;
  final int processedRows;

  ExportProgress copyWith({
    ExportState? state,
    int? totalRows,
    int? processedRows,
  }) {
    return ExportProgress(
      state: state ?? this.state,
      totalRows: totalRows ?? this.totalRows,
      processedRows: processedRows ?? this.processedRows,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    state.serialize(serializer);
    serializer.serializeInt64(totalRows);
    serializer.serializeInt64(processedRows);
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

    return other is ExportProgress
      && state == other.state
      && totalRows == other.totalRows
      && processedRows == other.processedRows;
  }

  @override
  int get hashCode => Object.hash(
        state,
        totalRows,
        processedRows,
      );

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'state: $state, '
        'totalRows: $totalRows, '
        'processedRows: $processedRows'
        ')';
      return true;
    }());

    return fullString ?? 'ExportProgress';
  }
}

final _exportProgressStreamController =
    StreamController<RustSignalPack<ExportProgress>>();
