import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/repositories/book_repository.dart';
import '../models/book_model.dart';
import '../../../../core/network/network_manager.dart';
import '../../../../core/cache/cache_manager.dart';
import '../datasources/book_local_data_source.dart';
import '../datasources/book_remote_data_source.dart';

@Injectable(as: BookRepository)
class BookRepositoryImpl implements BookRepository {
  final NetworkManager networkManager;
  final CacheManager cacheManager;
  final Dio dio;
  final Box<BookModel> bookBox;
  final Box<String> favoritesBox;
  final Box<int> progressBox;
  final Box<DateTime> lastReadBox;
  final BookRemoteDataSource remoteDataSource;
  final BookLocalDataSource localDataSource;

  @injectable
  BookRepositoryImpl({
    required this.networkManager,
    required this.cacheManager,
    required this.dio,
    required this.bookBox,
    @Named('favorites') required this.favoritesBox,
    required this.progressBox,
    required this.lastReadBox,
    required this.remoteDataSource,
    required this.localDataSource,
  }) {
    print(
        '📚 [BookRepositoryImpl] Initialized with base URL: ${AppConfig.apiBaseUrl}');
    print(
        '📚 [BookRepositoryImpl] NetworkManager: ${networkManager.runtimeType}');
    print(
        '📚 [BookRepositoryImpl] RemoteDataSource: ${remoteDataSource.runtimeType}');
  }

  @override
  Future<Either<Failure, List<BookModel>>> getBooks() async {
    print('📚 [BookRepositoryImpl] Getting books...');
    try {
      final books = await remoteDataSource.fetchBooks();
      await localDataSource.cacheBooks(books);
      print(
          '📚 [BookRepositoryImpl] ✅ Successfully fetched and cached ${books.length} books');
      return Right(books);
    } catch (e) {
      print('📚 [BookRepositoryImpl] ❌ Error getting books: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<BookModel>>> fetchBooks() async {
    print('📚 [BookRepositoryImpl] Fetching books from remote...');
    try {
      final books = await remoteDataSource.fetchBooks();
      await localDataSource.cacheBooks(books);
      print(
          '📚 [BookRepositoryImpl] ✅ Successfully fetched and cached ${books.length} books');
      return Right(books);
    } catch (e) {
      print('📚 [BookRepositoryImpl] ❌ Error fetching books: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, List<BookModel>>> getCachedBooks() async {
    try {
      final books = await localDataSource.getBooks();
      return Right(books);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, BookModel?>> getBook(String id) async {
    try {
      final book = await localDataSource.getBook(id);
      return Right(book);
    } catch (e) {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, BookModel?>> fetchBookDetails(String id) async {
    try {
      final response = await networkManager.get('/books/$id');
      final book = BookModel.fromJson(response.data);
      return Right(book);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateBook(BookModel book) async {
    try {
      await remoteDataSource.updateBook(book);
      await localDataSource.cacheBook(book);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteBook(String id) async {
    try {
      await remoteDataSource.deleteBook(id);
      await localDataSource.deleteBook(id);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<BookModel?> getBookById(String id) async {
    try {
      final response = await networkManager.get('/books/$id');
      return BookModel.fromJson(response.data);
    } catch (e) {
      print('Error getting book by id: $e');
      return null;
    }
  }

  @override
  Future<BookModel> downloadBook(String id) async {
    try {
      final response = await networkManager.get('/books/$id/download');
      final book = BookModel.fromJson(response.data);
      await cacheManager.saveBook(book);
      return book;
    } catch (e) {
      print('Error downloading book: $e');
      rethrow;
    }
  }

  @override
  Future<List<BookModel>> getOfflineBooks() async {
    try {
      return await cacheManager.getBooks();
    } catch (e) {
      print('Error getting offline books: $e');
      return [];
    }
  }

  @override
  Future<void> updateBookProgress(String id, int progress) async {
    try {
      await networkManager
          .put('/books/$id/progress', data: {'progress': progress});
      await cacheManager.saveBookProgress(id, progress);
    } catch (e) {
      print('Error updating book progress: $e');
      rethrow;
    }
  }

  @override
  Future<int> getBookProgress(String id) async {
    try {
      final response = await networkManager.get('/books/$id/progress');
      return response.data['progress'] as int;
    } catch (e) {
      print('Error getting book progress: $e');
      return 0;
    }
  }

  @override
  Future<Either<Failure, List<String>>> getBookPages(String id) async {
    try {
      final book = await getBookById(id);
      if (book == null) {
        return Left(CacheFailure());
      }
      final pages = book.content.split('\n');
      return Right(pages);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<List<String>> getFavorites(String bookId) async {
    try {
      final response = await networkManager.get('/books/$bookId/favorites');
      return List<String>.from(response.data);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> updateLastReadPage(String bookId, int page) async {
    await updateBookProgress(bookId, page);
  }

  @override
  Future<bool> isBookDownloaded(String id) async {
    final offlineBook = await cacheManager.getData('offline_book_$id');
    return offlineBook != null;
  }

  @override
  Future<List<BookModel>> getDownloadedBooks() async {
    try {
      return await cacheManager.getBooks();
    } catch (e) {
      print('Error getting downloaded books: $e');
      return [];
    }
  }

  @override
  Future<List<BookModel>> searchBooks(String query) async {
    try {
      final response = await networkManager
          .get('/books/search', queryParameters: {'q': query});
      return (response.data as List)
          .map((json) => BookModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching books: $e');
      return [];
    }
  }

  @override
  Future<List<BookModel>> getRecommendedBooks() async {
    try {
      final response = await networkManager.get('/books/recommended');
      return (response.data as List)
          .map((json) => BookModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting recommended books: $e');
      return [];
    }
  }

  @override
  Future<List<BookModel>> getBooksByGenre(String genre) async {
    try {
      final response = await networkManager.get('/books/genre/$genre');
      return (response.data as List)
          .map((json) => BookModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting books by genre: $e');
      return [];
    }
  }

  @override
  Future<List<BookModel>> getBooksByAuthor(String author) async {
    try {
      final response = await networkManager.get('/books/author/$author');
      return (response.data as List)
          .map((json) => BookModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting books by author: $e');
      return [];
    }
  }

  @override
  Future<void> rateBook(String id, double rating) async {
    try {
      await networkManager.put('/books/$id/rate', data: {'rating': rating});
    } catch (e) {
      print('Error rating book: $e');
      rethrow;
    }
  }

  @override
  Future<void> addReview(String id, String review) async {
    try {
      await networkManager.post('/books/$id/reviews', data: {'review': review});
    } catch (e) {
      print('Error adding review: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getReviews(String id) async {
    try {
      final response = await networkManager.get('/books/$id/reviews');
      return List<String>.from(response.data);
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }

  @override
  Future<void> shareBook(String id) async {
    try {
      await networkManager.post('/books/$id/share');
    } catch (e) {
      print('Error sharing book: $e');
      rethrow;
    }
  }

  @override
  Future<void> reportBook(String id, String reason) async {
    try {
      await networkManager.post('/books/$id/report', data: {'reason': reason});
    } catch (e) {
      print('Error reporting book: $e');
      rethrow;
    }
  }

  @override
  Future<void> syncBookProgress(String id) async {
    try {
      final progress = await getBookProgress(id);
      await updateBookProgress(id, progress);
    } catch (e) {
      print('Error syncing book progress: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearBookProgress(String id) async {
    try {
      await networkManager.delete('/books/$id/progress');
      await cacheManager.removeData('book_progress_$id');
    } catch (e) {
      print('Error clearing book progress: $e');
      rethrow;
    }
  }

  @override
  Future<void> exportBook(String id, String format) async {
    try {
      final response = await networkManager
          .get('/books/$id/export', queryParameters: {'format': format});
      await cacheManager.setData('exported_book_$id', response.data);
    } catch (e) {
      print('Error exporting book: $e');
      rethrow;
    }
  }

  @override
  Future<void> importBook(String path) async {
    try {
      final file = await cacheManager.getData(path);
      if (file != null) {
        final book = BookModel.fromJson(file as Map<String, dynamic>);
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error importing book: $e');
      rethrow;
    }
  }

  @override
  Future<void> backupBooks() async {
    try {
      final books = await cacheManager.getBooks();
      await cacheManager.setData('backup_books', books);
    } catch (e) {
      print('Error backing up books: $e');
      rethrow;
    }
  }

  @override
  Future<void> restoreBooks() async {
    try {
      final books =
          await cacheManager.getData('backup_books') as List<BookModel>;
      for (final book in books) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error restoring books: $e');
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await cacheManager.clearCache();
    } catch (e) {
      print('Error clearing cache: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateBookMetadata(
      String id, Map<String, dynamic> metadata) async {
    try {
      await networkManager.put('/books/$id/metadata', data: metadata);
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book metadata: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getBookMetadata(String id) async {
    try {
      final response = await networkManager.get('/books/$id/metadata');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Error getting book metadata: $e');
      return {};
    }
  }

  @override
  Future<void> updateBookCover(String id, String coverUrl) async {
    try {
      await networkManager
          .put('/books/$id/cover', data: {'coverUrl': coverUrl});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book cover: $e');
      rethrow;
    }
  }

  @override
  Future<String> getBookCover(String id) async {
    try {
      final response = await networkManager.get('/books/$id/cover');
      return response.data['coverUrl'] as String;
    } catch (e) {
      print('Error getting book cover: $e');
      return '';
    }
  }

  @override
  Future<void> updateBookDescription(String id, String description) async {
    try {
      await networkManager
          .put('/books/$id/description', data: {'description': description});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book description: $e');
      rethrow;
    }
  }

  @override
  Future<String> getBookDescription(String id) async {
    try {
      final response = await networkManager.get('/books/$id/description');
      return response.data['description'] as String;
    } catch (e) {
      print('Error getting book description: $e');
      return '';
    }
  }

  @override
  Future<void> updateBookTitle(String id, String title) async {
    try {
      await networkManager.put('/books/$id/title', data: {'title': title});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book title: $e');
      rethrow;
    }
  }

  @override
  Future<String> getBookTitle(String id) async {
    try {
      final response = await networkManager.get('/books/$id/title');
      return response.data['title'] as String;
    } catch (e) {
      print('Error getting book title: $e');
      return '';
    }
  }

  @override
  Future<void> updateBookAuthor(String id, String author) async {
    try {
      await networkManager.put('/books/$id/author', data: {'author': author});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book author: $e');
      rethrow;
    }
  }

  @override
  Future<String> getBookAuthor(String id) async {
    try {
      final response = await networkManager.get('/books/$id/author');
      return response.data['author'] as String;
    } catch (e) {
      print('Error getting book author: $e');
      return '';
    }
  }

  @override
  Future<void> updateBookGenres(String id, List<String> genres) async {
    try {
      await networkManager.put('/books/$id/genres', data: {'genres': genres});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book genres: $e');
      rethrow;
    }
  }

  @override
  Future<List<String>> getBookGenres(String id) async {
    try {
      final response = await networkManager.get('/books/$id/genres');
      return List<String>.from(response.data['genres']);
    } catch (e) {
      print('Error getting book genres: $e');
      return [];
    }
  }

  @override
  Future<void> updateBookRating(String id, double rating) async {
    try {
      await networkManager.put('/books/$id/rating', data: {'rating': rating});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book rating: $e');
      rethrow;
    }
  }

  @override
  Future<double> getBookRating(String id) async {
    try {
      final response = await networkManager.get('/books/$id/rating');
      return response.data['rating'] as double;
    } catch (e) {
      print('Error getting book rating: $e');
      return 0.0;
    }
  }

  @override
  Future<void> updateBookPageCount(String id, int pageCount) async {
    try {
      await networkManager
          .put('/books/$id/pageCount', data: {'pageCount': pageCount});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book page count: $e');
      rethrow;
    }
  }

  @override
  Future<int> getBookPageCount(String id) async {
    try {
      final response = await networkManager.get('/books/$id/pageCount');
      return response.data['pageCount'] as int;
    } catch (e) {
      print('Error getting book page count: $e');
      return 0;
    }
  }

  @override
  Future<void> updateBookPublishedDate(String id, DateTime date) async {
    try {
      await networkManager.put('/books/$id/publishedDate',
          data: {'date': date.toIso8601String()});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book published date: $e');
      rethrow;
    }
  }

  @override
  Future<DateTime> getBookPublishedDate(String id) async {
    try {
      final response = await networkManager.get('/books/$id/publishedDate');
      return DateTime.parse(response.data['date'] as String);
    } catch (e) {
      print('Error getting book published date: $e');
      return DateTime.now();
    }
  }

  @override
  Future<void> updateBookLastReadDate(String id, DateTime date) async {
    try {
      await networkManager.put('/books/$id/lastReadDate',
          data: {'date': date.toIso8601String()});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book last read date: $e');
      rethrow;
    }
  }

  @override
  Future<DateTime> getBookLastReadDate(String id) async {
    try {
      final response = await networkManager.get('/books/$id/lastReadDate');
      return DateTime.parse(response.data['date'] as String);
    } catch (e) {
      print('Error getting book last read date: $e');
      return DateTime.now();
    }
  }

  @override
  Future<void> updateBookLastReadPage(String id, int page) async {
    try {
      await networkManager.put('/books/$id/lastReadPage', data: {'page': page});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book last read page: $e');
      rethrow;
    }
  }

  @override
  Future<int> getBookLastReadPage(String id) async {
    try {
      final response = await networkManager.get('/books/$id/lastReadPage');
      return response.data['page'] as int;
    } catch (e) {
      print('Error getting book last read page: $e');
      return 0;
    }
  }

  @override
  Future<void> updateBookIsDownloaded(String id, bool isDownloaded) async {
    try {
      await networkManager
          .put('/books/$id/isDownloaded', data: {'isDownloaded': isDownloaded});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book is downloaded: $e');
      rethrow;
    }
  }

  @override
  Future<bool> getBookIsDownloaded(String id) async {
    try {
      final response = await networkManager.get('/books/$id/isDownloaded');
      return response.data['isDownloaded'] as bool;
    } catch (e) {
      print('Error getting book is downloaded: $e');
      return false;
    }
  }

  @override
  Future<void> updateBookCoverUrl(String id, String url) async {
    try {
      await networkManager.put('/books/$id/coverUrl', data: {'url': url});
      final book = await getBookById(id);
      if (book != null) {
        await cacheManager.saveBook(book);
      }
    } catch (e) {
      print('Error updating book cover URL: $e');
      rethrow;
    }
  }

  @override
  Future<String> getBookCoverUrl(String id) async {
    try {
      final response = await networkManager.get('/books/$id/coverUrl');
      return response.data['url'] as String;
    } catch (e) {
      print('Error getting book cover URL: $e');
      return '';
    }
  }

  @override
  Future<Either<Failure, void>> addToFavorites(
      String bookId, String word) async {
    try {
      await networkManager
          .post('/books/$bookId/favorites', data: {'word': word});
      return const Right(null);
    } catch (e) {
      print('Error adding to favorites: $e');
      return Left(ServerFailure());
    }
  }

  @override
  Future<void> removeFromFavorites(String bookId, String word) async {
    try {
      await networkManager
          .delete('/books/$bookId/favorites/$word');
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  @override
  Future<Either<Failure, BookModel>> getBookDetails(int id) async {
    try {
      final response = await networkManager.get('/books/$id/details');
      final book = BookModel.fromJson(response.data);
      return Right(book);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
