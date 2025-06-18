import 'package:dio/dio.dart';
import '../../domain/entities/book.dart';

abstract class BookRemoteDataSource {
  Future<List<Book>> fetchBooks();
  Future<Book> fetchBookDetails(int id);
  Future<void> updateBook(Book book);
  Future<void> deleteBook(String id);
}

class BookRemoteDataSourceImpl implements BookRemoteDataSource {
  final Dio dio;

  BookRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<Book>> fetchBooks() async {
    try {
      final response = await dio.get('/api/ReadingTexts');
      final List<dynamic> data = response.data;
      return data.map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch books: $e');
    }
  }

  @override
  Future<Book> fetchBookDetails(int id) async {
    try {
      final response = await dio.get('/books/$id');
      return Book.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to fetch book details: $e');
    }
  }

  @override
  Future<void> updateBook(Book book) async {
    try {
      await dio.put('/books/${book.id}', data: book.toJson());
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  @override
  Future<void> deleteBook(String id) async {
    try {
      await dio.delete('/books/$id');
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }
}
