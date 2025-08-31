import 'dart:async';
import 'package:injectable/injectable.dart';
import 'package:collection/collection.dart';
import 'package:hive/hive.dart';
import '../storage/storage_manager.dart';
import '../../features/reader/data/models/book_model.dart';
import '../../features/reader/domain/repositories/book_repository.dart';

class LastReadInfo {
  final BookModel book;
  final int pageIndex;
  final DateTime savedAt;

  LastReadInfo({required this.book, required this.pageIndex, required this.savedAt});
}

@lazySingleton
class LastReadManager {
  static const String _keyBookId = 'last_read_book_id';
  static const String _keyPage = 'last_read_page';
  static const String _keyAt = 'last_read_at';
  static const String _keyRecentList = 'recent_reads';

  final StorageManager storageManager;
  final BookRepository bookRepository;

  final StreamController<LastReadInfo?> _updatesController = StreamController<LastReadInfo?>.broadcast();
  Stream<LastReadInfo?> get updates => _updatesController.stream;

  LastReadManager(this.storageManager, this.bookRepository);

  Future<void> saveLastRead({required String bookId, required int pageIndex}) async {
    await storageManager.save<String>(_keyBookId, bookId);
    await storageManager.save<int>(_keyPage, pageIndex);
    await storageManager.save<String>(_keyAt, DateTime.now().toIso8601String());
    // Flush for safety on iOS simulator
    await storageManager.saveContext();

    // Also update recent reads list
    try {
      await _upsertRecentRead(bookId: bookId, pageIndex: pageIndex);
    } catch (_) {}

    // Notify listeners
    try {
      final info = await getLastRead();
      _updatesController.add(info);
    } catch (_) {
      _updatesController.add(null);
    }
  }

  Future<LastReadInfo?> getLastRead() async {
    final bookId = await storageManager.fetch<String>(_keyBookId);
    final pageIndex = await storageManager.fetch<int>(_keyPage);
    final atIso = await storageManager.fetch<String>(_keyAt);
    if (bookId == null || pageIndex == null) return null;

    // Prefer local cache first
    try {
      final localEither = await bookRepository.getBook(bookId);
      final localBook = await localEither.fold((_) async => null, (m) async => m);
      if (localBook != null) {
        final savedAt = DateTime.tryParse(atIso ?? '') ?? DateTime.now();
        return LastReadInfo(book: localBook, pageIndex: pageIndex, savedAt: savedAt);
      }
    } catch (_) {}

    // Try fetch single from remote
    try {
      final remoteEither = await bookRepository.fetchBookDetails(bookId);
      final remoteBook = await remoteEither.fold((_) async => null, (m) async => m);
      if (remoteBook != null) {
        final savedAt = DateTime.tryParse(atIso ?? '') ?? DateTime.now();
        return LastReadInfo(book: remoteBook, pageIndex: pageIndex, savedAt: savedAt);
      }
    } catch (_) {}

    // As a fallback, try cached list if available
    try {
      final cachedEither = await bookRepository.getCachedBooks();
      return cachedEither.fold((_) => null, (models) {
        final model = models.firstWhereOrNull((m) => m.id == bookId);
        if (model == null) return null;
        final savedAt = DateTime.tryParse(atIso ?? '') ?? DateTime.now();
        return LastReadInfo(book: model, pageIndex: pageIndex, savedAt: savedAt);
      });
    } catch (_) {
      return null;
    }
  }

  Future<void> _upsertRecentRead({required String bookId, required int pageIndex}) async {
    final nowIso = DateTime.now().toIso8601String();
    final raw = await storageManager.fetch<List<dynamic>>(_keyRecentList) ?? <dynamic>[];
    final List<Map<String, dynamic>> items = raw
        .whereType<Map>()
        .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
        .map((e) => e as Map<String, dynamic>)
        .toList();

    // Remove existing of same bookId
    items.removeWhere((e) => (e['bookId']?.toString() ?? '') == bookId);
    // Insert on top
    items.insert(0, {
      'bookId': bookId,
      'pageIndex': pageIndex,
      'at': nowIso,
    });
    // Keep last 5
    final limited = items.take(5).toList();
    await storageManager.save<List<dynamic>>(_keyRecentList, limited);
  }

  Future<List<LastReadInfo>> getRecentReads({int limit = 5}) async {
    final raw = await storageManager.fetch<List<dynamic>>(_keyRecentList) ?? <dynamic>[];
    final List<Map<String, dynamic>> items = raw
        .whereType<Map>()
        .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
        .map((e) => e as Map<String, dynamic>)
        .toList();

    final List<LastReadInfo> result = [];
    for (final item in items) {
      final String bookId = item['bookId']?.toString() ?? '';
      final int pageIndex = (item['pageIndex'] is int)
          ? item['pageIndex'] as int
          : int.tryParse(item['pageIndex']?.toString() ?? '0') ?? 0;
      final DateTime savedAt = DateTime.tryParse(item['at']?.toString() ?? '') ?? DateTime.now();

      BookModel? model;
      try {
        final localEither = await bookRepository.getBook(bookId);
        model = await localEither.fold((_) async => null, (m) async => m);
      } catch (_) {}
      if (model == null) {
        try {
          final remoteEither = await bookRepository.fetchBookDetails(bookId);
          model = await remoteEither.fold((_) async => null, (m) async => m);
        } catch (_) {}
      }
      if (model != null) {
        result.add(LastReadInfo(book: model, pageIndex: pageIndex, savedAt: savedAt));
      }
      if (result.length >= limit) break;
    }
    return result;
  }
}

