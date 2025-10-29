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
    final categories = bookViewModel.categories;
    return SafeArea(
      child: Column(
        children: [
          _buildModernAppBar(),
          _buildSearchSection(),
          if (bookViewModel.hasError && bookViewModel.hasBooks)
            _buildErrorBanner(bookViewModel),
          Expanded(child: _buildCategorySections(context, bookViewModel, categories)),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: AppColors.background,
      child: Container
        (
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.accent],
          ),
          borderRadius: BorderRadius.circular(AppRadius.cardRadius),
          boxShadow: AppShadows.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kitaplar',
                    style: AppTypography.title1.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 18,
                        color: AppColors.textQuaternary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Okuma yolculuğunuza devam edin',
                          style: AppTypography.subhead.copyWith(
                            color: AppColors.textQuaternary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.white),
                    tooltip: 'Yenile',
                    onPressed: () {
                      final vm = Provider.of<BookListViewModel>(context, listen: false);
                      vm.refreshBooks();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (kDebugMode)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.bug_report_rounded, color: AppColors.white),
                      onPressed: () {
                        final viewModel = Provider.of<BookListViewModel>(context, listen: false);
                        viewModel.debugBooks();
                      },
                      tooltip: 'Debug Books',
                    ),
                  ),
              ],
            ),
          ],
        ),
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

  // Ana sayfadaki bölüm başlığına benzer bir başlık
  Widget _buildSectionTitle(String title, [String? subtitle]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.title2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Ana sayfadaki yatay kitap kaydırıcıya benzer bir görünüm
  Widget _buildBooksScroller(BuildContext context, List<Book> books) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        double cardWidth;
        if (screenWidth < 400) {
          cardWidth = 110;
        } else if (screenWidth < 600) {
          cardWidth = 121;
        } else {
          cardWidth = 135;
        }
        final double coverHeight = cardWidth * 1.30;
        final double listHeight = coverHeight + (screenHeight < 600 ? 70 : 82);

        return SizedBox(
          height: listHeight,
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 20, right: 12),
            scrollDirection: Axis.horizontal,
            itemCount: books.length.clamp(0, 12),
            separatorBuilder: (_, __) => SizedBox(width: screenWidth < 400 ? 12 : 16),
            itemBuilder: (context, index) {
              final book = books[index];
              return UnifiedBookCard(book: book);
            },
          ),
        );
      },
    );
  }

  Widget _buildCategorySections(BuildContext context, BookListViewModel vm, List<String> categories) {
    return RefreshIndicator(
      onRefresh: () async => await vm.refreshBooks(),
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: widget.showBottomNav ? 100 : 20, top: 8),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final books = vm.filterBooksBySearchAndCategory(
            searchText: _searchController.text,
            category: category,
          );
          if (books.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildSectionTitle(category),
              const SizedBox(height: 8),
              _buildBooksScroller(context, books),
              const SizedBox(height: 8),
            ],
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

  // Grid kullanımı kaldırıldı; dikey kategoriler ve yatay scroller kullanılıyor

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
