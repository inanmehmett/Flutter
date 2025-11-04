import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../cache/cache_manager.dart';
import '../network/network_manager.dart';
import '../storage/secure_storage_service.dart';
import '../../features/reader/data/models/book_model.dart';
import '../../features/reader/data/repositories/book_repository_impl.dart';
import '../../features/reader/domain/repositories/book_repository.dart';
import '../../features/reader/data/datasources/book_local_data_source.dart';
import '../../features/reader/data/datasources/book_remote_data_source.dart';
import '../../features/reader/services/page_manager.dart';
import '../../features/reader/services/page_cache.dart';
import '../../features/reader/services/pagination_worker.dart';
import '../../features/auth/data/services/auth_service.dart';
import '../../features/reader/data/services/translation_service.dart';
import '../../features/reader/data/services/reading_quiz_service.dart';
import '../../features/game/services/game_service.dart';
import '../../features/quiz/data/services/vocabulary_quiz_service.dart';
import '../../features/quiz/data/services/quiz_service.dart';
import '../../features/quiz/domain/repositories/quiz_repository.dart';
import '../../features/quiz/data/repositories/quiz_repository_impl.dart';
import '../network/api_client.dart';
import '../analytics/event_service.dart';
import 'injection.config.dart';
import '../storage/last_read_manager.dart';
import '../storage/storage_manager.dart';
import '../realtime/signalr_service.dart';
import '../../features/vocab/data/models/user_word.dart';
import '../../features/vocab/data/datasources/user_word_local_data_source.dart';
import '../../features/vocab/domain/services/vocab_learning_service.dart';
import '../../features/vocabulary_notebook/data/repositories/vocabulary_repository_impl.dart';
import '../../features/vocabulary_notebook/domain/services/tts_service.dart';
import '../../features/vocabulary_notebook/domain/services/quiz_answer_generator.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Ensure all Hive boxes are open
  if (!Hive.isBoxOpen('app_cache')) {
    await Hive.openBox<String>('app_cache');
  }
  if (!Hive.isBoxOpen('books')) {
    await Hive.openBox<BookModel>('books');
  }
  if (!Hive.isBoxOpen('favorites')) {
    await Hive.openBox<String>('favorites');
  }
  if (!Hive.isBoxOpen('progress')) {
    await Hive.openBox<int>('progress');
  }
  if (!Hive.isBoxOpen('last_read')) {
    await Hive.openBox<DateTime>('last_read');
  }
  if (!Hive.isBoxOpen('user_preferences')) {
    await Hive.openBox<String>('user_preferences');
  }
  if (!Hive.isAdapterRegistered(41)) {
    Hive.registerAdapter(UserWordModelAdapter());
  }
  if (!Hive.isBoxOpen(UserWordLocalDataSource.boxName)) {
    await Hive.openBox<UserWordModel>(UserWordLocalDataSource.boxName);
  }

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BookModelAdapter());
  }

  // Register Duration for CacheManager
  getIt.registerLazySingleton<Duration>(() => const Duration(hours: 24));

  // Initialize auto-generated dependencies
  await getIt.init();

  // Register AuthServiceProtocol with AuthService implementation
  getIt.registerLazySingleton<AuthServiceProtocol>(
    () => getIt<AuthService>(),
  );

  // Register LastReadManager (manual to avoid codegen dependency)
  if (!getIt.isRegistered<LastReadManager>()) {
    getIt.registerLazySingleton<LastReadManager>(
      () => LastReadManager(
        getIt<StorageManager>(),
        getIt<BookRepository>(),
      ),
    );
  }

  // Register FlutterTts
  getIt.registerLazySingleton<FlutterTts>(() => FlutterTts());

  // Register TranslationService (only if not already registered by injectable)
  if (!getIt.isRegistered<TranslationService>()) {
    getIt.registerLazySingleton<TranslationService>(() => TranslationService(getIt<NetworkManager>()));
  }

  // Register ReadingQuizService
  if (!getIt.isRegistered<ReadingQuizService>()) {
    getIt.registerLazySingleton<ReadingQuizService>(
      () => ReadingQuizService(getIt<ApiClient>(), getIt<SecureStorageService>()),
    );
  }

  // Register GameService
  if (!getIt.isRegistered<GameService>()) {
    getIt.registerLazySingleton<GameService>(() => GameService(getIt<ApiClient>(), getIt<CacheManager>()));
  }
  
  // Register VocabularyQuizService
  if (!getIt.isRegistered<VocabularyQuizService>()) {
    getIt.registerLazySingleton<VocabularyQuizService>(() => VocabularyQuizService(getIt<Dio>()));
  }
  
  // Register EventService
  if (!getIt.isRegistered<EventService>()) {
    getIt.registerLazySingleton<EventService>(() => EventService(getIt<ApiClient>()));
  }
  
  // Register Pagination Services
  getIt.registerLazySingleton<SimplePageCache>(
    () => SimplePageCache(capacity: 15, maxMemoryMB: 25),
  );
  
  getIt.registerLazySingleton<PageManager>(
    () => PageManager(),
  );

  // Vocab Local + Service
  if (!getIt.isRegistered<UserWordLocalDataSource>()) {
    final box = Hive.box<UserWordModel>(UserWordLocalDataSource.boxName);
    getIt.registerLazySingleton<UserWordLocalDataSource>(() => UserWordLocalDataSource(box));
  }
  if (!getIt.isRegistered<VocabLearningService>()) {
    getIt.registerLazySingleton<VocabLearningService>(() => VocabLearningService(getIt<UserWordLocalDataSource>()));
  }

  // Register VocabularyRepository for Vocabulary Notebook feature
  if (!getIt.isRegistered<VocabularyRepositoryImpl>()) {
    getIt.registerLazySingleton<VocabularyRepositoryImpl>(() => VocabularyRepositoryImpl());
  }

  // Register TTS Service
  if (!getIt.isRegistered<TtsService>()) {
    final flutterTts = getIt<FlutterTts>();
    getIt.registerLazySingleton<TtsService>(() => TtsService(flutterTts));
  }

  // Register Quiz Answer Generator
  if (!getIt.isRegistered<QuizAnswerGenerator>()) {
    final repository = getIt<VocabularyRepositoryImpl>();
    getIt.registerLazySingleton<QuizAnswerGenerator>(
      () => QuizAnswerGenerator(repository),
    );
  }

  // Register QuizService and QuizRepository for backend quiz
  if (!getIt.isRegistered<QuizService>()) {
    getIt.registerLazySingleton<QuizService>(() => QuizService(getIt<Dio>()));
  }
  if (!getIt.isRegistered<QuizRepository>()) {
    getIt.registerLazySingleton<QuizRepository>(
      () => QuizRepositoryImpl(getIt<QuizService>()),
    );
  }
}
