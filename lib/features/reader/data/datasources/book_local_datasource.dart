import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/book.dart';

class BookLocalDataSource {
  final SharedPreferences prefs;
  final Box<Book> bookBox;

  BookLocalDataSource({
    required this.prefs,
    required this.bookBox,
  });

  Future<List<Book>> getBooks() async {
    return bookBox.values.toList();
  }

  Future<Book?> getBook(String id) async {
    return bookBox.get(id);
  }

  Future<void> saveBook(Book book) async {
    await bookBox.put(book.id, book);
  }

  Future<void> saveBooks(List<Book> books) async {
    for (final book in books) {
      await bookBox.put(book.id, book);
    }
  }

  Future<void> deleteBook(String id) async {
    await bookBox.delete(id);
  }

  Future<void> clearBooks() async {
    await bookBox.clear();
  }

  Future<List<String>> getFavoriteWords() async {
    final favorites = prefs.getStringList('favorite_words') ?? [];
    return favorites;
  }

  Future<void> addFavoriteWord(String word) async {
    final favorites = await getFavoriteWords();
    if (!favorites.contains(word)) {
      favorites.add(word);
      await prefs.setStringList('favorite_words', favorites);
    }
  }

  Future<void> removeFavoriteWord(String word) async {
    final favorites = await getFavoriteWords();
    favorites.remove(word);
    await prefs.setStringList('favorite_words', favorites);
  }

  Future<void> saveReadBooks(List<Book> readBooks) async {
    // Convert books to JSON strings for storage
    final bookJsonList = readBooks.map((book) => book.id).toList();
    await prefs.setStringList('read_books', bookJsonList);
  }

  Future<List<Book>> getReadBooks() async {
    final bookIds = prefs.getStringList('read_books') ?? [];
    final readBooks = <Book>[];

    for (final id in bookIds) {
      final book = await getBook(id);
      if (book != null) {
        readBooks.add(book);
      }
    }

    return readBooks;
  }
}
