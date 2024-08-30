import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:scribble_app/backend/preferences.dart';
import 'package:scribble_app/backend/schema/bt_device.dart';
import 'package:scribble_app/utils/ble/connect.dart';
import 'package:scribble_app/utils/ble/find.dart';
import 'package:scribble_app/utils/ble/gatt_utils.dart';

Future<BTDeviceStruct?> scanAndConnectDevice({bool autoConnect = true, bool timeout = false}) async {
  debugPrint('Starting scanAndConnectDevice');
  var deviceId = SharedPreferencesUtil().deviceId;
  debugPrint('Stored deviceId: $deviceId');

  // Check Bluetooth adapter state
  var adapterState = await FlutterBluePlus.adapterState.first;
  debugPrint('Bluetooth adapter state: $adapterState');
  if (adapterState != BluetoothAdapterState.on) {
    debugPrint('Bluetooth is not available or turned off');
    return null;
  }

  // Disconnect from any currently connected device
  for (var device in await FlutterBluePlus.connectedDevices) {
    debugPrint('Disconnecting from ${device.platformName}');
    await device.disconnect();
  }

  debugPrint('Starting BLE scan');
  await FlutterBluePlus.startScan(timeout: Duration(seconds: 30));

  try {
    await for (final results in FlutterBluePlus.scanResults) {
      debugPrint('Scan results received. Found ${results.length} devices');
      for (ScanResult r in results) {
        debugPrint('Device found: ${r.device.platformName} (${r.device.remoteId.str})');
        debugPrint('  RSSI: ${r.rssi}');
        debugPrint('  Connectable: ${r.advertisementData.connectable}');
        debugPrint('  Local Name: ${r.advertisementData.localName}');
        debugPrint('  Service UUIDs: ${r.advertisementData.serviceUuids}');
        
        if (r.device.platformName == 'Friend' || r.advertisementData.serviceUuids.contains(friendServiceUuid)) {
          debugPrint('Friend device found. Stopping scan');
          await FlutterBluePlus.stopScan();
          
          try {
            debugPrint('Attempting to connect to Friend device: ${r.device.platformName}');
            await r.device.connect(autoConnect: autoConnect);
            debugPrint('Successfully connected to Friend device: ${r.device.platformName}');
            
            SharedPreferencesUtil().deviceId = r.device.remoteId.str;
            SharedPreferencesUtil().deviceName = r.device.platformName;

            return BTDeviceStruct(
              id: r.device.remoteId.str,
              name: r.device.platformName,
              rssi: r.rssi,
            );
          } catch (e) {
            debugPrint('Failed to connect to Friend device: $e');
          }
        } else {
          debugPrint('Skipping non-Friend device');
        }
      }
    }
  } catch (e) {
    debugPrint('Error during scan: $e');
  } finally {
    debugPrint('Ensuring scan is stopped');
    await FlutterBluePlus.stopScan();
  }

  debugPrint('No Friend device found or connection failed');
  return null;
}
