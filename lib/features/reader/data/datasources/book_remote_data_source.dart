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
      BookModel(
        id: '4',
        title: 'Business English Basics',
        author: 'David Wilson',
        content: '''In today's global business environment, English has become the lingua franca of international commerce. Whether you're attending meetings, writing emails, or networking with colleagues from around the world, strong English skills are essential for professional success.

Business communication requires a specific set of vocabulary and phrases that differ from everyday conversation. Understanding these terms and knowing how to use them appropriately can make a significant difference in your professional relationships and career advancement.

When introducing yourself in a business setting, you might say: "Hello, I'm [name] from [company]. I work in [department]." This provides essential information about your role and organization. You might also add: "I've been with the company for [time period]" to give context about your experience.

During meetings, common phrases include: "Let's get started" or "Shall we begin?" When you want to contribute to the discussion, you can say: "I'd like to add something" or "If I may interject." If you need clarification, ask: "Could you please clarify that point?" or "I'm not sure I understand. Could you explain further?"

When presenting ideas, you might use phrases like: "I propose that we..." or "My recommendation would be..." If you're expressing agreement, say: "I completely agree" or "That's an excellent point." For disagreement, use polite phrases like: "I see it differently" or "I have a different perspective on this."

Email communication is a crucial part of modern business. Start emails with appropriate greetings: "Dear [name]" for formal communication or "Hi [name]" for more casual situations. When closing emails, use phrases like: "Best regards," "Sincerely," or "Looking forward to hearing from you."

When scheduling meetings, you might say: "Would you be available for a meeting on [date] at [time]?" or "I'd like to schedule a call to discuss [topic]." Always confirm the details: "Just to confirm, we're meeting on [date] at [time] at [location]."

If you need to reschedule, be polite and give advance notice: "I apologize, but I need to reschedule our meeting. Would [alternative time] work for you?" Always provide alternative options and apologize for the inconvenience.

When discussing projects, use phrases like: "We're currently working on..." or "The project is progressing well." If there are challenges, be honest but professional: "We're facing some challenges with..." or "We need to address some issues."

Performance reviews and feedback are important aspects of business communication. When giving feedback, be constructive: "I appreciate your work on..." or "One area for improvement might be..." When receiving feedback, respond positively: "Thank you for the feedback" or "I'll work on improving that."

Networking is essential for career growth. At business events, you might ask: "What do you do?" or "What industry are you in?" Show interest in others: "That sounds fascinating. Could you tell me more about..." or "How did you get into that field?"

Remember that business English is not just about vocabulary; it's also about cultural awareness and professional etiquette. Understanding the cultural context of your business partners and clients can help you communicate more effectively and build stronger relationships.

The key to mastering business English is practice and exposure. Read business articles, watch business news, and participate in professional discussions. The more you immerse yourself in business English, the more natural it will become.''',
        translation: 'Günümüzün küresel iş ortamında, İngilizce ortak dil haline geldi...',
        summary: 'Essential business English vocabulary and phrases.',
        textLevel: '3',
        textLanguage: 'en',
        translationLanguage: 'tr',
        estimatedReadingTimeInMinutes: 18,
        wordCount: 1000,
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
        content: '''Planning a trip abroad? Here are some essential English phrases that will help you navigate airports, hotels, restaurants, and tourist attractions with confidence. Whether you're traveling for business or pleasure, these expressions will make your journey smoother and more enjoyable.

At the airport, you'll need to check in for your flight. You might say: "I'd like to check in for my flight to [destination]" or "I have a reservation under the name [your name]." The agent might ask: "Do you have any luggage to check?" or "Would you like a window or aisle seat?"

When going through security, you might hear: "Please remove your shoes and belt" or "Place your electronics in a separate bin." Follow the instructions and ask if you're unsure: "Is this okay?" or "Do I need to remove this?"

On the plane, flight attendants might ask: "Would you like something to drink?" or "What would you like for dinner?" You can respond with: "I'll have [your choice], please" or "Just water, thank you." If you need assistance, say: "Could you help me, please?"

When you arrive at your destination, you'll need to go through customs. The officer might ask: "What's the purpose of your visit?" or "How long will you be staying?" Answer clearly: "I'm here for vacation" or "I'm on a business trip for [duration]."

At the hotel, you'll check in at the front desk. Say: "I have a reservation under [name]" or "I'd like to check in, please." The clerk might ask: "Do you have a credit card for incidentals?" or "Would you like a room with a view?"

If you need help with your room, call the front desk: "My room key isn't working" or "Could you send someone to fix the air conditioning?" For housekeeping, you might say: "Could you please clean my room?" or "I need fresh towels."

When dining at restaurants, you'll need to make reservations: "I'd like to make a reservation for [number] people at [time]" or "Do you have any tables available for tonight?" The host might ask: "Smoking or non-smoking?" or "Would you like to sit inside or outside?"

Ordering food, you can say: "I'd like to start with [appetizer]" or "What do you recommend?" The server might ask: "How would you like your steak cooked?" or "Would you like fries or a salad with that?" Don't forget to ask: "Could I have the bill, please?"

When shopping, you might ask: "Do you have this in a different size?" or "How much does this cost?" If you're looking for something specific: "Where can I find [item]?" or "Do you sell [product]?" For payment: "Do you accept credit cards?" or "Can I pay with cash?"

At tourist attractions, you might ask: "What time does the museum close?" or "How much is the entrance fee?" For directions: "How do I get to [location]?" or "Is it within walking distance?" If you're lost: "Could you help me find [place]?" or "I'm looking for [landmark]."

Using public transportation, you might ask: "How do I get to [destination]?" or "Which bus goes to [place]?" For tickets: "I'd like a ticket to [destination]" or "How much is a day pass?" On the bus or train: "Is this the right stop for [place]?" or "Could you let me know when we reach [stop]?"

Remember that body language and a friendly smile can help bridge language barriers. Most people appreciate the effort to communicate in their language, even if you make mistakes. Don't be afraid to ask for help or clarification when needed.

The key to successful travel communication is preparation and practice. Learn the essential phrases before your trip, and don't hesitate to use them. Your confidence will grow with each successful interaction, making your travel experience more enjoyable and memorable.''',
        translation: 'Yurt dışına seyahat planlıyor musun? İşte bazı temel İngilizce ifadeler...',
        summary: 'Useful English phrases for travelers.',
        textLevel: '2',
        textLanguage: 'en',
        translationLanguage: 'tr',
        estimatedReadingTimeInMinutes: 16,
        wordCount: 900,
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
