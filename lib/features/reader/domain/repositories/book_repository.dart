import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../data/models/book_model.dart';

abstract class BookRepository {
  // Core CRUD operations
  Future<Either<Failure, List<BookModel>>> getBooks();
  Future<Either<Failure, BookModel?>> getBook(String id);
  Future<Either<Failure, void>> updateBook(BookModel book);
  Future<Either<Failure, void>> deleteBook(String id);
  
  // Book details and fetching
  Future<Either<Failure, BookModel?>> fetchBookDetails(String bookId);
  Future<Either<Failure, List<BookModel>>> fetchBooks();
  Future<Either<Failure, List<BookModel>>> getCachedBooks();
  
  // Book management
  Future<BookModel> downloadBook(String id);
  Future<List<BookModel>> getOfflineBooks();
  Future<bool> isBookDownloaded(String id);
  
  // Progress tracking
  Future<void> updateBookProgress(String id, int progress);
  Future<int> getBookProgress(String id);
  
  // Search and filtering
  Future<List<BookModel>> searchBooks(String query);
  Future<List<BookModel>> getRecommendedBooks();
  
  // Favorites
  Future<Either<Failure, void>> addToFavorites(String bookId, String word);
  Future<void> removeFromFavorites(String bookId, String word);
  Future<List<String>> getFavorites(String bookId);
  
  // Cache management
  Future<void> clearCache();
}
