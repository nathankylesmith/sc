import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../objectbox.g.dart';
import '../models/context_item.dart';

class DatabaseService {
  late final Store _store;
  late final Box<ContextItem> _contextBox;

  Future<void> initialize() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(docsDir.path, "objectbox");
    _store = await openStore(directory: dbPath);
    _contextBox = _store.box<ContextItem>();
  }

  Future<int> addContextItem(String content, List<double> embedding) async {
    final item = ContextItem(content: content, embedding: embedding);
    return _contextBox.put(item);
  }

  List<ContextItem> getAllContextItems() {
    return _contextBox.getAll();
  }

  List<String> getRelatedContext(List<double> queryEmbedding) {
    // This is a simple implementation. For production, you'd want to use
    // a more sophisticated similarity search algorithm.
    final allItems = getAllContextItems();
    allItems.sort((a, b) {
      final distA = _euclideanDistance(a.embedding, queryEmbedding);
      final distB = _euclideanDistance(b.embedding, queryEmbedding);
      return distA.compareTo(distB);
    });
    return allItems.take(5).map((item) => item.content).toList();
  }

  double _euclideanDistance(List<double> a, List<double> b) {
    if (a.length != b.length) throw Exception("Vectors must be of the same length");
    return List.generate(a.length, (i) => (a[i] - b[i]) * (a[i] - b[i]))
        .reduce((sum, n) => sum + n);
  }

  void close() {
    _store.close();
  }
}