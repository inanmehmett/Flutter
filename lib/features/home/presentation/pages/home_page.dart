import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../reader/presentation/viewmodels/book_list_view_model.dart';
import '../../../reader/data/models/book_model.dart';
import '../../../reader/domain/entities/book.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/di/injection.dart';
import '../../../home/presentation/widgets/profile_header.dart';
import '../../../home/presentation/widgets/gamification_header.dart';
import '../../../game/widgets/leaderboard_preview.dart';
import '../../../quests/presentation/widgets/quests_preview.dart';
import '../../../../core/storage/last_read_manager.dart';
import '../../../../core/network/network_manager.dart';
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
  @override
  void initState() {
    super.initState();
    // Load books when page initializes
    Future.microtask(() =>
        Provider.of<BookListViewModel>(context, listen: false).fetchBooks());
    
    // Check auth status when page initializes
    Future.microtask(() =>
        context.read<AuthBloc>().add(CheckAuthStatus()));

    // Removed: prefetch of finished/validated counters
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
    if (_cachedStreakDays != null) return _cachedStreakDays;
    try {
      final service = getIt<GameService>();
      final summary = await service.getProfileSummary();
      _cachedStreakDays = summary.currentStreak;
      return _cachedStreakDays;
    } catch (_) {
      return _cachedStreakDays;
    }
  }

  String _greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'İyi geceler';
    if (hour < 12) return 'Günaydın';
    if (hour < 18) return 'İyi günler';
    return 'İyi akşamlar';
  }

  String _personalizeGreeting(String greeting, String userName) {
    final name = userName.trim();
    return name.isNotEmpty ? '$greeting, $name!' : '$greeting!';
  }


  Widget _buildVocabularyQuizButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlocProvider(
                  create: (context) => VocabularyQuizCubit(getIt<VocabularyQuizService>()),
                  child: const VocabularyQuizPage(),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.purple.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quiz icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(
                    Icons.quiz,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Quiz info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kelime Quiz\'i',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'İngilizce kelimeleri test edin ve XP kazanın!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.white.withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '10 soru • 10s/soru',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ],
            ),
          ),
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

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16,16,16,80),
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
                    child: FutureBuilder<int?>(
                      future: _fetchStreakDays(),
                      builder: (context, snap) {
                        final streak = snap.data ?? userProfile!.currentStreak;
                        return ProfileHeader(
                          profile: userProfile!,
                          streakDays: streak,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 2. Kişiselleştirilmiş Karşılama
                  _buildPersonalizedGreeting(context, userProfile!),
                  const SizedBox(height: 20),
                  
                  // 3. Continue Reading Button - Karşılama mesajının hemen altına taşındı
                  _buildContinueReading(context),
                  const SizedBox(height: 24),
                  
                  // 4. Gamification Header (Motivasyon için)
                  FutureBuilder<int?>(
                    future: _fetchStreakDays(),
                    builder: (context, snap) {
                      final streak = snap.data ?? userProfile!.currentStreak;
                      return GamificationHeader(
                        profile: userProfile!,
                        streakDays: streak,
                        totalXP: userProfile!.experiencePoints,
                        weeklyXP: 0, // TODO: Fetch from API
                        dailyGoal: 30, // TODO: Fetch from user settings
                        dailyProgress: 0, // TODO: Calculate from today's activities
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // 4.2 Quests Preview
                  const QuestsPreview(),
                  const SizedBox(height: 20),
                  
                  // 4.3 Vocabulary Quiz Button
                  _buildVocabularyQuizButton(context),
                  const SizedBox(height: 20),
                  
                  // 5. Sana Özel (önerilen) - Kitapları daha öne çıkar
                  const Text('Sana Özel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Consumer<BookListViewModel>(
                    builder: (context, bookViewModel, child) {
                      if (bookViewModel.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final userLevel = (userProfile?.levelName ?? userProfile?.levelDisplay ?? '')
                          .toString()
                          .trim();
                      final books = bookViewModel.getRecommendedBooks(limit: 8, userLevel: userLevel);
                      if (books.isEmpty) return const SizedBox.shrink();
                      return _buildBooksScroller(context, books);
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // 6. Yeni Eklenenler
                  const Text('Yeni Eklenenler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Consumer<BookListViewModel>(
                    builder: (context, bookViewModel, child) {
                      if (bookViewModel.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final books = bookViewModel.getRecentlyAddedBooks(limit: 8);
                      if (books.isEmpty) return const SizedBox.shrink();
                      return _buildBooksScroller(context, books);
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // 7. Trending Books - horizontal list
                  const Text('Trend Kitaplar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Consumer<BookListViewModel>(
                    builder: (context, bookViewModel, child) {
                      if (bookViewModel.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final books = bookViewModel.getTrendingBooks();

                      if (books.isEmpty) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('Henüz kitap bulunamadı'),
                          ),
                        );
                      }
                      return _buildBooksScroller(context, books);
                    },
                  ),
                  const SizedBox(height: 32),
                  
                  // 8. Leaderboard Preview - En alta taşındı
                  const LeaderboardPreview(),
                  const SizedBox(height: 20),
                ],
              ),
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
                  // iOS style book cards
                  SizedBox(
                    height: 88, // Daha da azaltıldı overflow için
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length.clamp(0, 5),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final info = items[index];
                        return _buildIOSBookCard(context, info);
                      },
                    ),
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

  Widget _buildIOSBookCard(BuildContext context, LastReadInfo info) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushNamed(context, '/reader', arguments: info.book);
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(8), // 12'den 8'e düşürüldü
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
            // iOS style book cover
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 56, // Daha da azaltıldı overflow için
                    width: 60,
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    info.book.title,
                    maxLines: 1, // 2'den 1'e düşürüldü
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15, // 17'den 15'e düşürüldü
                      height: 1.1, // 1.2'den 1.1'e düşürüldü
                      color: Color(0xFF1D1D1F), // iOS Black
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4), // 8'den 4'e düşürüldü
                  // iOS style secondary text
                  Text(
                    'Page ${info.pageIndex + 1} • ${info.book.estimatedReadingTimeInMinutes}m',
                    style: const TextStyle(
                      fontSize: 13, // 15'ten 13'e düşürüldü
                      color: Color(0xFF8E8E93), // iOS Gray
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4), // 8'den 4'e düşürüldü
                  // iOS style level text
                  Text(
                    'Level ${info.book.textLevel ?? '1'}',
                    style: const TextStyle(
                      fontSize: 11, // 13'ten 11'e düşürüldü
                      color: Color(0xFF34C759), // iOS Green
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
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildBooksScroller(BuildContext context, List<Book> books) {
  // Photo-like proportions from the reference: tall cover and compact texts
  const double cardWidth = 121; // ~+10%
  final double coverHeight = cardWidth * 1.30; // keep same aspect ratio
  final double listHeight = coverHeight + 82; // slight slack for larger text box

  return SizedBox(
    height: listHeight,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: books.length.clamp(0, 8),
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final book = books[index];
        return UnifiedBookCard(
          book: book,
        );
      },
    ),
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

