import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/audio_recording.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

class ViewContextPage extends StatefulWidget {
  final DatabaseService databaseService;

  const ViewContextPage({Key? key, required this.databaseService}) : super(key: key);

  @override
  _ViewContextPageState createState() => _ViewContextPageState();
}

class _ViewContextPageState extends State<ViewContextPage> {
  final AudioPlayer audioPlayer = AudioPlayer();
  int? currentlyPlayingIndex;

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration.speech());
  }

  Future<void> playAudio(String filePath, int index) async {
    await initAudioSession();
    print('Attempting to play audio file: $filePath');
    final file = File(filePath);
    if (await file.exists()) {
      final fileSize = await file.length();
      print('File exists. Size: $fileSize bytes');
      
      try {
        await audioPlayer.setFilePath(filePath);
        await audioPlayer.play();
        setState(() {
          currentlyPlayingIndex = index;
        });
        
        audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            print('Audio playback completed');
            setState(() {
              currentlyPlayingIndex = null;
            });
          }
        });

      } catch (e) {
        print('Error playing audio: $e');
        if (e is Exception) {
          print('Exception details:');
          print(e.toString());
        }
        if (e is Error) {
          print('Error stack trace:');
          print(e.stackTrace);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing audio: ${e.toString()}')),
        );
      }
    } else {
      print('File does not exist: $filePath');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio file not found')),
      );
    }
  }

  Future<void> playTestAudio() async {
    try {
      final player = AudioPlayer();
      await player.setAsset('assets/test_audio.wav');
      await player.play();
      print('Test audio playback started');
    } catch (e) {
      print('Error playing test audio: $e');
    }
  }

  void _deleteRecording(AudioRecording recording) async {
    try {
      await widget.databaseService.deleteAudioRecording(recording);

      // Update the state
      setState(() {
        // Remove the recording from the box
        widget.databaseService.audioRecordingBox.remove(recording.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording deleted successfully')),
      );
    } catch (e) {
      print('Error deleting recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete recording: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.databaseService.audioRecordingBox;
    final recordings = box.getAll();

    return Scaffold(
      appBar: AppBar(
        title: Text('View Context'),
        backgroundColor: const Color.fromARGB(255, 191, 12, 200),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: recordings.length,
              itemBuilder: (context, index) {
                final recording = recordings[index];
                return Dismissible(
                  key: Key(recording.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    color: Colors.red,
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteRecording(recording);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Recording deleted')),
                    );
                  },
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Confirm"),
                          content: Text("Are you sure you want to delete this recording?"),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text("Delete"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: ListTile(
                    title: Text('Recording ${index + 1}'),
                    subtitle: Text('Duration: ${recording.duration} seconds'),
                    trailing: Text(recording.timestamp.toString()),
                    leading: IconButton(
                      icon: Icon(currentlyPlayingIndex == index ? Icons.stop : Icons.play_arrow),
                      onPressed: () async {
                        if (await File(recording.filePath).exists()) {
                          playAudio(recording.filePath, index);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Audio file not found')),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Back to Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: playTestAudio,
              child: Text('Play Test Audio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}