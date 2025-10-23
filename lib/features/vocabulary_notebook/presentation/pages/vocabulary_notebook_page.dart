import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/vocabulary_bloc.dart';
import '../bloc/vocabulary_event.dart';
import '../bloc/vocabulary_state.dart';
import '../widgets/vocabulary_search_bar.dart';
import '../widgets/vocabulary_status_filter.dart';
import '../widgets/vocabulary_word_list.dart';
import '../widgets/add_word_fab.dart';
import '../widgets/vocabulary_stats_header.dart';
import 'vocabulary_study_page.dart';

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
                  // iOS-style large title with toolbar
                  SliverAppBar(
                    expandedHeight: 100,
                    floating: false,
                    pinned: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                      title: const Text(
                        'Kelime Defterim',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.sync_rounded),
                        onPressed: _onRefresh,
                        tooltip: 'Senkronize Et',
                      ),
                      const SizedBox(width: 4),
                    ],
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
      floatingActionButton: const AddWordFab(),
    );
  }

}
