part of 'signals.dart';

final assignRustSignal = <String, void Function(Uint8List, Uint8List)>{
  'BigBool': (Uint8List messageBytes, Uint8List binary) {
    final message = BigBool.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _bigBoolStreamController.add(rustSignal);
  },
  'DisplacementRecord': (Uint8List messageBytes, Uint8List binary) {
    final message = DisplacementRecord.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _displacementRecordStreamController.add(rustSignal);
  },
  'ExportProgress': (Uint8List messageBytes, Uint8List binary) {
    final message = ExportProgress.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _exportProgressStreamController.add(rustSignal);
  },
  'MyAmazingNumber': (Uint8List messageBytes, Uint8List binary) {
    final message = MyAmazingNumber.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _myAmazingNumberStreamController.add(rustSignal);
  },
  'MyTreasureOutput': (Uint8List messageBytes, Uint8List binary) {
    final message = MyTreasureOutput.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _myTreasureOutputStreamController.add(rustSignal);
  },
  'SmallNumber': (Uint8List messageBytes, Uint8List binary) {
    final message = SmallNumber.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _smallNumberStreamController.add(rustSignal);
  },
  'SyncProgress': (Uint8List messageBytes, Uint8List binary) {
    final message = SyncProgress.bincodeDeserialize(messageBytes);
    final rustSignal = RustSignalPack(
      message,
      binary,
    );
    _syncProgressStreamController.add(rustSignal);
  },
};
