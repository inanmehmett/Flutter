import 'package:flutter/material.dart';
import '../../domain/entities/vocabulary_stats.dart';

class VocabularyStatsHeader extends StatelessWidget {
  final VocabularyStats stats;
  final VoidCallback onWorkToday;
  final VoidCallback? onQuiz;

  const VocabularyStatsHeader({
    super.key,
    required this.stats,
    required this.onWorkToday,
    this.onQuiz,
  });

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    final Color surface = Theme.of(context).colorScheme.surface;
    final Color text = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black87;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: primary),
              const SizedBox(width: 8),
              Text(
                'İstatistiklerim',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              _primaryCta(context, label: 'Çalış', icon: Icons.psychology_alt, onTap: onWorkToday),
              if (onQuiz != null) ...[
                const SizedBox(width: 8),
                _secondaryCta(context, label: 'Quiz', icon: Icons.quiz, onTap: onQuiz!),
              ]
            ],
          ),
          const SizedBox(height: 12),
          _todayBanner(context, primary, surface, text),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat(context, label: 'Toplam', value: stats.totalWords.toString(), icon: Icons.menu_book_outlined),
              const SizedBox(width: 8),
              _miniStat(context, label: 'Tekrar', value: stats.wordsNeedingReview.toString(), icon: Icons.refresh_outlined),
              const SizedBox(width: 8),
              _progressStat(context, label: 'İlerleme', progress: stats.learningProgress),
            ],
          ),
        ],
      ),
    );
  }

  Widget _todayBanner(BuildContext context, Color primary, Color surface, Color textColor) {
    final int due = stats.wordsNeedingReview;
    final int added = stats.wordsAddedToday;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bugün çalışılacak', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('$due tekrar • $added yeni', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textColor.withOpacity(0.7))),
              ],
            ),
          ),
          _primaryCta(context, label: 'Çalış', icon: Icons.play_arrow_rounded, onTap: onWorkToday),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, {required String label, required String value, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _progressStat(BuildContext context, {required String label, required double progress}) {
    final int percent = (progress.clamp(0, 1) * 100).round();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress.clamp(0, 1),
                    strokeWidth: 4,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  ),
                  Text('$percent%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text('Toplam ilerleme', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7))),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _primaryCta(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _secondaryCta(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}


