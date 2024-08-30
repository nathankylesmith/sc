import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:typed_data';

class AudioService {
  late FlutterSoundRecorder _recorder;

  Future<void> initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder.openRecorder();
  }

  Future<void> startRecording(String filePath) async {
    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
      sampleRate: 44100,
      numChannels: 1,
    );
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
  }

  Future<String> saveAudioFile(List<int> audioBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    
    // Create a properly formatted WAV file
    final wavFile = await _createWavFile(audioBytes);
    await file.writeAsBytes(wavFile);
    
    // Verify that the file was created and is accessible
    if (await file.exists()) {
      print('Audio file saved successfully at: $filePath');
      print('File size: ${await file.length()} bytes');
    } else {
      print('Failed to save audio file at: $filePath');
    }
    
    return filePath;
  }

  Future<Uint8List> _createWavFile(List<int> audioBytes) async {
    final int fileSize = audioBytes.length + 36;
    final ByteData byteData = ByteData(44 + audioBytes.length);
    
    // WAV header
    byteData.setUint32(0, 0x52494646, Endian.big); // "RIFF"
    byteData.setUint32(4, fileSize, Endian.little);
    byteData.setUint32(8, 0x57415645, Endian.big); // "WAVE"
    byteData.setUint32(12, 0x666D7420, Endian.big); // "fmt "
    byteData.setUint32(16, 16, Endian.little); // Size of fmt chunk
    byteData.setUint16(20, 1, Endian.little); // Audio format (1 = PCM)
    byteData.setUint16(22, 1, Endian.little); // Number of channels
    byteData.setUint32(24, 44100, Endian.little); // Sample rate
    byteData.setUint32(28, 88200, Endian.little); // Byte rate
    byteData.setUint16(32, 2, Endian.little); // Block align
    byteData.setUint16(34, 16, Endian.little); // Bits per sample
    byteData.setUint32(36, 0x64617461, Endian.big); // "data"
    byteData.setUint32(40, audioBytes.length, Endian.little);
    
    // Audio data
    for (int i = 0; i < audioBytes.length; i++) {
      byteData.setUint8(44 + i, audioBytes[i]);
    }
    
    return byteData.buffer.asUint8List();
  }
}