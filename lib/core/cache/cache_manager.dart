import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../config/app_config.dart';
import 'package:daily_english/features/reader/data/models/book_model.dart';

@singleton
class CacheManager {
  static const String _boxName = 'app_cache';
  static const String _booksBoxName = 'books';
  static const String _progressBoxName = 'progress';

  final Box<String> _box;
  final Duration _defaultTimeout;
  late Box<BookModel> _booksBox;
  late Box<int> _progressBox;
  bool _isInitialized = false;

  @injectable
  CacheManager(
    @Named('app_cache') Box<String> box,
    Duration? defaultTimeout,
  )   : _box = box,
        _defaultTimeout = defaultTimeout ?? AppConfig.cacheTimeout {
    initialize();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _booksBox = Hive.box<BookModel>(_booksBoxName);
      _progressBox = Hive.box<int>(_progressBoxName);
      _isInitialized = true;
    } catch (e) {
      print('Error initializing CacheManager: $e');
      // Try to open boxes if they're not already open
      _booksBox = await Hive.openBox<BookModel>(_booksBoxName);
      _progressBox = await Hive.openBox<int>(_progressBoxName);
      _isInitialized = true;
    }
  }

  Future<void> setData(
    String key,
    dynamic data, {
    Duration? timeout,
  }) async {
    final cacheData = CacheData(
      data: data,
      timestamp: DateTime.now(),
      timeout: timeout ?? _defaultTimeout,
    );

    await _box.put(key, jsonEncode(cacheData.toJson()));
  }

  Future<T?> getData<T>(String key) async {
    final cachedString = _box.get(key);
    if (cachedString == null) return null;

    try {
      final cacheData = CacheData.fromJson(jsonDecode(cachedString));
      if (cacheData.isExpired) {
        await _box.delete(key);
        return null;
      }

      return cacheData.data as T;
    } catch (e) {
      await _box.delete(key);
      return null;
    }
  }

  Future<void> removeData(String key) async {
    await _box.delete(key);
  }

  Future<void> clearCache() async {
    await _box.clear();
  }

  Future<void> clear() async {
    await clearCache();
  }

  Future<void> removeExpiredData() async {
    final keys = _box.keys.toList();
    for (final key in keys) {
      final cachedString = _box.get(key);
      if (cachedString != null) {
        try {
          final cacheData = CacheData.fromJson(jsonDecode(cachedString));
          if (cacheData.isExpired) {
            await _box.delete(key);
          }
        } catch (e) {
          await _box.delete(key);
        }
      }
    }
  }

  Future<void> saveBook(BookModel book) async {
    if (!_isInitialized) await initialize();
    await _booksBox.put(book.id, book);
  }

  Future<List<BookModel>> getBooks() async {
    if (!_isInitialized) await initialize();
    return _booksBox.values.toList();
  }

  Future<BookModel?> getBook(String id) async {
    if (!_isInitialized) await initialize();
    return _booksBox.get(id);
  }

  Future<void> deleteBook(String id) async {
    if (!_isInitialized) await initialize();
    await _booksBox.delete(id);
    await _progressBox.delete(id);
  }

  Future<void> saveBookProgress(String id, int progress) async {
    if (!_isInitialized) await initialize();
    await _progressBox.put(id, progress);
  }

  Future<int> getBookProgress(String id) async {
    if (!_isInitialized) await initialize();
    return _progressBox.get(id) ?? 0;
  }

  Future<void> clearAll() async {
    if (!_isInitialized) await initialize();
    await _booksBox.clear();
    await _progressBox.clear();
  }

  Future<void> close() async {
    if (!_isInitialized) return;
    await _booksBox.close();
    await _progressBox.close();
  }
}

class CacheData {
  final dynamic data;
  final DateTime timestamp;
  final Duration timeout;

  CacheData({
    required this.data,
    required this.timestamp,
    required this.timeout,
  });

  bool get isExpired {
    return DateTime.now().difference(timestamp) > timeout;
  }

  Map<String, dynamic> toJson() {
    return {
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'timeout': timeout.inMilliseconds,
    };
  }

  factory CacheData.fromJson(Map<String, dynamic> json) {
    return CacheData(
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp']),
      timeout: Duration(milliseconds: json['timeout']),
    );
  }
}
