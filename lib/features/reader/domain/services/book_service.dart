import 'package:daily_english/core/network/network_manager.dart';
import 'package:daily_english/core/cache/cache_manager.dart';
import 'package:daily_english/core/config/app_config.dart';
import 'package:daily_english/features/reader/domain/repositories/book_repository.dart';
import 'package:daily_english/features/reader/data/models/book_model.dart';

class BookService {
  final NetworkManager _networkManager;
  final CacheManager _cacheManager;
  final BookRepository _bookRepository;

  BookService({
    required NetworkManager networkManager,
    required CacheManager cacheManager,
    required BookRepository bookRepository,
  })  : _networkManager = networkManager,
        _cacheManager = cacheManager,
        _bookRepository = bookRepository {
    print(
        '📚 [BookService] Initialized with base URL: ${AppConfig.apiBaseUrl}');
  }

  // MARK: - Book Management

  Future<List<BookModel>> getBooks() async {
    final cacheKey = 'books';
    print('📚 [BookService] Getting books from cache or API...');

    try {
      // Check cache first
      final cachedBooks =
          await _cacheManager.getData<List<BookModel>>(cacheKey);
      if (cachedBooks != null && cachedBooks.isNotEmpty) {
        print('📚 [BookService] ✅ Found ${cachedBooks.length} books in cache');
        return cachedBooks;
      }

      print('📚 [BookService] Cache empty, fetching from API...');
      final result = await _bookRepository.getBooks();

      return result.fold(
        (failure) {
          print('📚 [BookService] ❌ Failed to fetch books: ${failure.message}');
          throw Exception(failure.message);
        },
        (books) async {
          print('📚 [BookService] ✅ Fetched ${books.length} books from API');
          await _cacheManager.setData(cacheKey, books);
          print('📚 [BookService] ✅ Cached ${books.length} books');
          return books;
        },
      );
    } catch (e) {
      print('📚 [BookService] ❌ Error in getBooks: $e');
      rethrow;
    }
  }

  Future<BookModel?> getBookById(String id) async {
    final cacheKey = 'book_$id';
    print('📚 [BookService] Getting book by ID: $id');

    try {
      // Check cache first
      final cachedBook = await _cacheManager.getData<BookModel>(cacheKey);
      if (cachedBook != null) {
        print('📚 [BookService] ✅ Found book in cache: ${cachedBook.title}');
        return cachedBook;
      }

      print('📚 [BookService] Cache miss, fetching from API...');
      final result = await _bookRepository.getBook(id);
      return result.fold(
        (failure) {
          print('📚 [BookService] ❌ Failed to get book: ${failure.message}');
          return null;
        },
        (book) async {
          if (book != null) {
            print('📚 [BookService] ✅ Fetched book from API: ${book.title}');
            await _cacheManager.setData(cacheKey, book);
            print('📚 [BookService] ✅ Cached book: ${book.title}');
          } else {
            print('📚 [BookService] ⚠️ Book not found: $id');
          }
          return book;
        },
      );
    } catch (e) {
      print('📚 [BookService] ❌ Error getting book by ID: $e');
      rethrow;
    }
  }

  Future<BookModel> downloadBook(String id) async {
    print('📚 [BookService] Downloading book: $id');
    try {
      final book = await _bookRepository.downloadBook(id);
      await _cacheManager.removeData('book_$id');
      print('📚 [BookService] ✅ Book downloaded: ${book.title}');
      return book;
    } catch (e) {
      print('📚 [BookService] ❌ Error downloading book: $e');
      rethrow;
    }
  }

  Future<List<BookModel>> getOfflineBooks() async {
    print('📚 [BookService] Getting offline books...');
    try {
      final books = await _bookRepository.getOfflineBooks();
      print('📚 [BookService] ✅ Found ${books.length} offline books');
      return books;
    } catch (e) {
      print('📚 [BookService] ❌ Error getting offline books: $e');
      rethrow;
    }
  }

  Future<void> deleteBook(String id) async {
    print('📚 [BookService] Deleting book: $id');
    try {
      final result = await _bookRepository.deleteBook(id);
      result.fold(
        (failure) {
          print('📚 [BookService] ❌ Failed to delete book: ${failure.message}');
          throw Exception(failure.message);
        },
        (_) async {
          await _cacheManager.removeData('book_$id');
          print('📚 [BookService] ✅ Book deleted and cache cleared: $id');
        },
      );
    } catch (e) {
      print('📚 [BookService] ❌ Error deleting book: $e');
      rethrow;
    }
  }

  // MARK: - Progress Management

  Future<void> updateBookProgress(String id, int currentPage) async {
    print('📚 [BookService] Updating book progress: $id -> page $currentPage');
    try {
      await _bookRepository.updateBookProgress(id, currentPage);
      await _cacheManager.removeData('book_$id');
      print(
          '📚 [BookService] ✅ Book progress updated: $id -> page $currentPage');
    } catch (e) {
      print('📚 [BookService] ❌ Error updating book progress: $e');
      rethrow;
    }
  }

  Future<int> getBookProgress(String id) async {
    print('📚 [BookService] Getting book progress: $id');
    try {
      final progress = await _bookRepository.getBookProgress(id);
      print('📚 [BookService] ✅ Book progress: $id -> page $progress');
      return progress;
    } catch (e) {
      print('📚 [BookService] ❌ Error getting book progress: $e');
      rethrow;
    }
  }

  // MARK: - Search and Recommendations

  Future<List<BookModel>> searchBooks(String query) async {
    print('📚 [BookService] Searching books: "$query"');
    try {
      final books = await _bookRepository.searchBooks(query);
      print(
          '📚 [BookService] ✅ Found ${books.length} books for query: "$query"');
      return books;
    } catch (e) {
      print('📚 [BookService] ❌ Error searching books: $e');
      rethrow;
    }
  }

  Future<List<BookModel>> getRecommendedBooks() async {
    print('📚 [BookService] Getting recommended books...');
    try {
      final books = await _bookRepository.getRecommendedBooks();
      print('📚 [BookService] ✅ Found ${books.length} recommended books');
      return books;
    } catch (e) {
      print('📚 [BookService] ❌ Error getting recommended books: $e');
      rethrow;
    }
  }

  // MARK: - Favorites Management

  Future<List<String>> getFavorites(String bookId) async {
    print('📚 [BookService] Getting favorites for book: $bookId');
    try {
      final favorites = await _bookRepository.getFavorites(bookId);
      print(
          '📚 [BookService] ✅ Found ${favorites.length} favorites for book: $bookId');
      return favorites;
    } catch (e) {
      print('📚 [BookService] ❌ Error getting favorites: $e');
      rethrow;
    }
  }

  Future<void> addToFavorites(String bookId, String word) async {
    print('📚 [BookService] Adding to favorites: book $bookId, word "$word"');
    try {
      final result = await _bookRepository.addToFavorites(bookId, word);
      result.fold(
        (failure) {
          print(
              '📚 [BookService] ❌ Failed to add to favorites: ${failure.message}');
          throw Exception(failure.message);
        },
        (_) {
          print(
              '📚 [BookService] ✅ Added to favorites: book $bookId, word "$word"');
        },
      );
    } catch (e) {
      print('📚 [BookService] ❌ Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String bookId, String word) async {
    print(
        '📚 [BookService] Removing from favorites: book $bookId, word "$word"');
    try {
      await _bookRepository.removeFromFavorites(bookId, word);
      print(
          '📚 [BookService] ✅ Removed from favorites: book $bookId, word "$word"');
    } catch (e) {
      print('📚 [BookService] ❌ Error removing from favorites: $e');
      rethrow;
    }
  }

  // MARK: - Cache Management

  Future<void> clearCache() async {
    print('📚 [BookService] Clearing cache...');
    try {
      await _bookRepository.clearCache();
      await _cacheManager.clearCache();
      print('📚 [BookService] ✅ Cache cleared');
    } catch (e) {
      print('📚 [BookService] ❌ Error clearing cache: $e');
      rethrow;
    }
  }

  Future<void> refreshBooks() async {
    print('📚 [BookService] Refreshing books...');
    try {
      await _cacheManager.clearCache();
      await _bookRepository.getBooks();
      print('📚 [BookService] ✅ Books refreshed');
    } catch (e) {
      print('📚 [BookService] ❌ Error refreshing books: $e');
      rethrow;
    }
  }

  // MARK: - Utility Methods

  Future<bool> isBookDownloaded(String id) async {
    print('📚 [BookService] Checking if book is downloaded: $id');
    try {
      return await _bookRepository.isBookDownloaded(id);
    } catch (e) {
      print('📚 [BookService] ❌ Error checking if book is downloaded: $e');
      return false;
    }
  }

  String getApiBaseUrl() {
    return AppConfig.apiBaseUrl;
  }

  String getApiVersion() {
    return AppConfig.apiVersion;
  }

  String getFullApiUrl() {
    final baseUrl = AppConfig.apiBaseUrl;
    final version = AppConfig.apiVersion;
    return version.isNotEmpty ? '$baseUrl/$version' : baseUrl;
  }
}
