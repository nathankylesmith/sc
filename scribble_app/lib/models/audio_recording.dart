import 'package:objectbox/objectbox.dart';

@Entity()
class AudioRecording {
  @Id()
  int id = 0;

  DateTime timestamp;
  String filePath;
  int duration;

  AudioRecording({
    required this.timestamp,
    required this.filePath,
    required this.duration,
  });
}