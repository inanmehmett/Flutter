import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../reader/presentation/viewmodels/book_list_view_model.dart';
import '../../../reader/domain/entities/book.dart';
import '../../../reader/data/models/book_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/di/injection.dart';
import '../../../home/presentation/widgets/profile_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16,16,16,80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profil Header (Tıklanabilir)
                  GestureDetector(
                    onTap: () {
                      if (authState is AuthAuthenticated) {
                        Navigator.pushNamed(context, '/profile');
                      } else {
                        Navigator.pushNamed(context, '/login');
                      }
                    },
                    child: ProfileHeader(profile: userProfile),
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Hızlı Erişim',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.menu_book,
                          title: 'Kitaplar',
                          subtitle: 'Okuma',
                          color: Theme.of(context).colorScheme.primary,
                          onTap: () {
                            Navigator.pushNamed(context, '/books');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.quiz,
                          title: 'Quiz',
                          subtitle: 'Test',
                          color: Colors.green,
                          onTap: () {
                            Navigator.pushNamed(context, '/quiz');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.games,
                          title: 'Oyunlar',
                          subtitle: 'Eğlence',
                          color: Colors.purple,
                          onTap: () {
                            Navigator.pushNamed(context, '/games');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Recommended Books
                  const Text(
                    'Önerilen Kitaplar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

                      final books = bookViewModel.getRecommendedBooks();

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
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: books.length,
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 16),
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
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(12),
                                          topRight: Radius.circular(12),
                                        ),
                                        child: Container(
                                          height: 80,
                                          width: double.infinity,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          child: Icon(
                                            Icons.book,
                                            size: 40,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                book.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                book.author ?? 'Unknown',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                               Row(
                                                 crossAxisAlignment: CrossAxisAlignment.start,
                                                 children: [
                                                  Text(
                                                    '${book.estimatedReadingTimeInMinutes ?? 10} dk',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  const Text(' • ',
                                                      style: TextStyle(
                                                          color: Colors.grey)),
                                                  Text(
                                                    'Sev. ${book.textLevel ?? "1"}',
                                                    style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
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

                  // Trending Books
                  const Text(
                    'Trend Kitaplar',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
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
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: books.length,
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 16),
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
                                        child: Container(
                                          height: 95,
                                          width: 140,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          child: Icon(
                                            Icons.book,
                                            size: 40,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Text(
                                            book.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 1:
              Navigator.pushNamed(context, '/books');
              break;
            case 2:
              Navigator.pushNamed(context, '/quiz');
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
        ],
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
