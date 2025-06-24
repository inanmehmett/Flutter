import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../viewmodels/book_list_view_model.dart';
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
                context.read<BookListViewModel>().debugBooks();
              },
            ),
        ],
      ),
      body: Consumer<BookListViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const LoadingView();
          }

          if (viewModel.errorMessage != null) {
            return ErrorView(errorMessage: viewModel.errorMessage!);
          }

          if (viewModel.books.isEmpty) {
            return const EmptyStateView();
          }

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => viewModel.fetchBooks(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount:
                        viewModel.filterBooks(_searchController.text).length,
                    itemBuilder: (context, index) {
                      final book =
                          viewModel.filterBooks(_searchController.text)[index];
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
