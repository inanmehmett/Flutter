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
import 'features/user/presentation/pages/badges_page.dart';
import 'core/realtime/realtime_service.dart';
import 'core/widgets/toasts.dart';
import 'core/network/api_client.dart';
import 'core/network/network_manager.dart';

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
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Colors.black87,
            unselectedItemColor: Colors.black54,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
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
          '/home': (context) => const AppShell(initialIndex: 0),
          '/books': (context) => const AppShell(initialIndex: 1),
          '/profile': (context) => const AppShell(initialIndex: 3),
          '/profile-details': (context) => const ProfileDetailsPage(),
          '/badges': (context) => BadgesPage(),
          '/profile-sample': (context) => const ProfileSamplePage(),
          '/quiz': (context) => Scaffold(
                body: Center(
                  child: Text('Quiz Page - Coming Soon!', style: TextStyle(fontSize: 24)),
                ),
                bottomNavigationBar: const _GlobalBottomNav(currentIndex: 2),
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
          '/games': (context) => Scaffold(
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

class AppShell extends StatefulWidget {
  final int initialIndex;
  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  late final RealtimeService _realtime;

  final _pages = const [
    HomePage(showBottomNav: false),
    BookListPage(showBottomNav: false),
    // Placeholder Quiz page
    Scaffold(body: Center(child: Text('Quiz Page - Coming Soon!', style: TextStyle(fontSize: 24)))),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _realtime = RealtimeService(getIt<ApiClient>(), getIt<NetworkManager>())..start();
    _realtime.events.listen((evt) {
      if (!mounted) return;
      final ctx = context;
      switch (evt.type) {
        case RealtimeEventType.xpChanged:
          ToastOverlay.show(ctx, XpToast((evt.payload['deltaXP'] ?? 0) as int));
          break;
        case RealtimeEventType.levelUp:
          ToastOverlay.show(ctx, LevelUpToast((evt.payload['levelLabel'] ?? '') as String));
          break;
        case RealtimeEventType.badgeEarned:
          ToastOverlay.show(ctx, BadgeToast((evt.payload['name'] ?? '') as String));
          break;
        case RealtimeEventType.streakUpdated:
          ToastOverlay.show(ctx, StreakToast((evt.payload['currentStreak'] ?? 0) as int));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.fastOutSlowIn,
        switchOutCurve: Curves.fastOutSlowIn,
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _GlobalBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _GlobalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  const _GlobalBottomNav({required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Books'),
        BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        if (onTap != null) {
          onTap!(index);
          return;
        }
        // Fallback route navigation
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/books');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/quiz');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
    );
  }
}
