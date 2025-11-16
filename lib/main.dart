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
import 'features/user/presentation/pages/badges_page_v2.dart';
import 'core/realtime/signalr_service.dart';
import 'core/cache/cache_manager.dart';
import 'core/widgets/toasts.dart';
import 'core/widgets/badge_celebration.dart';
import 'core/widgets/celebration_badge.dart';
import 'core/network/api_client.dart';
import 'core/network/network_manager.dart';
import 'features/game/services/game_service.dart';
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
          '/badges': (context) => const BadgesPageV2(),
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
  final Set<String> _shownBadgeNames = {}; // Track badges that have been shown

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
    
    // Use SignalR service instead of polling (offline-safe)
    _signalRService = getIt<SignalRService>();
    try {
      _signalRService.start();
    } catch (e) {
      print('⚠️ [AppShell] SignalR failed to start (offline mode): $e');
      // Continue without SignalR - app will work offline
    }
    
    _signalRService.events.listen((evt) {
      if (!mounted) return;
      final ctx = context;
      
      // Logout sırasında CheckAuthStatus tetiklenmesini önle
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthLoading || authState is AuthUnauthenticated) {
        return; // Logout işlemi devam ediyor veya zaten logout olmuş
      }
      
      // Invalidate profile-related caches (DO NOT trigger CheckAuthStatus to prevent infinite loops)
      void invalidateProfileCaches() {
        final cache = getIt<CacheManager>();
        cache.removeData('user/profile');
        cache.removeData('game/level');
        cache.removeData('game/streak');
        cache.removeData('game/badges'); // Invalidate badge cache to force refresh
        // DO NOT trigger CheckAuthStatus here - it causes infinite loops
        // Profile will be refreshed when user navigates to profile page or manually refreshes
      }
      
      // Check for newly earned badges (called when XP changes or level up)
      Future<void> checkForNewBadges(BuildContext context) async {
        if (!mounted) return;
        try {
          final gameService = GameService(getIt<ApiClient>(), getIt<CacheManager>());
          final badges = await gameService.getBadges(forceRefresh: true);
          
          final now = DateTime.now();
          
          // Find newly earned badges (isEarned = true and earned recently)
          for (final badgeData in badges) {
            if (badgeData is! Map<String, dynamic>) continue;
            final isEarned = (badgeData['isEarned'] ?? badgeData['IsEarned']) as bool? ?? false;
            if (!isEarned) continue;
            
            final badgeName = (badgeData['name'] ?? badgeData['Name'] ?? '').toString();
            if (badgeName.isEmpty) continue;
            
            // Check if this badge was already shown (to avoid duplicates)
            if (_shownBadgeNames.contains(badgeName)) continue;
            
            // Check if badge was earned recently (within last 2 minutes)
            final earnedAt = badgeData['earnedAt'] ?? badgeData['EarnedAt'];
            bool isRecentlyEarned = false;
            
            if (earnedAt != null) {
              try {
                DateTime? earnedDate;
                if (earnedAt is String) {
                  // Try parsing ISO 8601 format
                  earnedDate = DateTime.tryParse(earnedAt);
                  if (earnedDate == null) {
                    // Try parsing other formats
                    final parts = earnedAt.split('T');
                    if (parts.length == 2) {
                      final datePart = parts[0].split('-');
                      final timePart = parts[1].split(':');
                      if (datePart.length == 3 && timePart.length >= 2) {
                        earnedDate = DateTime(
                          int.parse(datePart[0]),
                          int.parse(datePart[1]),
                          int.parse(datePart[2]),
                          int.parse(timePart[0]),
                          int.parse(timePart[1]),
                        );
                      }
                    }
                  }
                } else if (earnedAt is Map) {
                  // Handle nested date objects
                  final year = earnedAt['year'] ?? earnedAt['Year'];
                  final month = earnedAt['month'] ?? earnedAt['Month'];
                  final day = earnedAt['day'] ?? earnedAt['Day'];
                  if (year != null && month != null && day != null) {
                    earnedDate = DateTime(
                      (year as num).toInt(),
                      (month as num).toInt(),
                      (day as num).toInt(),
                    );
                  }
                }
                
                if (earnedDate != null) {
                  final difference = now.difference(earnedDate);
                  // Show badge if earned within last 2 minutes
                  isRecentlyEarned = difference.inMinutes < 2;
                } else {
                  // If we can't parse the date, assume it's recent if badge is earned
                  // This handles cases where backend doesn't send earnedAt
                  isRecentlyEarned = true;
                }
              } catch (e) {
                print('⚠️ Error parsing earnedAt for badge $badgeName: $e');
                // If parsing fails, assume it's recent
                isRecentlyEarned = true;
              }
            } else {
              // If no earnedAt timestamp, check if it's a level badge (always show level badges)
              final category = (badgeData['category'] ?? badgeData['Category'] ?? '').toString().toLowerCase();
              isRecentlyEarned = category == 'level';
            }
            
            if (!isRecentlyEarned) continue;
            
            final badgeDescription = (badgeData['description'] ?? badgeData['Description'] ?? 'Tebrikler! Yeni bir başarı kazandınız!').toString();
            final badgeImageUrl = (badgeData['imageUrl'] ?? badgeData['ImageUrl'])?.toString();
            final badgeRarity = (badgeData['rarity'] ?? badgeData['Rarity'])?.toString();
            final badgeRarityColor = (badgeData['rarityColor'] ?? badgeData['RarityColor'] ?? badgeData['rarityColorHex'])?.toString();
            
            print('🏆 Newly earned badge detected: $badgeName');
            _shownBadgeNames.add(badgeName);
            
            // Show badge toast immediately
            if (mounted) {
              ToastOverlay.show(
                context,
                BadgeToast(
                  badgeName,
                  rarity: badgeRarity,
                  rarityColorHex: badgeRarityColor,
                  imageUrl: badgeImageUrl,
                  onTap: () {},
                ),
                duration: const Duration(seconds: 4),
                channel: 'badge',
              );
            }
            
            // Show badge celebration after a short delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                BadgeCelebration.show(
                  context,
                  name: badgeName,
                  subtitle: badgeDescription,
                  imageUrl: badgeImageUrl,
                  rarity: badgeRarity,
                  rarityColorHex: badgeRarityColor,
                  earned: true,
                );
              }
            });
            
            // Only show the first badge to avoid spam
            break;
          }
        } catch (e) {
          print('⚠️ Error checking badges: $e');
        }
      }
      switch (evt.type) {
        case RealtimeEventType.xpChanged:
          ToastOverlay.show(ctx, XpToast((evt.payload['deltaXP'] ?? 0) as int), channel: 'xp');
          invalidateProfileCaches();
          
          // Check for badges when XP changes (XP threshold badges)
          // Delay slightly to ensure backend has processed the badge award
          Future.delayed(const Duration(milliseconds: 300), () {
            checkForNewBadges(ctx);
          });
          break;
        case RealtimeEventType.levelUp:
          // Full-screen level-up celebration (purple themed, different from badge)
          final levelLabel = (evt.payload['levelLabel'] ?? evt.payload['newLevel'] ?? 'New Level') as String;
          final levelXp = evt.payload['totalXP'] != null ? (evt.payload['totalXP'] as num?)?.toInt() : null;
          
          // Check rewards array for badge information
          final rewards = evt.payload['rewards'];
          bool hasBadgeReward = false;
          if (rewards is List) {
            for (final reward in rewards) {
              if (reward is String && (reward.contains('rozet') || reward.contains('Rozet') || reward.contains('🏆'))) {
                hasBadgeReward = true;
                print('🏆 Level up rewards contain badge info: $reward');
                break;
              }
            }
          }
          
          LevelUpCelebration.show(
            ctx,
            levelLabel: levelLabel,
            xpEarned: levelXp,
          );
          
          // Also show a small toast for quick feedback
          ToastOverlay.show(ctx, LevelUpToast(levelLabel), channel: 'level');
          invalidateProfileCaches();
          
          // Check for newly earned badges immediately after level up
          // Backend may award badges during level up but doesn't send BadgeEarned event
          // If rewards array indicates badge, check immediately, otherwise delay slightly
          final delay = hasBadgeReward ? 200 : 300;
          Future.delayed(Duration(milliseconds: delay), () {
            checkForNewBadges(ctx);
          });
          break;
        case RealtimeEventType.badgeEarned:
          // Full-screen celebration + toast notification for better gamification
          final badgeName = (evt.payload['name'] ?? evt.payload['badgeName'] ?? 'Yeni Rozet') as String;
          final badgeDescription = (evt.payload['description'] ?? evt.payload['badgeDescription'] ?? 'Tebrikler! Yeni bir başarı kazandınız!') as String;
          final badgeImageUrl = (evt.payload['imageUrl'] ?? evt.payload['badgeImageUrl']) as String?;
          final badgeRarity = (evt.payload['rarity'] ?? evt.payload['Rarity']) as String?;
          final badgeRarityColor = (evt.payload['rarityColor'] ?? evt.payload['RarityColor']) as String?;
          
          print('🏆 Badge earned event received: $badgeName, description: $badgeDescription');
          print('🏆 Badge payload: ${evt.payload}');
          
          // Track this badge as shown to avoid duplicates
          if (badgeName.isNotEmpty) {
            _shownBadgeNames.add(badgeName);
          }
          
          // Show toast notification immediately (quick feedback)
          try {
            ToastOverlay.show(
              ctx,
              BadgeToast(
                badgeName,
                rarity: badgeRarity,
                rarityColorHex: badgeRarityColor,
                imageUrl: badgeImageUrl,
                onTap: () {
                  // Optional: Navigate to badge detail page
                },
              ),
              duration: const Duration(seconds: 4),
              channel: 'badge',
            );
            print('✅ Badge toast shown');
          } catch (e) {
            print('❌ Error showing badge toast: $e');
          }
          
          // Then show full-screen celebration (slight delay for better UX)
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted) {
              try {
                BadgeCelebration.show(
                  ctx,
                  name: badgeName,
                  subtitle: badgeDescription,
                  imageUrl: badgeImageUrl,
                  rarity: badgeRarity,
                  rarityColorHex: badgeRarityColor,
                  earned: true,
                );
                print('✅ Badge celebration shown');
              } catch (e) {
                print('❌ Error showing badge celebration: $e');
              }
            }
          });
          
          // Also invalidate caches to refresh badge count
          invalidateProfileCaches();
          break;
        case RealtimeEventType.streakUpdated:
          ToastOverlay.show(ctx, StreakToast((evt.payload['currentStreak'] ?? 0) as int), channel: 'streak');
          invalidateProfileCaches();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Login zorunluluğu kaldırıldı - direkt anasayfaya giriş
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
        onTap: (index) => _handleBottomNavTap(context, index),
      ),
    );
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
      case 1:
        setState(() => _currentIndex = index);
        break;
      case 4: // Profile - auth kontrolü yap
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          setState(() => _currentIndex = index);
        } else {
          // Login olmamış - login sayfasına yönlendir
          Navigator.of(context).pushReplacementNamed('/login');
        }
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
