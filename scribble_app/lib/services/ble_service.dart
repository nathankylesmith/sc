import 'package:flutter_blue/flutter_blue.dart';

class BleService {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice? connectedDevice;

  Future<void> connectToDevice() async {
    // Start scanning
    await flutterBlue.startScan(timeout: Duration(seconds: 4));

    // Listen to scan results
    var subscription = flutterBlue.scanResults.listen((results) {
      // TODO: Add logic to identify your specific device
      for (ScanResult r in results) {
        if (r.device.name == 'YourDeviceName') {
          // Connect to this device
          r.device.connect().then((_) {
            connectedDevice = r.device;
            print('Connected to ${r.device.name}');
          });
          break;
        }
      }
    });

    // Stop scanning
    await flutterBlue.stopScan();
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
    }
  }
}