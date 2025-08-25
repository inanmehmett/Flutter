import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../viewmodels/book_list_view_model.dart';
import '../../domain/entities/book.dart';
import '../widgets/category_picker.dart';
import '../widgets/book_card.dart';
import '../widgets/loading_view.dart';
import '../widgets/error_view.dart';
import '../widgets/empty_state_view.dart';
import '../../data/models/book_model.dart';

class BookListPage extends StatefulWidget {
  final bool showBottomNav;
  const BookListPage({super.key, this.showBottomNav = true});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final TextEditingController _searchController = TextEditingController();
  // Categories always visible
  int _selectedCategory = 0;

  @override
  void initState() {
    super.initState();
    // ViewModel'den kitapları yükle
    Future.microtask(() =>
        Provider.of<BookListViewModel>(context, listen: false).fetchBooks());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(
          'Books',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                final viewModel = Provider.of<BookListViewModel>(context, listen: false);
                viewModel.debugBooks();
              },
            ),
        ],
      ),
      body: Consumer<BookListViewModel>(
        builder: (context, bookViewModel, child) {
          if (bookViewModel.state == BookListState.initial || 
              bookViewModel.state == BookListState.loading) {
            return const LoadingView();
          }

          if (bookViewModel.state == BookListState.error && !bookViewModel.hasBooks) {
            return ErrorView(errorMessage: bookViewModel.errorMessage ?? 'Bilinmeyen hata');
          }

          if (!bookViewModel.hasBooks) {
            return const EmptyStateView();
          }

          // Build categories dynamically from books
          final categories = bookViewModel.categories;
          if (_selectedCategory >= categories.length) {
            _selectedCategory = 0;
          }
          final selectedCategory = categories[_selectedCategory];
          final filteredBooks = bookViewModel.filterBooksBySearchAndCategory(
            searchText: _searchController.text,
            category: selectedCategory,
          );

          return SafeArea(
            top: false,
            child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search books...',
                    prefixIcon: Icon(Icons.search,
                        color: Theme.of(context).colorScheme.primary),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              // Categories: always visible, dynamic from data
              CategoryPicker(
                categories: categories,
                selectedCategory: _selectedCategory,
                onCategorySelected: (index) {
                  setState(() => _selectedCategory = index);
                },
              ),
              if (bookViewModel.hasError && bookViewModel.hasBooks)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookViewModel.errorMessage!,
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ),
                      TextButton(
                        onPressed: () => bookViewModel.clearError(),
                        child: const Text('Kapat'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await bookViewModel.refreshBooks();
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Adaptive grid: compute columns by a minimum tile width for responsiveness
                      const double minTileWidth = 150; // keeps tiles readable on small phones
                      final int crossAxisCount = (constraints.maxWidth / minTileWidth)
                          .floor()
                          .clamp(2, 8);
                      const double childAspectRatio = 0.68; // visual balance for cover+meta

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                         itemCount: filteredBooks.length,
                         itemBuilder: (context, index) {
                           final book = filteredBooks[index];
                           final coverUrl = (book.imageUrl?.isNotEmpty == true)
                               ? book.imageUrl!
                               : (book.iconUrl ?? '');
                           final hasAudio = book.content.isNotEmpty;
                           return InkWell(
                             borderRadius: BorderRadius.circular(14),
                             onTap: () {
                               Navigator.pushNamed(
                                 context,
                                 '/book-preview',
                                 arguments: BookModel.fromBook(book),
                               );
                             },
                              child: Card(
                               elevation: 1,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(14),
                               ),
                                child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                    // Görsel + başlık overlay (Expanded ile kalan yüksekliği kapla)
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(14),
                                          topRight: Radius.circular(14),
                                        ),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            (coverUrl.isNotEmpty)
                                                ? Image.network(coverUrl, fit: BoxFit.cover)
                                                : Container(
                                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                                    child: Icon(Icons.menu_book, size: 36, color: Theme.of(context).colorScheme.primary),
                                                  ),
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                    colors: [Color.fromARGB(180, 0, 0, 0), Color.fromARGB(0, 0, 0, 0)],
                                                  ),
                                                ),
                                                child: Text(
                                                  book.title,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Çok kısa meta satırı (seviye, süre, sesli ikon)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                                      child: Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        children: [
                                          if ((book.textLevel ?? '').isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[200],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text('Sev. ${book.textLevel}', style: const TextStyle(fontSize: 9.5)),
                                            ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.schedule, size: 11, color: Colors.grey[700]),
                                              const SizedBox(width: 2),
                                              Text(
                                                '${book.estimatedReadingTimeInMinutes} dk',
                                                style: TextStyle(fontSize: 9.0, color: Colors.grey[700]),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          if (hasAudio)
                                            const Icon(Icons.headset, size: 12, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                 ],
                               ),
                             ),
                           );
                         },
                       );
                    },
                  ),
                ),
              ),
            ],
          ),
          );
        },
      ),
      bottomNavigationBar: widget.showBottomNav ? BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              // already on books
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/quiz');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
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
}
