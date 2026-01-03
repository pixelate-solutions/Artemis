import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleService {
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;

  Future<void> startScan({
    required List<Guid> withServices,
    required Duration timeout,
  }) {
    return FlutterBluePlus.startScan(
      timeout: timeout,
      withServices: withServices,
    );
  }

  Future<void> stopScan() {
    return FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device, {Duration? timeout}) {
    return device.connect(timeout: timeout ?? const Duration(seconds: 12));
  }

  Future<void> disconnect(BluetoothDevice device) {
    return device.disconnect();
  }

  Future<List<BluetoothService>> discoverServices(BluetoothDevice device) {
    return device.discoverServices();
  }
}
