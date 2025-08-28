import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../reader/presentation/viewmodels/book_list_view_model.dart';
import '../../../reader/data/models/book_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/di/injection.dart';
import '../../../home/presentation/widgets/profile_header.dart';
import '../../../../core/storage/last_read_manager.dart';
import '../../../../core/widgets/badge_celebration.dart';
import '../../../../core/network/network_manager.dart';

class HomePage extends StatefulWidget {
  final bool showBottomNav;
  const HomePage({super.key, this.showBottomNav = true});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _cachedStreakDays;
  int _booksTabIndex = 0; // 0: Önerilen, 1: Trend
  @override
  void initState() {
    super.initState();
    // Load books when page initializes
    Future.microtask(() =>
        Provider.of<BookListViewModel>(context, listen: false).fetchBooks());
    
    // Check auth status when page initializes
    Future.microtask(() =>
        context.read<AuthBloc>().add(CheckAuthStatus()));
  }

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
                  // Profil Header (Tıklanabilir) - önce
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
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      BadgeCelebration.show(context, name: 'Test Rozet', earned: true);
                    },
                    icon: const Icon(Icons.celebration),
                    label: const Text('Badge Test'),
                  ),
                  const SizedBox(height: 24),
                  // Gamification header removed per UX

                  // Hızlı erişim kaldırıldı

                  // Recommended Books
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_booksTabIndex == 0 ? 'Önerilen Kitaplar' : 'Trend Kitaplar',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Önerilen'),
                        selected: _booksTabIndex == 0,
                        onSelected: (v) => setState(() => _booksTabIndex = 0),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Trend'),
                        selected: _booksTabIndex == 1,
                        onSelected: (v) => setState(() => _booksTabIndex = 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<BookListViewModel>(
                    builder: (context, bookViewModel, child) {
                      if (bookViewModel.isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (bookViewModel.hasError && !bookViewModel.hasBooks) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                                const SizedBox(height: 8),
                                Text(
                                  'Kitaplar yüklenirken hata oluştu',
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => bookViewModel.refreshBooks(),
                                  child: const Text('Tekrar Dene'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final books = _booksTabIndex == 0
                          ? bookViewModel.getRecommendedBooks()
                          : bookViewModel.getTrendingBooks();

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
                      return SizedBox(
                        height: 210,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: books.length.clamp(0, 8),
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return SizedBox(
                              width: 140,
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
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
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: SizedBox(
                                          height: 120,
                                          width: double.infinity,
                                          child: book.iconUrl != null && book.iconUrl!.isNotEmpty
                                              ? Image.network(
                                                  book.imageUrl?.isNotEmpty == true ? book.imageUrl! : book.iconUrl!,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                                  child: Icon(
                                                    Icons.menu_book,
                                                    size: 40,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(10,10,10,10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book.title,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Text(
                                                  'Sev. ${book.textLevel ?? "1"} • ${book.estimatedReadingTimeInMinutes} dk',
                                                  style: TextStyle(color: Colors.grey[700], fontSize: 10),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(Icons.headset, size: 14, color: Colors.grey),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // Continue Reading
                  const SizedBox(height: 24),
                  _buildContinueReading(context),
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

                      return SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: books.length.clamp(0, 8),
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return SizedBox(
                              width: 130,
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          topRight: Radius.circular(16),
                                        ),
                                        child: SizedBox(
                                          height: 110,
                                          width: 130,
                                          child: book.iconUrl != null && book.iconUrl!.isNotEmpty
                                              ? Image.network(
                                                  book.imageUrl?.isNotEmpty == true ? book.imageUrl! : book.iconUrl!,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  child: Icon(
                                                    Icons.book,
                                                    size: 40,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(10,10,10,10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book.title,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            const Icon(Icons.headset, size: 13, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
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
    return FutureBuilder<LastReadInfo?>(
      future: lastReadManager.getLastRead(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.play_circle_fill, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Okumaya devam et', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(
                      snapshot.connectionState == ConnectionState.waiting
                          ? 'Yükleniyor...'
                          : (info == null
                              ? 'Son okunan: bulunamadı'
                              : '${info.book.title} • Sayfa ${info.pageIndex + 1}'),
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  if (info == null) return;
                  Navigator.pushNamed(
                    context,
                    '/reader',
                    arguments: info.book,
                  );
                },
                child: const Text('Devam'),
              ),
            ],
          ),
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
