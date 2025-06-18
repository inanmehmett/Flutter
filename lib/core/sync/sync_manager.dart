import 'package:daily_english/core/storage/storage_manager.dart';
import 'package:daily_english/features/reader/data/models/book_model.dart';
import 'package:daily_english/features/reader/domain/repositories/book_repository.dart';
import 'package:daily_english/core/sync/sync_state.dart';
import 'package:injectable/injectable.dart';

@singleton
class SyncManager {
  final StorageManager _storageManager;
  final BookRepository _bookRepository;
  bool _isSyncing = false;

  @injectable
  SyncManager(this._storageManager, this._bookRepository);

  Future<void> sync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // Get all local books
      final localBooks =
          await _storageManager.fetch<List<BookModel>>('books') ?? [];

      // Get all remote books
      final remoteBooks = await _bookRepository.getBooks();
      final remoteBooksList = remoteBooks.fold(
        (failure) => <BookModel>[],
        (books) => books.map((book) => book).toList(),
      );

      // Update local books with remote data
      for (final remoteBook in remoteBooksList) {
        final localBook = localBooks.firstWhere(
          (book) => book.id == remoteBook.id,
          orElse: () => remoteBook,
        );

        if (localBook.syncState == SyncState.synced) {
          await _storageManager.save('books', localBook);
        }
      }

      // Upload local changes
      for (final localBook in localBooks) {
        if (localBook.syncState == SyncState.updated) {
          await _bookRepository.updateBook(localBook);
          localBook.syncState = SyncState.synced;
          await _storageManager.save('books', localBook);
        } else if (localBook.syncState == SyncState.deleted) {
          await _bookRepository.deleteBook(localBook.id);
          await _storageManager.delete('books');
        }
      }

      await _storageManager.saveContext();
    } catch (e) {
      print('Sync error: $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> syncBook(BookModel book) async {
    try {
      if (book.syncState == SyncState.updated) {
        await _bookRepository.updateBook(book);
        book.syncState = SyncState.synced;
        await _storageManager.save('books', book);
      } else if (book.syncState == SyncState.deleted) {
        await _bookRepository.deleteBook(book.id);
        await _storageManager.delete('books');
      }
    } catch (e) {
      print('Book sync error: $e');
    }
  }

  Future<void> markBookForSync(BookModel book) async {
    book.syncState = SyncState.updated;
    await _storageManager.save('books', book);
  }

  Future<void> markBookForDeletion(BookModel book) async {
    book.syncState = SyncState.deleted;
    await _storageManager.save('books', book);
  }
}
