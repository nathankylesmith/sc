import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../backend/schema/bt_device.dart';
import '../utils/ble/scan.dart';
import 'package:flutter/foundation.dart';

class BleService {
  BTDeviceStruct? connectedDevice;

  Future<BTDeviceStruct?> connectToDevice() async {
    debugPrint('BleService: Starting connectToDevice');
    connectedDevice = await scanAndConnectDevice(autoConnect: false);
    if (connectedDevice != null) {
      debugPrint('BleService: Successfully connected to ${connectedDevice!.name}');
    } else {
      debugPrint('BleService: Failed to connect to any device');
    }
    return connectedDevice;
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      debugPrint('BleService: Disconnecting from ${connectedDevice!.name}');
      final device = BluetoothDevice.fromId(connectedDevice!.id);
      await device.disconnect();
      connectedDevice = null;
      debugPrint('BleService: Device disconnected');
    } else {
      debugPrint('BleService: No device to disconnect');
    }
  }
}