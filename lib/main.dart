import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'core/utils/logger.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'core/theme/theme_manager.dart';
import 'core/theme/app_design_system.dart';
import 'core/theme/app_colors.dart';
import 'features/user/presentation/pages/profile_page.dart';
import 'features/user/presentation/pages/profile_details_page.dart';
import 'features/user/presentation/pages/notifications_page.dart';
import 'features/user/presentation/pages/privacy_page.dart';
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
import 'features/reader/data/services/translation_service.dart';
import 'core/analytics/event_service.dart';
import 'features/reader/services/page_manager.dart';
import 'core/storage/last_read_manager.dart';
import 'features/user/presentation/pages/badges_page.dart';
import 'core/realtime/signalr_service.dart';
import 'core/cache/cache_manager.dart';
import 'core/widgets/toasts.dart';
import 'core/widgets/badge_celebration.dart';
import 'core/network/api_client.dart';
import 'core/network/network_manager.dart';
import 'features/game/pages/leaderboard_page.dart';
import 'features/quiz/presentation/pages/vocabulary_quiz_page.dart';
import 'features/quiz/presentation/cubit/vocabulary_quiz_cubit.dart';
import 'features/quiz/data/services/vocabulary_quiz_service.dart';
import 'features/vocabulary_notebook/presentation/pages/vocabulary_notebook_page.dart';
import 'features/vocabulary_notebook/presentation/bloc/vocabulary_bloc.dart';
import 'features/vocabulary_notebook/data/repositories/vocabulary_repository_impl.dart';
import 'features/vocab/presentation/pages/learning_list_page.dart';
import 'features/vocab/presentation/pages/flashcards_page.dart';
import 'features/vocab/presentation/pages/quiz_page.dart';

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
        BlocProvider<VocabularyBloc>(
          create: (context) => VocabularyBloc(repository: VocabularyRepositoryImpl()),
        ),
      ],
      child: MaterialApp(
        title: 'Daily English',
        debugShowCheckedModeBanner: false,
        theme: AppDesignSystem.lightTheme.copyWith(
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
              TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
            },
          ),
          snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
          ),
        ),
        darkTheme: AppDesignSystem.darkTheme,
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
          '/profile': (context) => const AppShell(initialIndex: 4),
          '/profile-details': (context) => const ProfileDetailsPage(),
          '/notifications': (context) => const NotificationsPage(),
          '/privacy': (context) => const PrivacyPage(),
          '/badges': (context) => BadgesPage(),
          '/leaderboard': (context) => const LeaderboardPage(),
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
                translationService: getIt<TranslationService>(),
                eventService: getIt<EventService>(),
                lastReadManager: getIt<LastReadManager>(),
                pageManager: getIt<PageManager>(),
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
          '/vocabulary': (context) => const AppShell(initialIndex: 2),
          '/learning-list': (context) => const LearningListPage(),
          '/study/flashcards': (context) => const FlashcardsPage(),
          '/study/quiz': (context) => const VocabQuizPage(),
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
  late final SignalRService _signalRService;
  bool _redirectedToLogin = false;

  final _pages = const [
    HomePage(showBottomNav: false),
    BookListPage(showBottomNav: false),
    VocabularyNotebookPage(),
    // Quiz page - will be replaced dynamically  
    Scaffold(body: Center(child: Text('Quiz Page - Coming Soon!', style: TextStyle(fontSize: 24)))),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    
    // Use SignalR service instead of polling
    _signalRService = getIt<SignalRService>();
    _signalRService.start();
    
    _signalRService.events.listen((evt) {
      if (!mounted) return;
      final ctx = context;
      // Invalidate profile-related caches and refresh profile on realtime updates
      void invalidateProfileCachesAndRefresh() {
        final cache = getIt<CacheManager>();
        cache.removeData('user/profile');
        cache.removeData('game/level');
        cache.removeData('game/streak');
        // Trigger profile refresh
        context.read<AuthBloc>().add(CheckAuthStatus());
      }
      switch (evt.type) {
        case RealtimeEventType.xpChanged:
          ToastOverlay.show(ctx, XpToast((evt.payload['deltaXP'] ?? 0) as int), channel: 'xp');
          invalidateProfileCachesAndRefresh();
          break;
        case RealtimeEventType.levelUp:
          ToastOverlay.show(ctx, LevelUpToast((evt.payload['levelLabel'] ?? '') as String), channel: 'level');
          invalidateProfileCachesAndRefresh();
          break;
        case RealtimeEventType.badgeEarned:
          // Full-screen celebration instead of simple toast
          final badgeName = (evt.payload['name'] ?? evt.payload['badgeName'] ?? 'Yeni Rozet') as String;
          final badgeDescription = (evt.payload['description'] ?? evt.payload['badgeDescription'] ?? 'Tebrikler! Yeni bir başarı kazandınız!') as String;
          final badgeImageUrl = (evt.payload['imageUrl'] ?? evt.payload['badgeImageUrl']) as String?;
          
          BadgeCelebration.show(
            ctx,
            name: badgeName,
            subtitle: badgeDescription,
            imageUrl: badgeImageUrl,
            earned: true,
          );
          
          // Also invalidate caches to refresh badge count
          invalidateProfileCachesAndRefresh();
          break;
        case RealtimeEventType.streakUpdated:
          ToastOverlay.show(ctx, StreakToast((evt.payload['currentStreak'] ?? 0) as int), channel: 'streak');
          invalidateProfileCachesAndRefresh();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated && !_redirectedToLogin) {
          // Auth yoksa login sayfasına yönlendir
          _redirectedToLogin = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/login');
          });
        }
      },
      child: Scaffold(
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
          onTap: (index) => _handleBottomNavTap(context, index),
        ),
      ),
    );
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
      case 1:
      case 4: // Home, Books, Profile
        setState(() => _currentIndex = index);
        break;
      case 2: // Vocabulary Notebook
        setState(() => _currentIndex = index);
        break;
      case 3: // Quiz
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => VocabularyQuizCubit(getIt<VocabularyQuizService>()),
              child: const VocabularyQuizPage(),
            ),
          ),
        );
        break;
    }
  }

  @override
  void dispose() {
    _signalRService.stop();
    super.dispose();
  }
}

class _GlobalBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;
  const _GlobalBottomNav({required this.currentIndex, this.onTap});

  static const List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home, label: 'Home', route: '/home'),
    _NavItem(icon: Icons.menu_book, label: 'Books', route: '/books'),
    _NavItem(icon: Icons.book_outlined, label: 'Kelime', route: '/vocabulary'),
    _NavItem(icon: Icons.quiz, label: 'Quiz', route: null), // Special handling
    _NavItem(icon: Icons.person, label: 'Profile', route: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
      items: _navItems.map((item) => BottomNavigationBarItem(
        icon: Icon(item.icon),
        label: item.label,
      )).toList(),
      onTap: (index) => _handleNavigation(context, index),
    );
  }

  void _handleNavigation(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    final item = _navItems[index];
    
    if (item.route == null) {
      // Special case for Quiz - navigate to vocabulary quiz
      _navigateToVocabularyQuiz(context);
    } else {
      Navigator.pushReplacementNamed(context, item.route!);
    }
  }

  void _navigateToVocabularyQuiz(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => VocabularyQuizCubit(getIt<VocabularyQuizService>()),
          child: const VocabularyQuizPage(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String? route;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
