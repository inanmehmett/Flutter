import 'package:flutter/material.dart';
import '../../domain/entities/vocabulary_word.dart';

/// CEFR seviye filtresi: A1, A2, B1, B2, C1, C2
class VocabularyLevelFilter extends StatelessWidget {
  final String? selectedLevel; // e.g. 'A1', 'B2', null = hepsi
  final List<VocabularyWord> words;
  final ValueChanged<String?> onLevelChanged;

  const VocabularyLevelFilter({
    super.key,
    required this.selectedLevel,
    required this.words,
    required this.onLevelChanged,
  });

  static const List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  @override
  Widget build(BuildContext context) {
    final counts = _computeLevelCounts(words);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip(
            context,
            label: 'Tüm seviyeler',
            level: null,
            count: words.length,
            isSelected: selectedLevel == null,
          ),
          const SizedBox(width: 8),
          for (final level in _levels) ...[
            _buildChip(
              context,
              label: level,
              level: level,
              count: counts[level] ?? 0,
              isSelected: selectedLevel == level,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Map<String, int> _computeLevelCounts(List<VocabularyWord> words) {
    final Map<String, int> result = {};
    for (final w in words) {
      final lvl = w.wordLevel?.toUpperCase().trim();
      if (lvl == null || lvl.isEmpty) continue;
      if (!_levels.contains(lvl)) continue;
      result[lvl] = (result[lvl] ?? 0) + 1;
    }
    return result;
  }

  Widget _buildChip(
    BuildContext context, {
    required String label,
    required String? level,
    required int count,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onLevelChanged(level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[850]
                  : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.85),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.2)
                    : Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


