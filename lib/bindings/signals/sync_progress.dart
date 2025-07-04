// ignore_for_file: type=lint, type=warning
part of 'signals.dart';


@immutable
class SyncProgress {
  /// An async broadcast stream that listens for signals from Rust.
  /// It supports multiple subscriptions.
  /// Make sure to cancel the subscription when it's no longer needed,
  /// such as when a widget is disposed.
  static final rustSignalStream =
      _syncProgressStreamController.stream.asBroadcastStream();

  const SyncProgress({
    required this.totalTimeSpanMs,
    required this.processedTimeSpanMs,
    required this.progressPercentage,
    required this.totalRecordsSynced,
    required this.currentWindowStart,
    required this.currentWindowEnd,
    required this.estimatedRemainingTimeMs,
  });

  static SyncProgress deserialize(BinaryDeserializer deserializer) {
    deserializer.increaseContainerDepth();
    final instance = SyncProgress(
      totalTimeSpanMs: deserializer.deserializeInt64(),
      processedTimeSpanMs: deserializer.deserializeInt64(),
      progressPercentage: deserializer.deserializeFloat64(),
      totalRecordsSynced: deserializer.deserializeUint64(),
      currentWindowStart: deserializer.deserializeInt64(),
      currentWindowEnd: deserializer.deserializeInt64(),
      estimatedRemainingTimeMs: deserializer.deserializeInt64(),
    );
    deserializer.decreaseContainerDepth();
    return instance;
  }

  static SyncProgress bincodeDeserialize(Uint8List input) {
    final deserializer = BincodeDeserializer(input);
    final value = SyncProgress.deserialize(deserializer);
    if (deserializer.offset < input.length) {
      throw Exception('Some input bytes were not read');
    }
    return value;
  }

  final int totalTimeSpanMs;
  final int processedTimeSpanMs;
  final double progressPercentage;
  final Uint64 totalRecordsSynced;
  final int currentWindowStart;
  final int currentWindowEnd;
  final int estimatedRemainingTimeMs;

  SyncProgress copyWith({
    int? totalTimeSpanMs,
    int? processedTimeSpanMs,
    double? progressPercentage,
    Uint64? totalRecordsSynced,
    int? currentWindowStart,
    int? currentWindowEnd,
    int? estimatedRemainingTimeMs,
  }) {
    return SyncProgress(
      totalTimeSpanMs: totalTimeSpanMs ?? this.totalTimeSpanMs,
      processedTimeSpanMs: processedTimeSpanMs ?? this.processedTimeSpanMs,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      totalRecordsSynced: totalRecordsSynced ?? this.totalRecordsSynced,
      currentWindowStart: currentWindowStart ?? this.currentWindowStart,
      currentWindowEnd: currentWindowEnd ?? this.currentWindowEnd,
      estimatedRemainingTimeMs: estimatedRemainingTimeMs ?? this.estimatedRemainingTimeMs,
    );
  }

  void serialize(BinarySerializer serializer) {
    serializer.increaseContainerDepth();
    serializer.serializeInt64(totalTimeSpanMs);
    serializer.serializeInt64(processedTimeSpanMs);
    serializer.serializeFloat64(progressPercentage);
    serializer.serializeUint64(totalRecordsSynced);
    serializer.serializeInt64(currentWindowStart);
    serializer.serializeInt64(currentWindowEnd);
    serializer.serializeInt64(estimatedRemainingTimeMs);
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

    return other is SyncProgress
      && totalTimeSpanMs == other.totalTimeSpanMs
      && processedTimeSpanMs == other.processedTimeSpanMs
      && progressPercentage == other.progressPercentage
      && totalRecordsSynced == other.totalRecordsSynced
      && currentWindowStart == other.currentWindowStart
      && currentWindowEnd == other.currentWindowEnd
      && estimatedRemainingTimeMs == other.estimatedRemainingTimeMs;
  }

  @override
  int get hashCode => Object.hash(
        totalTimeSpanMs,
        processedTimeSpanMs,
        progressPercentage,
        totalRecordsSynced,
        currentWindowStart,
        currentWindowEnd,
        estimatedRemainingTimeMs,
      );

  @override
  String toString() {
    String? fullString;

    assert(() {
      fullString = '$runtimeType('
        'totalTimeSpanMs: $totalTimeSpanMs, '
        'processedTimeSpanMs: $processedTimeSpanMs, '
        'progressPercentage: $progressPercentage, '
        'totalRecordsSynced: $totalRecordsSynced, '
        'currentWindowStart: $currentWindowStart, '
        'currentWindowEnd: $currentWindowEnd, '
        'estimatedRemainingTimeMs: $estimatedRemainingTimeMs'
        ')';
      return true;
    }());

    return fullString ?? 'SyncProgress';
  }
}

final _syncProgressStreamController =
    StreamController<RustSignalPack<SyncProgress>>();
