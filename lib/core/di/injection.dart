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
import '../../features/reader/domain/services/book_service.dart';
import '../../features/reader/domain/services/auth_service.dart' as reader_auth;
import '../../features/reader/domain/services/user_service.dart';
import '../../features/reader/domain/services/achievement_manager.dart';
import '../../features/reader/data/datasources/book_local_data_source.dart';
import '../../features/reader/data/datasources/book_remote_data_source.dart';
import '../../features/reader/services/page_manager.dart';
import '../../features/reader/services/page_cache.dart';
import '../../features/reader/services/pagination_worker.dart';
import 'injection.config.dart';

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

  // Register Hive adapters
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BookModelAdapter());
  }

  // Register Duration for CacheManager
  getIt.registerLazySingleton<Duration>(() => const Duration(hours: 24));

  // Register base URL from environment or config
  // getIt.registerLazySingleton<String>(
  //   () => const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:5173'),
  //   instanceName: 'baseUrl',
  // );

  // Initialize auto-generated dependencies
  await getIt.init();

  // Register BookService
  getIt.registerLazySingleton<BookService>(
    () => BookService(
      networkManager: getIt<NetworkManager>(),
      cacheManager: getIt<CacheManager>(),
      bookRepository: getIt<BookRepository>(),
    ),
  );

  // Register FlutterTts
  getIt.registerLazySingleton<FlutterTts>(() => FlutterTts());
  
  // Register Pagination Services
  getIt.registerLazySingleton<SimplePageCache>(
    () => SimplePageCache(capacity: 15, maxMemoryMB: 25),
  );
  
  getIt.registerLazySingleton<PageManager>(
    () => PageManager(),
  );
}
