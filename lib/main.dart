import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
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
  print('🚀 App starting...');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter binding initialized');

  try {
    // Initialize Hive
    print('📦 Initializing Hive...');
    await Hive.initFlutter();
    print('✅ Hive initialized');

    // Register Adapters
    print('🔧 Registering Hive adapters...');
    Hive.registerAdapter(BookModelAdapter());
    Hive.registerAdapter(SyncStateAdapter());
    print('✅ Hive adapters registered');

    // Open Boxes in correct order
    print('📁 Opening Hive boxes...');
    await Hive.openBox<String>('app_cache');
    await Hive.openBox<BookModel>('books');
    await Hive.openBox<String>('favorites');
    await Hive.openBox<int>('progress');
    await Hive.openBox<DateTime>('last_read');
    print('✅ All Hive boxes opened');

    // Initialize DI
    print('🔌 Initializing dependency injection...');
    await configureDependencies();
    print('✅ Dependency injection configured');

    print('🎯 Running app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print('❌ Error during initialization: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ Building MyApp...');
    return MultiProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(getIt<auth.AuthServiceProtocol>()),
        ),
        ChangeNotifierProvider<BookListViewModel>(
          create: (context) => BookListViewModel(getIt<BookRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Daily English',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFF9800)),
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
          '/profile': (context) => const Scaffold(
                body: Center(
                  child: Text('Profile Page - Coming Soon!',
                      style: TextStyle(fontSize: 24)),
                ),
              ),
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
