import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/context_item.dart';
import '../objectbox.g.dart';

class DatabaseService {
  late final Store _store;
  late final Box<ContextItem> _contextItemBox;
  late final Box<AudioContextItem> _audioContextItemBox;

  DatabaseService._create(this._store) {
    _contextItemBox = Box<ContextItem>(_store);
    _audioContextItemBox = Box<AudioContextItem>(_store);
  }

  static Future<DatabaseService> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(docsDir.path, "objectbox"));
    return DatabaseService._create(store);
  }

  Future<int> addAudioContextItem(AudioContextItem audioContextItem) async {
    return _audioContextItemBox.put(audioContextItem);
  }

  Future<int> addContextItem(ContextItem contextItem) async {
    return _contextItemBox.put(contextItem);
  }

  List<AudioContextItem> getAllAudioContextItems() {
    return _audioContextItemBox.getAll();
  }

  List<ContextItem> getAllContextItems() {
    return _contextItemBox.getAll();
  }

  AudioContextItem? getAudioContextItem(int id) {
    return _audioContextItemBox.get(id);
  }

  ContextItem? getContextItem(int id) {
    return _contextItemBox.get(id);
  }

  Future<void> deleteAudioContextItem(int id) async {
    _audioContextItemBox.remove(id);
  }

  Future<void> deleteContextItem(int id) async {
    _contextItemBox.remove(id);
  }

  void close() {
    _store.close();
  }

  Future<List<ContextItem>> getContextItems() async {
    // This method is already implemented as getAllContextItems()
    // We can simply call that method and return its result
    return getAllContextItems();
  }
}