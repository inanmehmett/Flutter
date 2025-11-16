import 'package:flutter/material.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/vocabulary_stats.dart';

class VocabularyStatusFilter extends StatelessWidget {
  final VocabularyStatus? selectedStatus;
  final VocabularyStats stats;
  final ValueChanged<VocabularyStatus?> onStatusChanged;

  const VocabularyStatusFilter({
    super.key,
    required this.selectedStatus,
    required this.stats,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            context,
            label: 'Tümü',
            count: stats.totalWords,
            icon: Icons.library_books,
            isSelected: selectedStatus == null,
            onTap: () => onStatusChanged(null),
          ),
          const SizedBox(width: 8),
          ...VocabularyStatus.values.map(
            (status) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildFilterChip(
                context,
                label: status.displayName,
                count: _getCountForStatus(status),
                icon: _getIconForStatus(status),
                isSelected: selectedStatus == status,
                onTap: () => onStatusChanged(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForStatus(VocabularyStatus status) {
    switch (status) {
      case VocabularyStatus.new_:
        return Icons.fiber_new;
      case VocabularyStatus.learning:
        return Icons.school;
      case VocabularyStatus.known:
        return Icons.check_circle;
      case VocabularyStatus.mastered:
        return Icons.star;
    }
  }

  int _getCountForStatus(VocabularyStatus status) {
    switch (status) {
      case VocabularyStatus.new_:
        return stats.newWords;
      case VocabularyStatus.learning:
        return stats.learningWords;
      case VocabularyStatus.known:
        return stats.knownWords;
      case VocabularyStatus.mastered:
        return stats.masteredWords;
    }
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required int count,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.85),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
                letterSpacing: -0.1,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.2)
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
