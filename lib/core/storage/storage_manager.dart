import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

@singleton
class StorageManager {
  final Box _box;

  @injectable
  StorageManager(@Named('app_cache') Box<String> box) : _box = box;

  Future<void> save<T>(String key, T value) async {
    // Box is registered as Box<String> (see DI). Persist everything as String.
    final String encoded = _encodeValue(value);
    await _box.put(key, encoded);
  }

  Future<T?> fetch<T>(String key) async {
    final dynamic raw = _box.get(key);
    if (raw == null) return null;
    return _decodeValue<T>(raw);
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

  String _encodeValue(dynamic value) {
    if (value is String) return 'S:$value';
    if (value is int) return 'I:$value';
    if (value is double) return 'D:$value';
    if (value is bool) return 'B:${value ? 1 : 0}';
    if (value is DateTime) return 'T:${value.toIso8601String()}';
    try {
      return 'J:${jsonEncode(value)}';
    } catch (_) {
      return 'S:${value.toString()}';
    }
  }

  T? _decodeValue<T>(dynamic raw) {
    if (raw is! String) {
      // Fallback cast for unexpected cases
      return raw as T?;
    }
    if (raw.length < 2 || raw[1] != ':') {
      // No prefix; best-effort cast
      return raw as T?;
    }
    final String prefix = raw.substring(0, 2);
    final String body = raw.substring(2);

    switch (prefix) {
      case 'S:':
        return (body) as T?;
      case 'I:':
        return (int.tryParse(body) as T?);
      case 'D:':
        return (double.tryParse(body) as T?);
      case 'B:':
        final v = (body == '1' || body.toLowerCase() == 'true');
        return (v as T?);
      case 'T:':
        final dt = DateTime.tryParse(body);
        return (dt as T?);
      case 'J:':
        try {
          final decoded = jsonDecode(body);
          return decoded as T?;
        } catch (_) {
          return null;
        }
      default:
        return raw as T?;
    }
  }
}
