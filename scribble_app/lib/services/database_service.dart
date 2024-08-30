import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/context_item.dart';
import '../objectbox.g.dart';
import '../models/audio_recording.dart';
import 'package:objectbox/objectbox.dart';

class DatabaseService {
  late final Store _store;
  late final Box<AudioRecording> _audioRecordingBox;
  

  DatabaseService._create(this._store) {
    _audioRecordingBox = Box<AudioRecording>(_store);
  }

  static Future<DatabaseService> create() async {
    final store = await openStore();
    return DatabaseService._create(store);
  }

  Box<AudioRecording> get audioRecordingBox => _audioRecordingBox;
  Box<ContextItem> get contextItemBox => _store.box<ContextItem>();

  Future<void> deleteAudioRecording(AudioRecording recording) async {
    // Delete the file from the file system
    final file = File(recording.filePath);
    if (await file.exists()) {
      await file.delete();
    }

    // Remove the recording from the database
    audioRecordingBox.remove(recording.id);
  }
}

Future<void> initialize() async {
  final store = await openStore();
  DatabaseService._create(store);
}