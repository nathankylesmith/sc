import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:typed_data';

class AudioService {
  late FlutterSoundRecorder _recorder;
  List<int> _audioBuffer = [];
  static const int _maxBufferSize = 1024 * 1024; // 1MB buffer size

  Future<void> initRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder.openRecorder();
  }

  Future<void> startRecording(String filePath, int sampleRate) async {
    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.pcm16WAV,
      sampleRate: sampleRate,
      numChannels: 1,
    );
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
  }

  void resetBuffer() {
    _audioBuffer.clear();
  }

  Future<void> addAudioData(List<int> data) async {
    _audioBuffer.addAll(data);
    if (_audioBuffer.length > _maxBufferSize) {
      await _writeBufferToDisk();
    }
  }

  Future<void> _writeBufferToDisk() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/temp_audio_buffer.raw');
    await file.writeAsBytes(_audioBuffer, mode: FileMode.append);
    _audioBuffer.clear();
  }

  Future<String> saveAudioFile(String fileName, int sampleRate, int numChannels, int bitsPerSample) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    
    // Create a properly formatted WAV file
    final wavFile = await _createWavFile(sampleRate, numChannels, bitsPerSample);
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

  Future<Uint8List> _createWavFile(int sampleRate, int numChannels, int bitsPerSample) async {
    final tempFile = File('${(await getApplicationDocumentsDirectory()).path}/temp_audio_buffer.raw');
    if (await tempFile.exists()) {
      final rawAudioData = await tempFile.readAsBytes();
      _audioBuffer.addAll(rawAudioData);
      await tempFile.delete();
    }

    // Force 16-bit PCM
    bitsPerSample = 16;
    final int bytesPerSample = 2;
    final int dataSize = _audioBuffer.length;
    final int fileSize = 36 + dataSize;
    final int byteRate = sampleRate * numChannels * bytesPerSample;
    final int blockAlign = numChannels * bytesPerSample;

    final wavHeader = [
      0x52, 0x49, 0x46, 0x46, // "RIFF"
      ...intToBytes(fileSize, 4), // Chunk size
      0x57, 0x41, 0x56, 0x45, // "WAVE"
      0x66, 0x6D, 0x74, 0x20, // "fmt "
      16, 0, 0, 0, // Subchunk1 size (16 bytes)
      1, 0, // Audio format (1 = PCM)
      ...intToBytes(numChannels, 2), // Number of channels
      ...intToBytes(sampleRate, 4), // Sample rate
      ...intToBytes(byteRate, 4), // Byte rate
      ...intToBytes(blockAlign, 2), // Block align
      ...intToBytes(bitsPerSample, 2), // Bits per sample
      0x64, 0x61, 0x74, 0x61, // "data"
      ...intToBytes(dataSize, 4), // Subchunk2 size
    ];

    final wavFile = Uint8List(44 + dataSize);
    wavFile.setRange(0, 44, wavHeader);
    wavFile.setRange(44, 44 + dataSize, _audioBuffer);

    print('WAV Header: ${wavHeader.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
    print('First 10 bytes of audio data: ${_audioBuffer.take(10).map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');

    _audioBuffer.clear();
    return wavFile;
  }

  int getDuration(int sampleRate, int numChannels, int bitsPerSample) {
    final bytesPerSample = bitsPerSample ~/ 8;
    return (_audioBuffer.length / (sampleRate * numChannels * bytesPerSample)).round();
  }

  List<int> intToBytes(int value, int length) {
    return List<int>.generate(length, (i) => (value >> (8 * i)) & 0xFF);
  }
}