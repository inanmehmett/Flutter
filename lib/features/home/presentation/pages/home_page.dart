import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../reader/presentation/viewmodels/book_list_view_model.dart';
import '../../../reader/domain/entities/book.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../home/presentation/widgets/profile_header.dart';
import '../../../game/widgets/leaderboard_preview.dart';
import '../../../../core/storage/last_read_manager.dart';
import '../../../../core/config/app_config.dart';
import '../../../game/services/game_service.dart';
import '../../../quiz/presentation/pages/vocabulary_quiz_page.dart';
import '../../../quiz/presentation/cubit/vocabulary_quiz_cubit.dart';
import '../../../quiz/data/services/vocabulary_quiz_service.dart';
import '../../../reader/presentation/widgets/unified_book_card.dart';
// import removed: ApiClient no longer used for home counters

class HomePage extends StatefulWidget {
  final bool showBottomNav;
  const HomePage({super.key, this.showBottomNav = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _cachedStreakDays;
  bool _isLoadingStreak = false;
  
  // Design system spacing
  static const double _smallSpacing = AppSpacing.spacing3;
  static const double _mediumSpacing = AppSpacing.spacing4;
  static const double _largeSpacing = AppSpacing.spacing5;
  static const double _extraLargeSpacing = AppSpacing.spacing6;
  static const double _sectionSpacing = AppSpacing.spacing8;
  
  // Design system colors (Orange-focused for English learning)
  static const Color _primaryOrange = AppColors.primary;
  static const Color _secondaryOrange = AppColors.primaryLight;
  static const Color _textPrimary = AppColors.textPrimary;
  static const Color _textSecondary = AppColors.textSecondary;
  static const Color _backgroundWhite = AppColors.surface;
  static const Color _borderColor = AppColors.border;
  @override
  void initState() {
    super.initState();
    // Load books when page initializes
    Future.microtask(() =>
        Provider.of<BookListViewModel>(context, listen: false).fetchBooks());
    
    // Check auth status when page initializes
    Future.microtask(() =>
        context.read<AuthBloc>().add(CheckAuthStatus()));

    // Prefetch all data to prevent multiple API calls
    _prefetchAllData();
  }

  Future<void> _prefetchAllData() async {
    try {
      // Fetch streak data once
      await _fetchStreakDays();
      
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
  void dispose() {
    // Clean up any resources
    super.dispose();
  }

  String _resolveImageUrl(String? imageUrl, String? iconUrl) {
    final url = (iconUrl != null && iconUrl.isNotEmpty)
        ? iconUrl
        : (imageUrl ?? '');
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
    return '${AppConfig.apiBaseUrl}/$url';
  }

  // Removed: _extractCount helper for counters

  Widget _buildPersonalizedGreeting(BuildContext context, UserProfile profile) {
    final now = DateTime.now();
    final hour = now.hour;
    
    String greeting;
    if (hour < 12) {
      greeting = 'Günaydın';
    } else if (hour < 17) {
      greeting = 'İyi günler';
    } else if (hour < 21) {
      greeting = 'İyi akşamlar';
    } else {
      greeting = 'İyi geceler';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, ${profile.userName}!',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bugün ne okumak istersiniz?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Future<int?> _fetchStreakDays() async {
    if (_cachedStreakDays != null || _isLoadingStreak) return _cachedStreakDays;
    
    try {
      _isLoadingStreak = true;
      final service = getIt<GameService>();
      final summary = await service.getProfileSummary();
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

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
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

  Widget _buildDailyProgressCard(BuildContext context, UserProfile profile) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryOrange, _secondaryOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardRadius),
        boxShadow: AppShadows.cardShadowElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Günlük İlerleme',
                style: AppTypography.title3.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                  'Günlük Hedef',
                  '${profile.experiencePoints} XP',
                  Icons.flag,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressItem(
                  'Streak',
                  '${_cachedStreakDays ?? profile.currentStreak} gün',
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizAdvertisementSection(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(AppSpacing.paddingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryOrange, _secondaryOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardRadius),
        boxShadow: AppShadows.cardShadowElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kelime Quiz\'e Başla',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yeni kelimeler öğren ve seviyeni yükselt!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: Semantics(
              label: 'Kelime Quiz\'ini Başlat',
              hint: 'İngilizce kelime bilginizi test etmek için dokunun',
              button: true,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => BlocProvider(
                        create: (context) => VocabularyQuizCubit(getIt<VocabularyQuizService>()),
                        child: const VocabularyQuizPage(),
                      ),
                    ),
                  );
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: _primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.paddingM),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Quiz\'e Başla',
                style: AppTypography.buttonMedium,
              ),
            ),
          ),
        ),
        ],
      ),
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
              valueColor: AlwaysStoppedAnimation<Color>(_primaryOrange),
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
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: _textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final greeting = _greetingByTime();
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
                  // 1. Profil Header (En üstte - kişisel odaklı)
                  GestureDetector(
                    onTap: () {
                      if (authState is AuthAuthenticated) {
                        Navigator.pushNamed(context, '/profile');
                      } else {
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    child: ProfileHeader(
                      profile: userProfile!,
                      streakDays: _cachedStreakDays ?? userProfile!.currentStreak,
                    ),
                  ),
                  const SizedBox(height: _mediumSpacing),
                  
                  // 2. Kişiselleştirilmiş Karşılama
                  _buildPersonalizedGreeting(context, userProfile!),
                  const SizedBox(height: _largeSpacing),
                  
                  // 3. EĞİTİM ODAKLI BÖLÜMLER - Öğrenme hiyerarşisi
                  
                  // 3.1 Günlük İlerleme (En önemli - motivasyon)
                  _buildDailyProgressCard(context, userProfile!),
                  const SizedBox(height: _largeSpacing),
                  
                  // 3.2 Devam Eden Okuma
                  _buildContinueReading(context),
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
                  _buildQuizAdvertisementSection(context),
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
      bottomNavigationBar: widget.showBottomNav ? BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.pushReplacementNamed(context, '/books');
              break;
            case 2:
              // Navigate to vocabulary quiz instead of placeholder quiz page
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider(
                    create: (context) => VocabularyQuizCubit(getIt<VocabularyQuizService>()),
                    child: const VocabularyQuizPage(),
                  ),
                ),
              );
              break;
            case 3:
              final state = context.read<AuthBloc>().state;
              if (state is AuthAuthenticated) {
                Navigator.pushReplacementNamed(context, '/profile');
              } else {
                Navigator.pushReplacementNamed(context, '/login');
              }
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ) : null,
    );
  }

  Widget _buildContinueReading(BuildContext context) {
    final lastReadManager = getIt<LastReadManager>();
    return StreamBuilder<LastReadInfo?>(
      stream: lastReadManager.updates,
      builder: (context, _) {
        return FutureBuilder<List<LastReadInfo>>(
          future: lastReadManager.getRecentReads(limit: 5),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <LastReadInfo>[];
            
            if (snapshot.connectionState == ConnectionState.waiting && items.isEmpty) {
              return _buildIOSLoadingCard();
            }

            if (items.isEmpty) {
              return _buildIOSEmptyCard();
            }

            // iOS 17 style continue reading section - single container
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Simple header - just title
                  const Text(
                    'Continue Reading',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      color: Color(0xFF1D1D1F), // iOS Black
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // iOS style book cards - responsive height
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final cardHeight = screenWidth < 400 ? 80.0 : 88.0;
                      
                      return SizedBox(
                        height: cardHeight,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length.clamp(0, 5),
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final info = items[index];
                            return _buildIOSBookCard(context, info, cardHeight);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIOSLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7), // iOS Light Gray
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Loading...',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 17,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7), // iOS Light Gray
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.book_outlined,
              color: Color(0xFF8E8E93), // iOS Gray
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'No recent books',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 17,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSBookCard(BuildContext context, LastReadInfo info, double cardHeight) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth < 400 ? 260.0 : 280.0;
    final coverHeight = cardHeight - 32; // Padding için alan bırak
    final coverWidth = coverHeight * 0.6; // Oran koru
    
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushNamed(context, '/reader', arguments: info.book);
      },
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // iOS style book cover - responsive
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: coverHeight,
                    width: coverWidth,
                    color: const Color(0xFFF2F2F7), // iOS Light Gray
                    child: _RecentCoverThumb(info: info),
                  ),
                ),
                // iOS style progress indicator
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E5EA), // iOS Separator
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (info.pageIndex + 1) / 50,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF007AFF), // iOS Blue
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Book title with better overflow handling
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      info.book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth < 400 ? 14 : 15,
                        height: 1.2,
                        color: const Color(0xFF1D1D1F), // iOS Black
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // iOS style secondary text with overflow protection
                  Text(
                    'Page ${info.pageIndex + 1} • ${info.book.estimatedReadingTimeInMinutes}m',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: screenWidth < 400 ? 12 : 13,
                      color: const Color(0xFF8E8E93), // iOS Gray
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // iOS style level text
                  Text(
                    'Level ${info.book.textLevel ?? '1'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: screenWidth < 400 ? 10 : 11,
                      color: const Color(0xFF34C759), // iOS Green
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // iOS style chevron
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFFC7C7CC), // iOS Light Gray
              size: 18,
            ),
          ],
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
      final double listHeight = coverHeight + (screenHeight < 600 ? 70 : 82); // Responsive text area
      
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

class _RecentCoverThumb extends StatelessWidget {
  final LastReadInfo info;
  const _RecentCoverThumb({required this.info});

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_HomePageState>();
    final resolved = state?._resolveImageUrl(info.book.imageUrl, info.book.iconUrl) ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        width: 48,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
        child: resolved.isEmpty
            ? const Icon(Icons.menu_book, size: 24)
            : Image.network(
                resolved,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const Icon(Icons.menu_book, size: 24),
              ),
      ),
    );
  }
}

// Removed: _StatChip (home counters UI)

