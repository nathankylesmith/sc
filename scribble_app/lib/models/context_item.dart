import 'package:objectbox/objectbox.dart';

@Entity()
class ContextItem {
  int id;
  String content;
  List<double> embedding;

  ContextItem({this.id = 0, required this.content, required this.embedding});
}