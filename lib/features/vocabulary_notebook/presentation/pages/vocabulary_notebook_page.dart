import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/vocabulary_bloc.dart';
import '../bloc/vocabulary_event.dart';
import '../bloc/vocabulary_state.dart';
import '../widgets/vocabulary_search_bar.dart';
import '../widgets/vocabulary_status_filter.dart';
import '../widgets/vocabulary_word_list.dart';
import '../widgets/vocabulary_stats_header.dart';
import 'vocabulary_study_page.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';

class VocabularyNotebookPage extends StatefulWidget {
  const VocabularyNotebookPage({super.key});

  @override
  State<VocabularyNotebookPage> createState() => _VocabularyNotebookPageState();
}

class _VocabularyNotebookPageState extends State<VocabularyNotebookPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<VocabularyBloc>().add(LoadVocabulary());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      context.read<VocabularyBloc>().add(LoadVocabulary());
    } else {
      context.read<VocabularyBloc>().add(SearchWords(query: query));
    }
  }

  void _onStatusFilterChanged(status) {
    context.read<VocabularyBloc>().add(FilterByStatus(status: status));
  }

  void _onRefresh() {
    context.read<VocabularyBloc>().add(RefreshVocabulary());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      context.read<VocabularyBloc>().add(LoadMoreVocabulary());
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildPageContent(context);
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
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
                    'Kelime Defterim',
                    style: AppTypography.title1.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.bookmark_added_rounded,
                        size: 18,
                        color: AppColors.textQuaternary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kelimelerini düzenle, tekrar et ve ilerlemeni gör',
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
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildPageContent(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      body: BlocConsumer<VocabularyBloc, VocabularyState>(
        listener: (context, state) {
          if (state is VocabularyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is WordAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kelime başarıyla eklendi!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is WordUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kelime başarıyla güncellendi!'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is WordDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kelime başarıyla silindi!'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VocabularyLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is VocabularyError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onRefresh,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (state is VocabularyLoaded) {
            return RefreshIndicator(
              onRefresh: () async => _onRefresh(),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Modern gradient header
                  SliverToBoxAdapter(
                    child: _buildModernHeader(context),
                  ),
                  
                  // Modern minimal header
                  SliverToBoxAdapter(
                    child: VocabularyStatsHeader(
                      stats: state.stats,
                      onWorkToday: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<VocabularyBloc>(),
                            child: const VocabularyStudyPage(),
                          ),
                        ),
                      ),
                      onQuiz: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<VocabularyBloc>(),
                            child: const VocabularyStudyPage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                  
                  // Arama çubuğu
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: VocabularySearchBar(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 12),
                  ),
                  
                  // Durum filtresi
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: VocabularyStatusFilter(
                        selectedStatus: state.selectedStatus,
                        onStatusChanged: _onStatusFilterChanged,
                      ),
                    ),
                  ),
                  
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                  
                  // Kelime listesi
                  VocabularyWordList(words: state.words),

                  // Loading more indicator
                  SliverToBoxAdapter(
                    child: state.hasMore
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : const SizedBox.shrink(),
                  ),
                  
                  // Alt boşluk
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            );
          }

          return const Center(
            child: Text('Beklenmeyen durum'),
          );
        },
      ),
    );
  }

}
