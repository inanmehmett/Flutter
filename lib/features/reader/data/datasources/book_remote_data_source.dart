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
      // Correct backend endpoint
      final response = await _dio.get('/api/ApiReadingTexts');
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
            final book = BookModel.fromJson(json);
            books.add(book);
          } catch (e) {
            // skip invalid item
          }
        }
        
        return books;
      } else {
        return _getTestBooks();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        print('📚 [BookRemoteDataSource] 404 on /api/ApiReadingTexts, returning test data');
        return _getTestBooks();
      }
      print('📚 [BookRemoteDataSource] DioException: ${e.type} ${e.message}');
      return _getTestBooks();
    } catch (e) {
      print('📚 [BookRemoteDataSource] ❌ Error fetching books: $e');
      return _getTestBooks();
    }
  }

  @override
  Future<BookModel> fetchBookDetails(int id) async {
    print('📚 [BookRemoteDataSource] Fetching book details: $id');
    try {
      final response = await _dio.get('/api/ApiReadingTexts/$id');
      final data = response.data['data'] as Map<String, dynamic>;
      final book = BookModel.fromJson(data);
      print('📚 [BookRemoteDataSource] ✅ Fetched book details: ${book.title}');
      return book;
    } catch (e) {
      print('📚 [BookRemoteDataSource] ❌ Error fetching book details: $e');
      return _getTestBook(id.toString());
    }
  }

  @override
  Future<void> updateBook(BookModel book) async {
    print('📚 [BookRemoteDataSource] Updating book: ${book.title}');
    try {
      await _dio.put('/api/ApiReadingTexts/${book.id}', data: book.toJson());
      print('📚 [BookRemoteDataSource] ✅ Book updated: ${book.title}');
    } catch (e) {
      print('📚 [BookRemoteDataSource] ❌ Error updating book: $e');
    }
  }

  @override
  Future<void> deleteBook(String id) async {
    print('📚 [BookRemoteDataSource] Deleting book: $id');
    try {
      await _dio.delete('/api/ApiReadingTexts/$id');
      print('📚 [BookRemoteDataSource] ✅ Book deleted: $id');
    } catch (e) {
      print('📚 [BookRemoteDataSource] ❌ Error deleting book: $e');
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
        content: '''Once upon a time, there was a brave explorer who set out on an incredible journey. His name was Alexander, and he had always dreamed of discovering new lands and uncovering ancient mysteries.

The journey began on a bright spring morning. Alexander packed his bag with essential supplies: a map, a compass, some food, and his trusty journal. He said goodbye to his family and friends, promising to return with amazing stories.

As he walked through the dense forest, Alexander encountered many challenges. The path was overgrown with thorny bushes, and the weather was unpredictable. Sometimes it rained heavily, making the ground slippery and dangerous.

Despite these difficulties, Alexander remained determined. He knew that every great adventure required courage and perseverance. He remembered the words of his grandfather: "The greatest treasures are not made of gold, but of experiences and memories."

After several days of walking, Alexander discovered an ancient temple hidden deep in the forest. The temple was covered in mysterious symbols and seemed to glow with an otherworldly light. His heart raced with excitement as he approached the entrance.

Inside the temple, Alexander found walls covered with beautiful paintings that told the story of an ancient civilization. The paintings showed people living in harmony with nature, using advanced technology that seemed impossible for their time.

As he explored further, Alexander discovered a library filled with ancient books and scrolls. The knowledge contained within these pages could change the world forever. He carefully documented everything he found, knowing that this discovery would make history.

The journey back home was just as challenging as the journey there. Alexander had to navigate through dangerous terrain while protecting the precious artifacts and knowledge he had discovered. He faced storms, wild animals, and treacherous mountain passes.

Finally, after months of adventure, Alexander returned to his village. The people were amazed by his stories and the treasures he had brought back. His discovery of the ancient temple became the subject of countless books and documentaries.

Alexander's adventure taught him that the world is full of wonders waiting to be discovered. He realized that true courage is not the absence of fear, but the willingness to face challenges head-on. His journey inspired generations of explorers to follow in his footsteps.

The ancient temple he discovered became a protected historical site, and researchers from around the world came to study its mysteries. Alexander's name was forever remembered in the annals of exploration history.

Years later, when Alexander was old and gray, he would sit by the fire and tell his grandchildren about his great adventure. He would remind them that life itself is the greatest adventure of all, and that every day brings new opportunities for discovery and growth.

The lessons Alexander learned on his journey became the foundation of his philosophy: always be curious, never give up, and remember that the greatest adventures are those that change not just the world, but also yourself.''',
        translation: 'Bir zamanlar, inanılmaz bir yolculuğa çıkan cesur bir kaşif vardı...',
        summary: 'A thrilling adventure story about exploration and discovery.',
        textLevel: '1',
        textLanguage: 'en',
        translationLanguage: 'tr',
        estimatedReadingTimeInMinutes: 15,
        wordCount: 800,
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
        content: '''Learning a new language can be challenging, but with the right approach, it becomes an exciting journey of discovery. English, as one of the most widely spoken languages in the world, opens doors to countless opportunities.

The key to successful language learning lies in consistency and practice. Every day, even if it's just for fifteen minutes, dedicating time to study English will yield remarkable results over time. The human brain is incredibly adaptable, and with regular exposure to the language, it begins to recognize patterns and structures naturally.

One of the most effective methods for learning English is immersion. This doesn't necessarily mean moving to an English-speaking country, although that would be ideal. Immersion can be achieved through various means: watching English movies and TV shows, listening to English podcasts, reading English books and articles, and even thinking in English.

Vocabulary building is a crucial aspect of language learning. Instead of memorizing long lists of words, it's more effective to learn words in context. When you encounter a new word, try to understand how it's used in a sentence, what other words it's commonly paired with, and in what situations it would be appropriate to use it.

Grammar, while important, should not be the primary focus of language learning. Many people get discouraged by complex grammar rules and give up before they even start. The truth is that native speakers often don't follow all grammar rules perfectly, and communication is possible even with imperfect grammar.

Speaking practice is essential for developing fluency. Many learners can read and write English well but struggle with speaking. This is often due to fear of making mistakes or not being understood. The key is to practice speaking regularly, even if it's just talking to yourself or recording your voice.

Listening comprehension is another crucial skill that requires dedicated practice. English has many different accents and dialects, and understanding spoken English can be challenging at first. Start with slower, clearer speech and gradually work your way up to faster, more natural speech.

Reading is one of the best ways to improve your English skills. It exposes you to new vocabulary, different writing styles, and various topics. Start with simple texts and gradually increase the difficulty level. Don't worry about understanding every word; focus on getting the main idea and gradually build your vocabulary.

Writing practice helps you organize your thoughts and express yourself clearly in English. Start with simple sentences and gradually work your way up to more complex structures. Keep a journal in English, write emails, or participate in online forums to get regular writing practice.

Technology has made language learning more accessible than ever before. There are countless apps, websites, and online resources available for learning English. These tools can provide personalized learning experiences, immediate feedback, and opportunities to practice with native speakers.

The most important thing to remember is that learning a language is a marathon, not a sprint. It takes time, patience, and consistent effort. Celebrate your progress, no matter how small, and don't be discouraged by setbacks. Every mistake is an opportunity to learn and improve.

With dedication and the right approach, anyone can learn English effectively. The journey may be challenging at times, but the rewards are immeasurable. English proficiency opens up new career opportunities, allows you to connect with people from around the world, and provides access to a vast amount of knowledge and culture.''',
        translation: 'Yeni bir dil öğrenmek zor olabilir, ancak doğru yaklaşımla...',
        summary: 'A comprehensive guide to learning English effectively.',
        textLevel: '2',
        textLanguage: 'en',
        translationLanguage: 'tr',
        estimatedReadingTimeInMinutes: 20,
        wordCount: 1200,
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
        content: '''Hello! How are you today? I hope you're having a wonderful day. Let me share some common daily conversations that will help you improve your English speaking skills.

When you meet someone for the first time, you might say: "Hi, I'm [your name]. Nice to meet you!" The other person will usually respond with: "Nice to meet you too! I'm [their name]." This is a polite and friendly way to start a conversation.

If you're asking about someone's well-being, you can say: "How are you doing?" or "How have you been?" Common responses include: "I'm doing well, thank you!" or "I've been busy, but good." It's polite to ask the same question back: "And how about you?"

When you want to know what someone has been up to, you might ask: "What have you been up to lately?" or "What's new with you?" This shows interest in the other person's life and activities. People usually share recent events, work updates, or personal news.

If you're making plans, you might say: "Would you like to grab coffee sometime?" or "Are you free this weekend?" When someone invites you, you can respond with: "That sounds great!" or "I'd love to, but I'm busy that day." Always be honest about your availability.

When you're ordering food at a restaurant, you might say: "I'd like to order, please" or "Can I get the menu?" The server will usually ask: "What would you like to drink?" or "Are you ready to order?" You can respond with: "I'll have [your choice], please."

If you're shopping and need help, you can ask: "Excuse me, do you have this in a different size?" or "Can you help me find [item]?" Store employees are usually happy to help and might ask: "What size are you looking for?" or "What color would you prefer?"

When you're at work, common conversations include: "How was your weekend?" or "Did you finish the report?" Colleagues often discuss projects, deadlines, and work-related topics. It's important to maintain professional communication while being friendly.

If you're running late for a meeting, you might say: "I'm running a bit late, I'll be there in 10 minutes" or "Sorry for the delay, traffic was terrible." It's always good to apologize and give an estimated arrival time.

When you're saying goodbye, you can use phrases like: "It was great seeing you!" or "Let's catch up soon!" If you're leaving a party or gathering, you might say: "Thanks for having me!" or "I had a wonderful time!"

Remember that body language and tone of voice are just as important as the words you use. A smile and friendly tone can make even simple phrases sound warm and welcoming. Practice these conversations regularly, and you'll become more confident in your English speaking skills.

The key to improving your conversation skills is practice. Don't be afraid to make mistakes - they're a natural part of learning. Native speakers appreciate the effort and are usually patient with language learners. Keep practicing, and you'll see improvement over time.''',
        translation: 'Merhaba! Bugün nasılsın? Umarım harika bir gün geçiriyorsun...',
        summary: 'Essential daily conversations in English with Turkish translations.',
        textLevel: '1',
        textLanguage: 'en',
        translationLanguage: 'tr',
        estimatedReadingTimeInMinutes: 12,
        wordCount: 700,
        isActive: true,
        categoryId: 3,
        categoryName: 'Conversation',
        createdAt: now,
        updatedAt: now,
        imageUrl: 'https://picsum.photos/200/300?random=3',
        iconUrl: 'https://picsum.photos/100/150?random=3',
        slug: 'daily-conversations',
      ),
    ];
  }

  BookModel _getTestBook(String id) {
    final now = DateTime.now();
    return BookModel(
      id: id,
      title: 'Test Book $id',
      author: 'Test Author',
      content: 'This is a test book content for book $id.',
      translation: 'Bu, $id numaralı kitap için test içeriğidir.',
      summary: 'A test book for development purposes.',
      textLevel: '1',
      textLanguage: 'en',
      translationLanguage: 'tr',
      estimatedReadingTimeInMinutes: 5,
      wordCount: 100,
      isActive: true,
      categoryId: 1,
      categoryName: 'Test',
      createdAt: now,
      updatedAt: now,
      imageUrl: 'https://picsum.photos/200/300?random=$id',
      iconUrl: 'https://picsum.photos/100/150?random=$id',
      slug: 'test-book-$id',
    );
  }
}
