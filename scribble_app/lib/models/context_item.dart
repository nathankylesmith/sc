import 'package:objectbox/objectbox.dart';

@Entity()
class ContextItem {
  @Id()
  int id;

  String filename;
  String content;
  DateTime createdAt;
  final audioContextItem = ToOne<AudioContextItem>();

  ContextItem({
    this.id = 0,
    required this.filename,
    required this.content,
    required this.createdAt,
  });
}

@Entity()
class AudioContextItem {
  @Id()
  int id;

  String filename;
  String filePath;
  DateTime createdAt;

  AudioContextItem({
    this.id = 0,
    required this.filename,
    required this.filePath,
    required this.createdAt,
  });
}