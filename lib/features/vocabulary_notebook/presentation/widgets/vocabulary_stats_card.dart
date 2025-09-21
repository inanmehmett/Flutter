import 'package:flutter/material.dart';
import '../../domain/entities/vocabulary_stats.dart';

class VocabularyStatsCard extends StatelessWidget {
  final VocabularyStats stats;

  const VocabularyStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'İstatistiklerim',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Ana istatistikler
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Toplam',
                  '${stats.totalWords}',
                  Icons.book_outlined,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Tekrar Gerekli',
                  '${stats.wordsNeedingReview}',
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  context,
                  'Bugün Eklenen',
                  '${stats.wordsAddedToday}',
                  Icons.add_circle_outline,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Bugün Tekrar',
                  '${stats.wordsReviewedToday}',
                  Icons.refresh,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // İlerleme çubuğu
          _buildProgressSection(context),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Öğrenme İlerlemesi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(stats.learningProgress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: stats.learningProgress,
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildProgressItem(context, '🆕', 'Yeni', stats.newWords),
            _buildProgressItem(context, '📚', 'Öğreniyorum', stats.learningWords),
            _buildProgressItem(context, '✅', 'Biliyorum', stats.knownWords),
            _buildProgressItem(context, '🏆', 'Uzman', stats.masteredWords),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressItem(
    BuildContext context,
    String emoji,
    String label,
    int count,
  ) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
