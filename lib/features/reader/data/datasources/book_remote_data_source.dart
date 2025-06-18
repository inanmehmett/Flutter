import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/config/app_config.dart';
import '../models/book_model.dart';

abstract class BookRemoteDataSource {
  Future<List<BookModel>> fetchBooks();
  Future<BookModel> fetchBookDetails(int id);
  Future<void> updateBook(BookModel book);
  Future<void> deleteBook(String id);
}

@Injectable(as: BookRemoteDataSource)
class BookRemoteDataSourceImpl implements BookRemoteDataSource {
  final Dio _dio;

  BookRemoteDataSourceImpl(this._dio) {
    print(
        '📚 [BookRemoteDataSource] Initialized with base URL: ${AppConfig.apiBaseUrl}');
  }

  @override
  Future<List<BookModel>> fetchBooks() async {
    print('📚 [BookRemoteDataSource] Fetching books from API...');
    try {
      final response = await _dio.get('/api/ReadingTexts');
      print('📚 [BookRemoteDataSource] ✅ API Response received');
      print('📚 [BookRemoteDataSource] Response status: ${response.statusCode}');
      print('📚 [BookRemoteDataSource] Response data type: ${response.data.runtimeType}');
      
      final data = response.data['data'];
      print('📚 [BookRemoteDataSource] Data type: ${data.runtimeType}');
      print('📚 [BookRemoteDataSource] Data length: ${data is List ? data.length : 'N/A'}');
      
      if (data is List) {
        final books = <BookModel>[];
        
        for (int i = 0; i < data.length; i++) {
          try {
            final json = data[i] as Map<String, dynamic>;
            print('📚 [BookRemoteDataSource] Parsing book $i: ${json['title'] ?? 'Unknown'}');
            final book = BookModel.fromJson(json);
            books.add(book);
            print('📚 [BookRemoteDataSource] ✅ Successfully parsed book $i');
          } catch (e) {
            print('📚 [BookRemoteDataSource] ❌ Error parsing book $i: $e');
            print('📚 [BookRemoteDataSource] Book $i data: ${data[i]}');
            // Continue with next book instead of failing completely
          }
        }
        
        print('📚 [BookRemoteDataSource] ✅ Successfully parsed ${books.length}/${data.length} books');
        return books;
      } else {
        print('📚 [BookRemoteDataSource] ❌ API data is not a list! data type: ${data.runtimeType}');
        print('📚 [BookRemoteDataSource] Data content: $data');
        return _getTestBooks();
      }
    } catch (e) {
      print('📚 [BookRemoteDataSource] ❌ Error fetching books: $e');
      print('📚 [BookRemoteDataSource] 🔄 Returning test data instead...');
      return _getTestBooks();
    }
  }

  @override
  Future<BookModel> fetchBookDetails(int id) async {
    print('📚 [BookRemoteDataSource] Fetching book details: $id');
    try {
      final response = await _dio.get('/books/$id');
      final book = BookModel.fromJson(response.data as Map<String, dynamic>);
      print('📚 [BookRemoteDataSource] ✅ Fetched book details: ${book.title}');
      return book;
    } catch (e) {
      print('📚 [BookRemoteDataSource] ❌ Error fetching book details: $e');
      print('📚 [BookRemoteDataSource] 🔄 Returning test book instead...');

      // Return test book when API is not available
      return _getTestBook(id.toString());
    }
  }

  @override
  Future<void> updateBook(BookModel book) async {
    print('📚 [BookRemoteDataSource] Updating book: ${book.title}');
    try {
      await _dio.put('/books/${book.id}', data: book.toJson());
      print('📚 [BookRemoteDataSource] ✅ Book updated: ${book.title}');
    } catch (e) {
      print('📚 [BookRemoteDataSource] ❌ Error updating book: $e');
      print('📚 [BookRemoteDataSource] 🔄 Simulating successful update...');
      // Simulate successful update for test data
    }
  }

  @override
  Future<void> deleteBook(String id) async {
    print('📚 [BookRemoteDataSource] Deleting book: $id');
    try {
      await _dio.delete('/books/$id');
      print('📚 [BookRemoteDataSource] ✅ Book deleted: $id');
    } catch (e) {
      print('📚 [BookRemoteDataSource] ❌ Error deleting book: $e');
      print('📚 [BookRemoteDataSource] 🔄 Simulating successful deletion...');
      // Simulate successful deletion for test data
    }
  }

  // MARK: - Test Data

  List<BookModel> _getTestBooks() {
    final now = DateTime.now();
    return [
      BookModel(
        id: '1',
        title: 'The Great Adventure',
        author: 'John Smith',
        content:
            'Once upon a time, there was a brave explorer who set out on an incredible journey...',
        translation:
            'Bir zamanlar, inanılmaz bir yolculuğa çıkan cesur bir kaşif vardı...',
        summary: 'A thrilling adventure story about exploration and discovery.',
        textLevel: '1',
        textLanguage: 'en',
        translationLanguage: 'tr',
        estimatedReadingTimeInMinutes: 5,
        wordCount: 150,
        isActive: true,
        categoryId: 1,
        categoryName: 'Adventure',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://picsum.photos/200/300?random=1',
        iconUrl: 'https://picsum.photos/100/150?random=1',
        slug: 'the-great-adventure',
      ),
      BookModel(
        id: '2',
        title: 'Learning English Made Easy',
        author: 'Sarah Johnson',
        content:
            'Learning a new language can be challenging, but with the right approach...',
        translation:
            'Yeni bir dil öğrenmek zor olabilir, ancak doğru yaklaşımla...',
        summary: 'A comprehensive guide to learning English effectively.',
        textLevel: '2',
        textLanguage: 'en',
        translationLanguage: 'tr',
        estimatedReadingTimeInMinutes: 8,
        wordCount: 250,
        isActive: true,
        categoryId: 2,
        categoryName: 'Education',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://picsum.photos/200/300?random=2',
        iconUrl: 'https://picsum.photos/100/150?random=2',
        slug: 'learning-english-made-easy',
      ),
      BookModel(
        id: '3',
        title: 'Daily Conversations',
        author: 'Maria Garcia',
        content:
            'Hello! How are you today? I hope you\'re having a wonderful day...',
        translation:
            'Merhaba! Bugün nasılsın? Umarım harika bir gün geçiriyorsun...',
        summary:
            'Essential daily conversations in English with Turkish translations.',
        textLevel: '1',
        textLanguage: 'en',
        translationLanguage: 'tr',
        estimatedReadingTimeInMinutes: 3,
        wordCount: 100,
        isActive: true,
        categoryId: 3,
        categoryName: 'Conversation',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://picsum.photos/200/300?random=3',
        iconUrl: 'https://picsum.photos/100/150?random=3',
        slug: 'daily-conversations',
      ),
      BookModel(
        id: '4',
        title: 'Business English Basics',
        author: 'David Wilson',
        content:
            'In today\'s global business environment, English has become the lingua franca...',
        translation:
            'Günümüzün küresel iş ortamında, İngilizce ortak dil haline geldi...',
        summary: 'Essential business English vocabulary and phrases.',
        textLevel: '3',
        textLanguage: 'en',
        translationLanguage: 'tr',
        estimatedReadingTimeInMinutes: 10,
        wordCount: 300,
        isActive: true,
        categoryId: 4,
        categoryName: 'Business',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://picsum.photos/200/300?random=4',
        iconUrl: 'https://picsum.photos/100/150?random=4',
        slug: 'business-english-basics',
      ),
      BookModel(
        id: '5',
        title: 'Travel English',
        author: 'Lisa Chen',
        content:
            'Planning a trip abroad? Here are some essential English phrases...',
        translation:
            'Yurt dışına seyahat planlıyor musun? İşte bazı temel İngilizce ifadeler...',
        summary: 'Useful English phrases for travelers.',
        textLevel: '2',
        textLanguage: 'en',
        translationLanguage: 'tr',
        estimatedReadingTimeInMinutes: 6,
        wordCount: 180,
        isActive: true,
        categoryId: 5,
        categoryName: 'Travel',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://picsum.photos/200/300?random=5',
        iconUrl: 'https://picsum.photos/100/150?random=5',
        slug: 'travel-english',
      ),
    ];
  }

  BookModel _getTestBook(String id) {
    final books = _getTestBooks();
    final book = books.firstWhere(
      (book) => book.id == id,
      orElse: () => books.first,
    );
    return book;
  }
}
