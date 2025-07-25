import 'package:flutter/foundation.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

enum BookListState { initial, loading, loaded, error }

class BookListViewModel extends ChangeNotifier {
  final BookRepository _bookRepository;
  
  // State management
  BookListState _state = BookListState.initial;
  List<Book> _books = [];
  String? _errorMessage;
  DateTime? _lastRefreshed;
  bool _isRefreshing = false;

  BookListViewModel(this._bookRepository);

  // Getters
  BookListState get state => _state;
  List<Book> get books => _books;
  bool get isLoading => _state == BookListState.loading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastRefreshed => _lastRefreshed;
  bool get hasBooks => _books.isNotEmpty;
  bool get hasError => _errorMessage != null;

  // State setters
  void _setState(BookListState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    _setState(BookListState.error);
  }

  void _setSuccess(List<Book> books) {
    _books = books;
    _errorMessage = null;
    _lastRefreshed = DateTime.now();
    _setState(BookListState.loaded);
  }

  // Main methods
  Future<void> fetchBooks({bool forceRefresh = false}) async {
    try {
      // Don't reload if already loading
      if (_state == BookListState.loading && !forceRefresh) return;
      
      _setState(BookListState.loading);
      _isRefreshing = forceRefresh;

      final booksEither = await _bookRepository.getBooks();
      
      booksEither.fold(
        (failure) {
          _setError(failure.toString());
        },
        (bookModels) {
          final books = bookModels.map((model) => model.toEntity()).toList();
          _setSuccess(books);
        },
      );
    } catch (e) {
      _setError('Beklenmeyen bir hata oluştu: ${e.toString()}');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> refreshBooks() async {
    await fetchBooks(forceRefresh: true);
  }

  // Filtering
  List<Book> filterBooks(String searchText) {
    if (searchText.isEmpty) return _books;
    
    return _books.where((book) {
      final titleMatch = book.title.toLowerCase().contains(searchText.toLowerCase());
      final authorMatch = book.author?.toLowerCase().contains(searchText.toLowerCase()) ?? false;
      return titleMatch || authorMatch;
    }).toList();
  }

  List<Book> getBooksByCategory(String category) {
    if (category == 'All' || category.isEmpty) return _books;
    
    return _books.where((book) {
      // Burada kategori filtreleme mantığı eklenebilir
      // Şimdilik tüm kitapları döndürüyoruz
      return true;
    }).toList();
  }

  List<Book> getRecommendedBooks({int limit = 3}) {
    return _books.take(limit).toList();
  }

  List<Book> getTrendingBooks({int limit = 3}) {
    // Basit bir trending algoritması - son eklenen kitaplar
    return _books.take(limit).toList();
  }

  // Error handling
  void clearError() {
    _errorMessage = null;
    if (_state == BookListState.error) {
      _setState(BookListState.loaded);
    }
    notifyListeners();
  }

  // Debug method
  void debugBooks() {
    if (kDebugMode) {
      print('\n=== DEBUG INFO ===');
      print('State: $_state');
      print('Total books: ${_books.length}');
      print('Is Loading: $isLoading');
      print('Is Refreshing: $_isRefreshing');
      print('Has Error: $hasError');
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
        print('- Reading Time: ${book.estimatedReadingTimeInMinutes ?? "Unknown"}');
        print('- Level: ${book.textLevel ?? "Unknown"}');
      }
    }
  }

  @override
  void dispose() {
    // Cleanup if needed
    super.dispose();
  }
}
