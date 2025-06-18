import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

@singleton
class StorageManager {
  final Box _box;

  @injectable
  StorageManager(@Named('app_cache') Box<String> box) : _box = box;

  Future<void> save<T>(String key, T value) async {
    await _box.put(key, value);
  }

  Future<T?> fetch<T>(String key) async {
    return _box.get(key) as T?;
  }

  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  Future<void> clear() async {
    await _box.clear();
  }

  Future<void> saveContext() async {
    await _box.flush();
  }
}
