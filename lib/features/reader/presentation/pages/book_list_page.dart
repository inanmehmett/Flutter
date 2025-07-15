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
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showCategories = false;
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
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => setState(() => _showCategories = !_showCategories),
          ),
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

          final filteredBooks = bookViewModel.filterBooks(_searchController.text);

          return Column(
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
              if (_showCategories)
                CategoryPicker(
                  categories: const ['All', 'Fiction', 'Non-Fiction', 'Poetry'],
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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredBooks.length,
                    itemBuilder: (context, index) {
                      final book = filteredBooks[index];
                      return BookCard(
                        book: book,
                        onTap: () {
                          // Book entity'yi BookModel'e dönüştürerek gönder
                          Navigator.pushNamed(
                            context,
                            '/book-preview',
                            arguments: BookModel.fromBook(book),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
