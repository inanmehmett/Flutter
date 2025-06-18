import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../models/book_model.dart';

abstract class BookLocalDataSource {
  Future<List<BookModel>> getBooks();
  Future<BookModel?> getBook(String id);
  Future<void> cacheBooks(List<BookModel> books);
  Future<void> cacheBook(BookModel book);
  Future<void> deleteBook(String id);
  Future<void> clearBooks();
}

@Injectable(as: BookLocalDataSource)
class BookLocalDataSourceImpl implements BookLocalDataSource {
  final Box<BookModel> _bookBox;

  BookLocalDataSourceImpl(this._bookBox);

  @override
  Future<List<BookModel>> getBooks() async {
    return _bookBox.values.toList();
  }

  @override
  Future<BookModel?> getBook(String id) async {
    return _bookBox.get(id);
  }

  @override
  Future<void> cacheBooks(List<BookModel> books) async {
    for (final book in books) {
      await _bookBox.put(book.id, book);
    }
  }

  @override
  Future<void> cacheBook(BookModel book) async {
    await _bookBox.put(book.id, book);
  }

  @override
  Future<void> deleteBook(String id) async {
    await _bookBox.delete(id);
  }

  @override
  Future<void> clearBooks() async {
    await _bookBox.clear();
  }
}
