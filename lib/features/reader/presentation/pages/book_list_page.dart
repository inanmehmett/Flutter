import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/config/app_config.dart';
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
      body: Consumer<BookListViewModel>(
        builder: (context, bookViewModel, child) {
          if (bookViewModel.state == BookListState.initial || 
              bookViewModel.state == BookListState.loading) {
            return _buildLoadingState();
          }

          if (bookViewModel.state == BookListState.error && !bookViewModel.hasBooks) {
            return _buildErrorState(bookViewModel.errorMessage ?? 'Bilinmeyen hata');
          }

          if (!bookViewModel.hasBooks) {
            return _buildEmptyState();
          }

          return _buildMainContent(bookViewModel);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            const Expanded(child: LoadingView()),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(child: ErrorView(errorMessage: errorMessage)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            const Expanded(child: EmptyStateView()),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BookListViewModel bookViewModel) {
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
      child: Column(
        children: [
          _buildModernAppBar(),
          _buildSearchSection(),
          _buildCategorySection(categories),
          if (bookViewModel.hasError && bookViewModel.hasBooks)
            _buildErrorBanner(bookViewModel),
          Expanded(
            child: _buildBooksGrid(filteredBooks, bookViewModel),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📚 Kitaplar',
                  style: AppTypography.title1.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'İngilizce öğrenmeye devam edin',
                  style: AppTypography.subhead.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (kDebugMode)
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
              ),
              child: IconButton(
                icon: const Icon(Icons.bug_report, color: AppColors.primary),
                onPressed: () {
                  final viewModel = Provider.of<BookListViewModel>(context, listen: false);
                  viewModel.debugBooks();
                },
                tooltip: 'Debug Books',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.inputRadius),
          boxShadow: AppShadows.inputShadow,
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Kitap ara...',
            hintStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.inputRadius),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildCategorySection(List<String> categories) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
                boxShadow: isSelected ? AppShadows.buttonShadow : null,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 1,
                ),
              ),
              child: Text(
                categories[index],
                style: AppTypography.buttonMedium.copyWith(
                  color: isSelected ? AppColors.surface : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(BookListViewModel bookViewModel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.cardRadius),
        border: Border.all(color: AppColors.warning),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              bookViewModel.errorMessage!,
              style: AppTypography.body.copyWith(color: AppColors.warning),
            ),
          ),
          TextButton(
            onPressed: () => bookViewModel.clearError(),
            child: Text(
              'Kapat',
              style: AppTypography.buttonSmall.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksGrid(List<Book> books, BookListViewModel bookViewModel) {
    if (books.isEmpty) {
      return _buildNoBooksFound();
    }

    return RefreshIndicator(
      onRefresh: () async => await bookViewModel.refreshBooks(),
      child: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _getCrossAxisCount(),
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 20,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return UnifiedBookCard(
            book: book,
            isGridLayout: true,
          );
        },
      ),
    );
  }

  int _getCrossAxisCount() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 3;
    return 4;
  }

  Widget _buildNoBooksFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Kitap bulunamadı',
            style: AppTypography.title2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Arama kriterlerinizi değiştirmeyi deneyin',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }



}
