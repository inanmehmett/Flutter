import 'package:flutter/material.dart';
import '../../domain/services/review_session.dart';
import '../../domain/entities/study_mode.dart';
import 'study_mode_selector.dart';

class StudySessionHeader extends StatelessWidget {
  final StudyMode mode;
  final ValueChanged<StudyMode> onModeChanged;
  final ReviewSession session;

  const StudySessionHeader({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mode selector
          StudyModeSelector(
            selectedMode: mode,
            onModeChanged: onModeChanged,
          ),
          
          const SizedBox(height: 16),
          
          // Session info
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  context,
                  icon: Icons.school_outlined,
                  label: 'Mod',
                  value: _getModeDisplayName(mode),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  icon: Icons.timer_outlined,
                  label: 'Tahmini Süre',
                  value: '${_calculateEstimatedTime()} dk',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  context,
                  icon: Icons.flag_outlined,
                  label: 'Hedef',
                  value: '${session.totalWords} kelime',
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getModeDisplayName(StudyMode mode) {
    switch (mode) {
      case StudyMode.review:
        return 'Günlük Tekrar';
      case StudyMode.quiz:
        return 'Quiz Modu';
      case StudyMode.flashcards:
        return 'Flashcard';
      case StudyMode.practice:
        return 'Pratik';
    }
  }

  int _calculateEstimatedTime() {
    // Her kelime için ortalama 15 saniye
    return (session.totalWords * 15 / 60).round().clamp(1, 60);
  }
}
