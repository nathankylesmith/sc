import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../services/ble_service.dart';
import '../services/database_service.dart';
import '../backend/preferences.dart';
import '../backend/schema/bt_device.dart';
import '../utils/ble/scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:objectbox/objectbox.dart';
import '../models/audio_recording.dart';
import '../utils/ble/gatt_utils.dart';
import 'view_context_page.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:async';
import '../services/audio_service.dart';

class HomePage extends StatefulWidget {
  final DatabaseService databaseService;

  const HomePage({Key? key, required this.databaseService}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BleService _bleService = BleService();
  bool _isConnected = false;
  BTDeviceStruct? _connectedDevice;
  bool _isRecording = false;
  BluetoothCharacteristic? _audioCharacteristic;
  List<int> _audioBuffer = [];
  int _sampleRate = 8000; // Change to 8000 Hz, which is more common for Bluetooth audio
  int _numChannels = 1; // Mono audio
  int _bitsPerSample = 8; // Change to 8-bit audio
  bool _isULaw = true; // Set to true if the device is using µ-law encoding
  BleAudioCodec _audioCodec = BleAudioCodec.unknown;
  final AudioService _audioService = AudioService();
  StreamSubscription<List<int>>? _audioSubscription;
  Timer? _connectionCheckTimer;
  bool _isProcessingAudio = false;

  @override
  void initState() {
    super.initState();
    _updateConnectedDeviceInfo();
    _startConnectionCheck();
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _connectionCheckTimer?.cancel();
    super.dispose();
  }

  void _startConnectionCheck() {
    _connectionCheckTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (_isConnected && _connectedDevice != null) {
        _checkConnectionStatus();
      }
    });
  }

  Future<void> _checkConnectionStatus() async {
    try {
      final device = BluetoothDevice.fromId(_connectedDevice!.id);
      await device.state.first;
    } catch (e) {
      print('BLE connection lost: $e');
      await _handleDisconnection();
    }
  }

  Future<void> _handleDisconnection() async {
    setState(() {
      _isConnected = false;
      _connectedDevice = null;
    });
    if (_isRecording) {
      _stopRecording();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('BLE connection lost. Attempting to reconnect...')),
    );
    await _reconnectToDevice();
  }

  Future<void> _reconnectToDevice() async {
    final deviceId = SharedPreferencesUtil().deviceId;
    if (deviceId.isNotEmpty) {
      try {
        final device = await scanAndConnectDevice(autoConnect: true);
        setState(() {
          _connectedDevice = device;
          _isConnected = device != null;
        });
        if (device != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reconnected to ${device.name}')),
          );
        }
      } catch (e) {
        print('Failed to reconnect: $e');
      }
    }
  }

  void _resetAudioSettings() {
    _sampleRate = 8000;
    _bitsPerSample = 8;
    _numChannels = 1;
    _audioCodec = BleAudioCodec.unknown;
    _audioBuffer.clear();
    _isULaw = false;
    _audioService.resetBuffer();
  }

  void _updateConnectedDeviceInfo() async {
    final deviceId = SharedPreferencesUtil().deviceId;
    if (deviceId.isNotEmpty) {
      final device = await scanAndConnectDevice(autoConnect: true);
      setState(() {
        _connectedDevice = device;
        _isConnected = device != null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        backgroundColor: const Color.fromARGB(255, 191, 12, 200),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[400]!, Colors.blue[800]!],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // ... other widgets ...
              ElevatedButton(
                onPressed: _toggleBleConnection,
                child: Text(_isConnected ? 'Disconnect BLE' : 'Connect BLE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color.fromARGB(255, 175, 46, 160),
                ),
              ),
              if (_connectedDevice != null) ...[
                Text(
                  'Connected Device: ${_connectedDevice!.name}',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  'Device ID: ${_connectedDevice!.getShortId()}',
                  style: TextStyle(color: Colors.white),
                ),
                if (_connectedDevice!.rssi != null)
                  Text(
                    'RSSI: ${_connectedDevice!.rssi}',
                    style: TextStyle(color: Colors.white),
                  ),
                if (_connectedDevice!.fwver != null)
                  Text(
                    'Firmware Version: ${String.fromCharCodes(_connectedDevice!.fwver!)}',
                    style: TextStyle(color: Colors.white),
                  ),
              ],
              if (_isConnected) ...[
                ElevatedButton(
                  onPressed: _isRecording ? null : _startRecording,
                  child: Text('Start Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : null,
                  child: Text('Stop Recording'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ViewContextPage(databaseService: widget.databaseService)),
                  );
                },
                child: Text('View Context'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleBleConnection() async {
    if (_isConnected) {
      debugPrint('Disconnecting from current device');
      await _bleService.disconnectDevice();
      setState(() {
        _isConnected = false;
        _connectedDevice = null;
      });
      debugPrint('Device disconnected');
    } else {
      // Check if Bluetooth is available and on
      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        String message = adapterState == BluetoothAdapterState.off
            ? 'Please turn on Bluetooth'
            : 'Bluetooth is not available on this device';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
        return;
      }

      // Check and request necessary permissions
      if (!await _checkAndRequestPermissions()) {
        debugPrint('Bluetooth permissions not granted');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bluetooth permissions are required')),
        );
        return;
      }

      try {
        debugPrint('Starting device connection process');
        final device = await _bleService.connectToDevice();
        if (device != null) {
          debugPrint('Successfully connected to device: ${device.name}');
          setState(() {
            _isConnected = true;
            _connectedDevice = device;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected successfully to ${device.name}')),
          );
        } else {
          debugPrint('Connection attempt returned null device');
          throw Exception('Failed to connect to device: No device found');
        }
      } catch (e) {
        debugPrint('Error during connection attempt: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      var bluetoothScan = await Permission.bluetoothScan.status;
      var bluetoothConnect = await Permission.bluetoothConnect.status;
      var locationWhenInUse = await Permission.locationWhenInUse.status;

      if (!bluetoothScan.isGranted || !bluetoothConnect.isGranted || !locationWhenInUse.isGranted) {
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse
        ].request();
      }

      return await Permission.bluetoothScan.isGranted &&
             await Permission.bluetoothConnect.isGranted &&
             await Permission.locationWhenInUse.isGranted;
    }

    return true; // For iOS, permissions are handled differently
  }

  void _startRecording() async {
    if (!_isConnected || _connectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please connect to a device first')),
      );
      return;
    }

    _resetAudioSettings();

    try {
      final device = BluetoothDevice.fromId(_connectedDevice!.id);
      final services = await device.discoverServices();
      final audioService = services.firstWhere(
        (s) => s.uuid.toString() == friendServiceUuid,
        orElse: () => throw Exception('Audio service not found'),
      );
      
      final codecCharacteristic = audioService.characteristics.firstWhere(
        (c) => c.uuid.toString() == audioCodecCharacteristicUuid,
        orElse: () => throw Exception('Audio codec characteristic not found'),
      );
      
      final codecValue = await codecCharacteristic.read();
      _audioCodec = mapNameToCodec(String.fromCharCodes(codecValue));
      
      print('Detected audio codec: $_audioCodec');
      
      // Update audio settings based on codec
      switch (_audioCodec) {
        case BleAudioCodec.pcm16:
          _sampleRate = 16000;
          _bitsPerSample = 16;
          break;
        case BleAudioCodec.mulaw8:
        case BleAudioCodec.mulaw16:
          _sampleRate = 8000;
          _bitsPerSample = 16; // We'll convert µ-law to 16-bit PCM
          _isULaw = true;
          break;
        default:
          // Keep default settings for unknown codecs
          break;
      }
      
      _audioCharacteristic = audioService.characteristics.firstWhere(
        (c) => c.uuid.toString() == audioDataStreamCharacteristicUuid,
        orElse: () => throw Exception('Audio characteristic not found'),
      );

      await _audioCharacteristic!.setNotifyValue(true);
      _audioSubscription = _audioCharacteristic!.value.listen(_processAudioData);

      setState(() {
        _isRecording = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording started')),
      );
      
      print('Sample rate: $_sampleRate');
      print('Bits per sample: $_bitsPerSample');
      print('Number of channels: $_numChannels');
    } catch (e) {
      print('Error starting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  void _processAudioData(List<int> value) async {
    if (_isProcessingAudio) return;
    _isProcessingAudio = true;

    try {
      if (value.length > 3) {
        var audioData = value.sublist(3); // Skip the first 3 bytes (header)
        await _audioService.addAudioData(audioData);
      }
    } catch (e) {
      print('Error processing audio data: $e');
    } finally {
      _isProcessingAudio = false;
    }
  }

  void _stopRecording() async {
    if (_audioCharacteristic == null) {
      print('Audio characteristic is null');
      return;
    }

    try {
      await _audioCharacteristic!.setNotifyValue(false);
      _audioSubscription?.cancel();

      final timestamp = DateTime.now();
      final fileName = 'audio_${timestamp.millisecondsSinceEpoch}.wav';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      await _audioService.saveAudioFile(fileName, _sampleRate, _numChannels, _bitsPerSample);

      final audioRecording = AudioRecording(
        timestamp: timestamp,
        filePath: filePath,
        duration: _audioService.getDuration(_sampleRate, _numChannels, _bitsPerSample),
      );

      final id = widget.databaseService.audioRecordingBox.put(audioRecording);
      print('Audio recording saved successfully with id: $id');

      setState(() {
        _isRecording = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording stopped and saved')),
      );
    } catch (e) {
      print('Error stopping recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
      );
    }
  }

  List<int> intToBytes(int value, int length) {
    return List<int>.generate(length, (i) => (value >> (8 * i)) & 0xFF);
  }

  List<int> _decodeULaw(List<int> ulawData) {
    final ulaw2linear = List<int>.generate(256, (i) {
      var u = ~i;
      int t = ((u & 0x0F) << 3) + 0x84;
      t <<= ((u & 0x70) >> 4);
      return ((u & 0x80) != 0 ? (0x84 - t) : (t - 0x84)) * 2;
    });

    return ulawData.expand((byte) {
      int sample = ulaw2linear[byte];
      return [sample & 0xFF, (sample >> 8) & 0xFF];
    }).toList();
  }
}
