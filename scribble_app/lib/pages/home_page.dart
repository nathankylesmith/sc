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

  @override
  void initState() {
    super.initState();
    _updateConnectedDeviceInfo();
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
      
      _audioCharacteristic = audioService.characteristics.firstWhere(
        (c) => c.uuid.toString() == audioDataStreamCharacteristicUuid,
        orElse: () => throw Exception('Audio characteristic not found'),
      );

      _audioBuffer.clear(); // Clear the buffer before starting a new recording

      await _audioCharacteristic!.setNotifyValue(true);
      _audioCharacteristic!.value.listen((value) {
        if (value.length > 3) {
          var audioData = value.sublist(3); // Skip the first 3 bytes (header)
          print('Raw audio data (first 10 bytes): ${audioData.take(10).toList()}');
          if (_audioCodec == BleAudioCodec.mulaw8 || _audioCodec == BleAudioCodec.mulaw16) {
            audioData = _decodeULaw(audioData);
            print('Decoded audio data (first 10 samples): ${audioData.take(20).toList()}');
          }
          _audioBuffer.addAll(audioData);
        }
        print('Received audio data: ${value.length} bytes');
        print('Total audio data: ${_audioBuffer.length} bytes');
      });

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

  void _stopRecording() async {
    if (_audioCharacteristic == null) {
      print('Audio characteristic is null');
      return;
    }

    try {
      await _audioCharacteristic!.setNotifyValue(false);

      final timestamp = DateTime.now();
      final fileName = 'audio_${timestamp.millisecondsSinceEpoch}.wav';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      await _createWavFile(filePath, _audioBuffer);

      final audioRecording = AudioRecording(
        timestamp: timestamp,
        filePath: filePath,
        duration: (_audioBuffer.length / (_sampleRate * _numChannels * (_bitsPerSample ~/ 8))).round(),
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

  Future<void> _createWavFile(String filePath, List<int> audioData) async {
    final file = File(filePath);
    final sink = file.openWrite();
    
    final int bitsPerSample = 16; // We're always converting to 16-bit PCM
    final int bytesPerSample = bitsPerSample ~/ 8;
    final int dataSize = audioData.length * bytesPerSample;
    final int fileSize = 36 + dataSize;
    final int byteRate = _sampleRate * _numChannels * bytesPerSample;
    final int blockAlign = _numChannels * bytesPerSample;

    final wavHeader = [
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      ...intToBytes(fileSize, 4), // Chunk size
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      16, 0, 0, 0, // Subchunk1 size (16 bytes)
      1, 0, // Audio format (1 = PCM)
      ...intToBytes(_numChannels, 2), // Number of channels
      ...intToBytes(_sampleRate, 4), // Sample rate
      ...intToBytes(byteRate, 4), // Byte rate
      ...intToBytes(blockAlign, 2), // Block align
      ...intToBytes(bitsPerSample, 2), // Bits per sample
      0x64, 0x61, 0x74, 0x61, // "data"
      ...intToBytes(dataSize, 4), // Subchunk2 size
    ];

    print('WAV header: ${wavHeader.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');

    sink.add(Uint8List.fromList(wavHeader));
    
    // Ensure we're writing 16-bit samples
    if (bytesPerSample == 2) {
      for (int i = 0; i < audioData.length; i += 2) {
        int sample = (audioData[i+1] << 8) | audioData[i];
        sink.add(Uint8List.fromList([sample & 0xFF, (sample >> 8) & 0xFF]));
      }
    } else {
      sink.add(Uint8List.fromList(audioData));
    }

    await sink.close();

    print('WAV file created: $filePath');
    print('File size: ${await file.length()} bytes');
    print('Expected file size: ${fileSize + 8} bytes');
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
