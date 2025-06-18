import 'package:flutter/foundation.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

class BookListViewModel extends ChangeNotifier {
  final BookRepository _bookRepository;
  List<Book> _books = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastRefreshed;

  BookListViewModel(this._bookRepository);

  List<Book> get books => _books;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastRefreshed => _lastRefreshed;

  Future<void> fetchBooks() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final booksEither = await _bookRepository.getBooks();
      booksEither.fold(
        (failure) {
          _errorMessage = failure.toString();
        },
        (bookModels) {
          _books = bookModels.map((model) => model.toEntity()).toList();
          _lastRefreshed = DateTime.now();
        },
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Book> filterBooks(String searchText) {
    if (searchText.isEmpty) return _books;
    return _books.where((book) {
      return book.title.toLowerCase().contains(searchText.toLowerCase()) ||
          (book.author.toLowerCase().contains(searchText.toLowerCase()) ??
              false);
    }).toList();
  }

  // Debug method
  void debugBooks() {
    if (kDebugMode) {
      print('\n=== DEBUG INFO ===');
      print('Total books: ${_books.length}');
      print('Is Loading: $_isLoading');
      print('Error: ${_errorMessage ?? "None"}');
      print('Last Refreshed: ${_lastRefreshed?.toString() ?? "Never"}');

      // Print first 3 books
      for (var i = 0; i < _books.length && i < 3; i++) {
        final book = _books[i];
        print('\nBook ${i + 1}:');
        print('- ID: ${book.id}');
        print('- Title: ${book.title}');
        print('- Author: ${book.author ?? "Unknown"}');
        print('- Active: ${book.isActive ?? true}');
      }
    }
  }
}
