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
import '../../../../core/storage/last_read_manager.dart';
import '../../../../core/network/network_manager.dart';
import '../../../../core/config/app_config.dart';
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

  Future<int?> _fetchStreakDays() async {
    if (_cachedStreakDays != null) return _cachedStreakDays;
    try {
      final client = getIt<NetworkManager>();
      final resp = await client.get('/api/ApiProgressStats/streak');
      final root = resp.data is Map<String, dynamic> ? resp.data as Map<String, dynamic> : {};
      final data = root['data'] is Map<String, dynamic> ? root['data'] as Map<String, dynamic> : {};
      final val = (data['currentStreak'] ?? data['CurrentStreak'] ?? data['streak']);
      final streak = (val is num) ? val.toInt() : (val is String ? int.tryParse(val) ?? 0 : 0);
      _cachedStreakDays = streak;
      return streak;
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
                  // Gamification Header (Yeni)
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
                  const SizedBox(height: 16),
                  // Profil Header (Tıklanabilir) - alt kısımda
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
                  // Time-based greeting personalized + test button (temporary)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.fastOutSlowIn,
                    switchOutCurve: Curves.fastOutSlowIn,
                    child: Text(
                      _personalizeGreeting(greeting, userProfile.userName),
                      key: ValueKey<String>(_personalizeGreeting(greeting, userProfile.userName)),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Bugün ne okumak istersiniz?', style: TextStyle(color: Colors.grey[600])),
                  // Removed: Okunan/Doğrulanan counters
                  const SizedBox(height: 16),
                  // Gamification header removed per UX

                  // Hızlı erişim kaldırıldı

                  // (Önerilen/Trend sekmeleri kaldırıldı)

                  // Continue Reading
                  const SizedBox(height: 24),
                  _buildContinueReading(context),
                  const SizedBox(height: 24),
                  // Sana Özel (önerilen)
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
                  // Yeni Eklenenler
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
                  // Trending Books - horizontal list
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
              Navigator.pushReplacementNamed(context, '/quiz');
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
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 4),
                    CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(width: 12),
                    Expanded(child: Text('Yükleniyor...')),
                  ],
                ),
              );
            }

            if (items.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.play_circle_fill, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('Son okunan bulunamadı'),
                    ),
                  ],
                ),
              );
            }

            // Multiple recent items horizontal list
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_fill, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Okumaya devam et', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 92,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length.clamp(0, 5),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final info = items[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pushNamed(context, '/reader', arguments: info.book);
                        },
                        child: Container(
                          width: 240,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _RecentCoverThumb(info: info),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      info.book.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Sayfa ${info.pageIndex + 1}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.play_arrow),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
  String resolveUrl(String? imageUrl, String? iconUrl) {
    final url = (iconUrl != null && iconUrl.isNotEmpty) ? iconUrl : (imageUrl ?? '');
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
    return '${AppConfig.apiBaseUrl}/$url';
  }

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
        final cover = resolveUrl(book.imageUrl, book.iconUrl);
        return SizedBox(
          width: cardWidth,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/book-preview',
                arguments: BookModel.fromBook(book),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: coverHeight,
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    child: cover.isEmpty
                        ? const Icon(Icons.menu_book, size: 40)
                        : Image.network(
                            cover,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.menu_book, size: 40),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Daily English',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.1),
                ),
                const SizedBox(height: 2),
                Text(
                  '${book.estimatedReadingTimeInMinutes} min • Lvl ${book.textLevel ?? '1'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.1),
                ),
              ],
            ),
          ),
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
