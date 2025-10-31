import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../bloc/vocabulary_bloc.dart';
import '../bloc/vocabulary_event.dart';
import 'vocabulary_word_card.dart';
import '../pages/vocabulary_word_detail_page.dart';
import '../pages/vocabulary_study_page.dart';

class VocabularyWordList extends StatelessWidget {
  final List<VocabularyWord> words;

  const VocabularyWordList({
    super.key,
    required this.words,
  });

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.book_rounded,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Henüz Kelime Yok',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Okuma yaparken kelimeleri defterinize ekleyebilir\nveya sağ alttaki butonla yeni kelime ekleyebilirsiniz',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'İpucu: Kitap okurken kelimelere dokunun',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BlocProvider.value(
                            value: context.read<VocabularyBloc>(),
                            child: const VocabularyStudyPage(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_circle_fill_rounded),
                    label: const Text('Bugün Çalış'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final word = words[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey<int>(word.id),
                background: _swipeBackground(context, alignLeft: true, color: const Color(0xFF10b981), icon: Icons.check_circle_rounded, label: 'İlerle'),
                secondaryBackground: _swipeBackground(context, alignLeft: false, color: const Color(0xFFef4444), icon: Icons.delete_rounded, label: 'Sil'),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    _showDeleteConfirmation(context, word);
                    return false;
                  } else {
                    // Cycle status: new_ -> learning -> known
                    final next = _nextStatus(word.status);
                    context.read<VocabularyBloc>().add(
                      UpdateWord(
                        word: word.copyWith(status: next),
                      ),
                    );
                    return false;
                  }
                },
                child: VocabularyWordCard(
                  word: word,
                  onTap: () => _navigateToWordDetail(context, word),
                  onStatusChanged: (newStatus) {
                    context.read<VocabularyBloc>().add(
                      UpdateWord(
                        word: word.copyWith(status: newStatus),
                      ),
                    );
                  },
                  onDelete: () => _showDeleteConfirmation(context, word),
                ),
              ),
            );
          },
          childCount: words.length,
        ),
      ),
    );
  }

  void _navigateToWordDetail(BuildContext context, VocabularyWord word) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => VocabularyWordDetailPage(vocabWordId: word.id, initialWord: word),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, VocabularyWord word) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kelimeyi Sil',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${word.word}" kelimesini defterinizden silmek istediğinizden emin misiniz?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                context.read<VocabularyBloc>().add(
                  DeleteWord(wordId: word.id),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Sil',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'İptal',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swipeBackground(BuildContext context, {required bool alignLeft, required Color color, required IconData icon, required String label}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
          end: alignLeft ? Alignment.centerRight : Alignment.centerLeft,
          colors: alignLeft
              ? [color, color.withOpacity(0.7)]
              : [color.withOpacity(0.7), color],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.only(
        left: alignLeft ? 24 : 16,
        right: alignLeft ? 16 : 24,
      ),
      child: Row(
        mainAxisAlignment: alignLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (alignLeft) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
          ] else ...[
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ],
        ],
      ),
    );
  }

  VocabularyStatus _nextStatus(VocabularyStatus s) {
    switch (s) {
      case VocabularyStatus.new_:
        return VocabularyStatus.learning;
      case VocabularyStatus.learning:
        return VocabularyStatus.known;
      case VocabularyStatus.known:
        return VocabularyStatus.mastered;
      case VocabularyStatus.mastered:
        return VocabularyStatus.mastered;
    }
  }
}
