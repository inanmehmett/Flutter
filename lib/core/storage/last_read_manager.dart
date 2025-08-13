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

  final StorageManager storageManager;
  final BookRepository bookRepository;

  LastReadManager(this.storageManager, this.bookRepository);

  Future<void> saveLastRead({required String bookId, required int pageIndex}) async {
    await storageManager.save<String>(_keyBookId, bookId);
    await storageManager.save<int>(_keyPage, pageIndex);
    await storageManager.save<String>(_keyAt, DateTime.now().toIso8601String());
    // Flush for safety on iOS simulator
    await storageManager.saveContext();
  }

  Future<LastReadInfo?> getLastRead() async {
    final bookId = await storageManager.fetch<String>(_keyBookId);
    final pageIndex = await storageManager.fetch<int>(_keyPage);
    final atIso = await storageManager.fetch<String>(_keyAt);
    if (bookId == null || pageIndex == null) return null;

    final booksEither = await bookRepository.getBooks();
    return booksEither.fold((_) => null, (models) {
      final model = models.firstWhereOrNull((m) => m.id == bookId);
      if (model == null) return null;
      final savedAt = DateTime.tryParse(atIso ?? '') ?? DateTime.now();
      return LastReadInfo(book: model, pageIndex: pageIndex, savedAt: savedAt);
    });
  }
}

