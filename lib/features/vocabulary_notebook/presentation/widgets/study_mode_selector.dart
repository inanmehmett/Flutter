import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/study_mode.dart';

class StudyModeSelector extends StatelessWidget {
  final StudyMode selectedMode;
  final ValueChanged<StudyMode> onModeChanged;

  const StudyModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: StudyMode.values.map((mode) {
          final isSelected = selectedMode == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onModeChanged(mode);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getModeIcon(mode),
                      size: 16,
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getModeLabel(mode),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getModeIcon(StudyMode mode) {
    switch (mode) {
      case StudyMode.review:
        return Icons.refresh_rounded;
      case StudyMode.quiz:
        return Icons.quiz_outlined;
      case StudyMode.flashcards:
        return Icons.style_outlined;
      case StudyMode.practice:
        return Icons.fitness_center_outlined;
    }
  }

  String _getModeLabel(StudyMode mode) {
    switch (mode) {
      case StudyMode.review:
        return 'Tekrar';
      case StudyMode.quiz:
        return 'Quiz';
      case StudyMode.flashcards:
        return 'Kartlar';
      case StudyMode.practice:
        return 'Pratik';
    }
  }
}
