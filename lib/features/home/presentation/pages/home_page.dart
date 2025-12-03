import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../reader/presentation/viewmodels/book_list_view_model.dart';
import '../../../reader/domain/entities/book.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/xp_state_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../home/presentation/widgets/profile_header.dart';
import '../../../home/presentation/widgets/home_header.dart';
import '../../../home/presentation/widgets/daily_progress_card.dart';
import '../../../home/presentation/widgets/vocabulary_notebook_card.dart';
import '../../../home/presentation/widgets/quiz_advertisement_card.dart';
import '../../../home/presentation/widgets/continue_reading_card.dart';
import '../../../home/utils/greeting_helper.dart';
import '../../../game/widgets/leaderboard_preview.dart';
import '../../../game/services/game_service.dart';
import '../../../reader/presentation/widgets/unified_book_card.dart';

class HomePage extends StatefulWidget {
  final bool showBottomNav;
  const HomePage({super.key, this.showBottomNav = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int? _cachedDailyXP;
  int? _cachedStreakDays;
  bool _isLoadingStreak = false;
  bool _isLoadingDailyXP = false;
  
  late XPStateService _xpStateService;
  StreamSubscription<int>? _dailyXPSubscription;
  StreamSubscription<int>? _streakSubscription;
  
  // Design system spacing
  static const double _smallSpacing = AppSpacing.spacing3;
  static const double _mediumSpacing = AppSpacing.spacing4;
  static const double _largeSpacing = AppSpacing.spacing5;
  static const double _extraLargeSpacing = AppSpacing.spacing6;
  static const double _sectionSpacing = AppSpacing.spacing8;
  
  // Design system colors
  static const Color _textPrimary = AppColors.textPrimary;
  static const Color _textSecondary = AppColors.textSecondary;
  static const Color _backgroundWhite = AppColors.surface;
  static const Color _borderColor = AppColors.border;
  
  @override
  void initState() {
    super.initState();
    _xpStateService = getIt<XPStateService>();
    
    // Add lifecycle observer to reload cache when app resumes
    WidgetsBinding.instance.addObserver(this);
    
    // Load cached XP data immediately (fast UI)
    _loadCachedXPData();
    
    // Listen to XP updates from SignalR
    _dailyXPSubscription = _xpStateService.dailyXPStream.listen((dailyXP) {
      print('🏠 [HomePage] Received daily XP update: $dailyXP');
      if (mounted) {
        print('🏠 [HomePage] Updating UI with new daily XP: $dailyXP');
        setState(() {
          _cachedDailyXP = dailyXP;
        });
      } else {
        print('⚠️ [HomePage] Widget not mounted, skipping UI update');
      }
    });
    
    _streakSubscription = _xpStateService.streakStream.listen((streak) {
      if (mounted) {
        setState(() {
          _cachedStreakDays = streak;
        });
      }
    });
    
    // Load books when page initializes
    Future.microtask(() =>
        Provider.of<BookListViewModel>(context, listen: false).fetchBooks());
    
    // Check auth status when page initializes
    Future.microtask(() =>
        context.read<AuthBloc>().add(CheckAuthStatus()));

    // Prefetch all data to prevent multiple API calls (background refresh)
    _prefetchAllData();
  }
  
  Future<void> _loadCachedXPData() async {
    // Load from cache immediately for fast UI
    final cachedDailyXP = await _xpStateService.getDailyXP();
    final cachedStreak = await _xpStateService.getStreak();
    
    if (mounted) {
      setState(() {
        _cachedDailyXP = cachedDailyXP > 0 ? cachedDailyXP : null;
        _cachedStreakDays = cachedStreak > 0 ? cachedStreak : null;
      });
    }
  }

  Future<void> _prefetchAllData() async {
    try {
      // Fetch streak data and daily XP once
      await Future.wait([
        _fetchStreakDays(),
        _fetchDailyXP(),
      ]);
      
      // Prefetch other data that widgets might need
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated) {
        // Prefetch gamification data
        final gameService = getIt<GameService>();
        await gameService.getProfileSummary();
      }
    } catch (e) {
      print('Error prefetching data: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Reload XP cache when app returns to foreground or page becomes visible
    if (state == AppLifecycleState.resumed) {
      print('🔄 [HomePage] App resumed, reloading XP cache...');
      _loadCachedXPData();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dailyXPSubscription?.cancel();
    _streakSubscription?.cancel();
    super.dispose();
  }

  Future<int?> _fetchStreakDays() async {
    if (_isLoadingStreak) return _cachedStreakDays;
    
    try {
      _isLoadingStreak = true;
      final service = getIt<GameService>();
      final summary = await service.getProfileSummary();
      
      // Update local cache
      await _xpStateService.updateStreak(summary.currentStreak);
      
      if (mounted) {
        setState(() {
          _cachedStreakDays = summary.currentStreak;
        });
      }
      return _cachedStreakDays;
    } catch (e) {
      print('Error fetching streak days: $e');
      return _cachedStreakDays;
    } finally {
      _isLoadingStreak = false;
    }
  }

  Future<int?> _fetchDailyXP() async {
    if (_isLoadingDailyXP) return _cachedDailyXP;
    
    try {
      _isLoadingDailyXP = true;
      final service = getIt<GameService>();
      final dailyXP = await service.getDailyXP();
      
      // Update local cache
      await _xpStateService.updateDailyXP(dailyXP);
      
      if (mounted) {
        setState(() {
          _cachedDailyXP = dailyXP;
        });
      }
      return _cachedDailyXP;
    } catch (e) {
      print('Error fetching daily XP: $e');
      return _cachedDailyXP ?? 0;
    } finally {
      _isLoadingDailyXP = false;
    }
  }


  Widget _buildSectionTitle(String title, [String? subtitle]) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final fontSize = screenWidth < 400 ? 18.0 : 20.0;
        final subtitleFontSize = screenWidth < 400 ? 14.0 : 16.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.title2.copyWith(
                fontSize: fontSize,
                color: _textPrimary,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTypography.subhead.copyWith(
                  fontSize: subtitleFontSize,
                  color: _textSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }


  Widget _buildLoadingSection() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: _backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'Yükleniyor...',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'İlk adımını at, İngilizce yolculuğuna başla! 🚀',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Navigate to all books or level test
              Navigator.pushNamed(context, '/books');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Kitapları Keşfet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            ),
          ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            // Auth durumuna göre profil bilgilerini al
            UserProfile? userProfile;
            
            if (authState is AuthAuthenticated) {
              userProfile = authState.user;
            } else if (authState is AuthChecking || authState is AuthLoading) {
              // Loading durumunda placeholder göster
              userProfile = UserProfile(
                id: 'loading',
                userName: 'Yükleniyor...',
                email: '',
                profileImageUrl: null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isActive: false,
                level: 0,
                experiencePoints: 0,
                totalReadBooks: 0,
                totalQuizScore: 0,
              );
            } else {
              // Kullanıcı login olmamışsa default göster
              userProfile = UserProfile(
                id: 'guest',
                userName: 'Misafir',
                email: 'Giriş yapın',
                profileImageUrl: null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                isActive: false,
                level: 0,
                experiencePoints: 0,
                totalReadBooks: 0,
                totalQuizScore: 0,
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.of(context).size.width;
                final horizontalPadding = screenWidth < 400 ? 12.0 : 16.0;
                final bottomPadding = widget.showBottomNav ? 80.0 : 20.0;
                
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding, 
                    16, 
                    horizontalPadding, 
                    bottomPadding
                  ),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Home Header (Profile + Level + XP + Streak)
                  HomeHeader(
                    profile: userProfile!,
                    greeting: GreetingHelper.getGreetingWithEmoji(userProfile!.displayNameOrUserName),
                    streakDays: _cachedStreakDays ?? userProfile!.currentStreak,
                    onTap: () {
                      if (authState is AuthAuthenticated) {
                        Navigator.pushNamed(context, '/profile');
                      } else {
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                  ),
                  const SizedBox(height: _largeSpacing),
                  
                  // 3. EĞİTİM ODAKLI BÖLÜMLER - Öğrenme hiyerarşisi
                  
                  // 3.1 Günlük İlerleme (En önemli - motivasyon)
                  DailyProgressCard(
                    profile: userProfile!,
                    streakDays: _cachedStreakDays ?? userProfile!.currentStreak,
                    dailyXP: _cachedDailyXP ?? 0,
                    dailyGoal: 50,
                  ),
                  const SizedBox(height: _largeSpacing),
                  
                  // 3.2 Devam Eden Okuma
                  const ContinueReadingCard(),
                  const SizedBox(height: _extraLargeSpacing),
                  
                  // 4. KİTAP ÖNERİLERİ - Öğrenme seviyesine göre
                  
                  // 4.1 Sana Özel (önerilen) - Kişiselleştirilmiş
                  _buildSectionTitle('Sana Özel', 'Seviyene uygun kitaplar'),
                  const SizedBox(height: _smallSpacing),
                  Consumer<BookListViewModel>(
                    builder: (context, bookViewModel, child) {
                      if (bookViewModel.isLoading) {
                        return _buildLoadingSection();
                      }
                      final userLevel = (userProfile?.levelName ?? userProfile?.levelDisplay ?? '')
                          .toString()
                          .trim();
                      final books = bookViewModel.getRecommendedBooks(limit: 6, userLevel: userLevel);
                      if (books.isEmpty) return _buildEmptySection('Henüz önerilen kitap yok');
                      return _buildBooksScroller(context, books);
                    },
                  ),
                  const SizedBox(height: _extraLargeSpacing),
                  
                  // 4.2 Yeni Eklenenler
                  _buildSectionTitle('Yeni Eklenenler', 'Son eklenen kitaplar'),
                  const SizedBox(height: _smallSpacing),
                  Consumer<BookListViewModel>(
                    builder: (context, bookViewModel, child) {
                      if (bookViewModel.isLoading) {
                        return _buildLoadingSection();
                      }
                      final books = bookViewModel.getRecentlyAddedBooks(limit: 6);
                      if (books.isEmpty) return _buildEmptySection('Henüz yeni kitap eklenmemiş');
                      return _buildBooksScroller(context, books);
                    },
                  ),
                  const SizedBox(height: _extraLargeSpacing),
                  
                  // 4.3 Trend Kitaplar
                  _buildSectionTitle('Trend Kitaplar', 'Popüler kitaplar'),
                  const SizedBox(height: _smallSpacing),
                  Consumer<BookListViewModel>(
                    builder: (context, bookViewModel, child) {
                      if (bookViewModel.isLoading) {
                        return _buildLoadingSection();
                      }
                      final books = bookViewModel.getTrendingBooks();
                      if (books.isEmpty) return _buildEmptySection('Henüz trend kitap yok');
                      return _buildBooksScroller(context, books);
                    },
                  ),
                  const SizedBox(height: _sectionSpacing),
                  
                  // 5. QUIZ REKLAMI - Liderlik tablosundan önce
                  const QuizAdvertisementCard(),
                  const SizedBox(height: _largeSpacing),
                  
                  // 5.1 KELİME DEFTERİ - Quiz'den sonra
                  const VocabularyNotebookCard(),
                  const SizedBox(height: _largeSpacing),
                  
                  // 6. SOSYAL VE MOTİVASYON - En altta
                  
                  // 6.1 Leaderboard Preview
                  const LeaderboardPreview(),
                  const SizedBox(height: _largeSpacing),
                ],
              ),
            );
              },
            );
          },
        ),
      ),
    );
  }

}

Widget _buildBooksScroller(BuildContext context, List<Book> books) {
  return LayoutBuilder(
    builder: (context, constraints) {
      final screenWidth = MediaQuery.of(context).size.width;
      final screenHeight = MediaQuery.of(context).size.height;
      
      // Responsive card width based on screen size
      double cardWidth;
      if (screenWidth < 400) {
        cardWidth = 110; // Smaller screens
      } else if (screenWidth < 600) {
        cardWidth = 121; // Medium screens
      } else {
        cardWidth = 135; // Larger screens
      }
      
      final double coverHeight = cardWidth * 1.30; // Keep aspect ratio
      final double listHeight = coverHeight + (screenHeight < 600 ? 76 : 90); // Responsive text area (increased to prevent overflow)
      
      return SizedBox(
        height: listHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: books.length.clamp(0, 8),
          separatorBuilder: (_, __) => SizedBox(width: screenWidth < 400 ? 12 : 16),
          itemBuilder: (context, index) {
            final book = books[index];
            return UnifiedBookCard(
              book: book,
            );
          },
        ),
      );
    },
  );
}

// Removed: _StatChip (home counters UI)
// Removed: _RecentCoverThumb (moved to continue_reading_card.dart)

