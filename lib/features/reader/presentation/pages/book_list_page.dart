import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../viewmodels/book_list_view_model.dart';
import '../../domain/entities/book.dart';
import '../widgets/category_picker.dart';
import '../widgets/unified_book_card.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Books',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
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
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bookViewModel.errorMessage!,
                          style: const TextStyle(color: AppColors.warning),
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
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    scrollDirection: Axis.horizontal,
                    itemCount: filteredBooks.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return UnifiedBookCard(
                        book: book,
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
