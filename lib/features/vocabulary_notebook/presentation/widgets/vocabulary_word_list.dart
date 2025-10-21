import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../bloc/vocabulary_bloc.dart';
import '../bloc/vocabulary_event.dart';
import 'vocabulary_word_card.dart';
import '../pages/vocabulary_word_detail_page.dart';

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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book_outlined,
                size: 64,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Henüz kelime eklenmemiş',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Okuma yaparken kelimeleri defterinize ekleyebilirsiniz',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
            );
          },
          childCount: words.length,
        ),
      ),
    );
  }

  void _navigateToWordDetail(BuildContext context, VocabularyWord word) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VocabularyWordDetailPage(vocabWordId: word.id),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, VocabularyWord word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kelimeyi Sil'),
        content: Text('${word.word} kelimesini defterinizden silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<VocabularyBloc>().add(
                DeleteWord(wordId: word.id),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
