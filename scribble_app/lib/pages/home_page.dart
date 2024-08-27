import 'package:flutter/material.dart';
import '../services/ble_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BleService _bleService = BleService();
  bool _isConnected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ... other widgets ...
            ElevatedButton(
              onPressed: _toggleBleConnection,
              child: Text(_isConnected ? 'Disconnect BLE' : 'Connect BLE'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleBleConnection() async {
    if (_isConnected) {
      await _bleService.disconnectDevice();
      setState(() {
        _isConnected = false;
      });
    } else {
      try {
        await _bleService.connectToDevice();
        setState(() {
          _isConnected = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }
}

