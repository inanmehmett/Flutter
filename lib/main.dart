import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/utils/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'core/theme/theme_manager.dart';
import 'features/user/presentation/pages/profile_page.dart';
import 'features/user/presentation/pages/profile_page_sample.dart';
import 'features/user/presentation/pages/profile_details_page.dart';
import 'core/di/injection.dart';
import 'features/reader/data/models/book_model.dart';
import 'features/reader/domain/repositories/book_repository.dart';
import 'core/sync/sync_state.dart';
import 'features/onboarding/presentation/widgets/splash_screen.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/data/services/auth_service.dart' as auth;
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/registration_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/reader/presentation/viewmodels/book_list_view_model.dart';
import 'features/reader/presentation/pages/book_list_page.dart';
import 'features/reader/presentation/pages/book_preview_page.dart';
import 'features/reader/presentation/pages/advanced_reader_page.dart';
import 'features/reader/presentation/bloc/advanced_reader_bloc.dart';

void main() async {
  Logger.info('App starting...');
  WidgetsFlutterBinding.ensureInitialized();
  Logger.debug('Flutter binding initialized');

  try {
    // Initialize Hive
    Logger.debug('Initializing Hive...');
    await Hive.initFlutter();
    Logger.debug('Hive initialized');

    // Register Adapters
    Logger.debug('Registering Hive adapters...');
    Hive.registerAdapter(BookModelAdapter());
    Hive.registerAdapter(SyncStateAdapter());
    Logger.debug('Hive adapters registered');

    // Open Boxes in correct order
    Logger.debug('Opening Hive boxes...');
    await Hive.openBox<String>('app_cache');
    await Hive.openBox<BookModel>('books');
    await Hive.openBox<String>('favorites');
    await Hive.openBox<int>('progress');
    await Hive.openBox<DateTime>('last_read');
    Logger.debug('All Hive boxes opened');

    // Initialize ThemeManager
    Logger.debug('Initializing ThemeManager...');
    await ThemeManager().init();
    Logger.debug('ThemeManager initialized');

    // Initialize DI
    Logger.debug('Initializing dependency injection...');
    await configureDependencies();
    Logger.debug('Dependency injection configured');

    Logger.info('Running app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    Logger.error('Error during initialization', e, stackTrace);
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Logger.debug('Building MyApp...');
    return MultiProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(getIt<auth.AuthServiceProtocol>()),
        ),
        ChangeNotifierProvider<BookListViewModel>(
          create: (context) => BookListViewModel(getIt<BookRepository>()),
        ),
        ChangeNotifierProvider<ThemeManager>(
          create: (context) => ThemeManager(),
        ),
      ],
      child: MaterialApp(
        title: 'Daily English',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF3B82F6),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
          useMaterial3: true,
        ),
        home: Builder(
          builder: (context) => SplashScreen(onComplete: () {
            Navigator.of(context).pushReplacementNamed('/home');
          }),
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegistrationPage(),
          '/home': (context) => const HomePage(),
          '/books': (context) => const BookListPage(),
          '/profile': (context) => const ProfilePage(),
          '/profile-details': (context) => const ProfileDetailsPage(),
          '/profile-sample': (context) => const ProfileSamplePage(),
          '/quiz': (context) => const Scaffold(
                body: Center(
                  child: Text('Quiz Page - Coming Soon!',
                      style: TextStyle(fontSize: 24)),
                ),
              ),
          '/reader': (context) {
            final book = ModalRoute.of(context)!.settings.arguments;
            return BlocProvider(
              create: (_) => AdvancedReaderBloc(
                bookRepository: getIt<BookRepository>(),
                flutterTts: getIt<FlutterTts>(),
              ),
              child: AdvancedReaderPage(book: book as BookModel),
            );
          },
          '/games': (context) => const Scaffold(
                body: Center(
                  child: Text('Games Page - Coming Soon!',
                      style: TextStyle(fontSize: 24)),
                ),
              ),
          '/book-preview': (context) {
            final args = ModalRoute.of(context)!.settings.arguments;
            if (args is BookModel) {
              return BookPreviewPage(book: args);
            } else {
              return Scaffold(body: Center(child: Text('No book data!')));
            }
          },
        },
      ),
    );
  }
}
