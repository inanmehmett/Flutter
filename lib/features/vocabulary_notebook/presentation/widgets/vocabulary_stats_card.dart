import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../domain/entities/vocabulary_stats.dart';

class VocabularyStatsCard extends StatelessWidget {
  final VocabularyStats stats;

  const VocabularyStatsCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.12),
                Colors.white.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.24)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 18, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(rect),
                    child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 8),
                  Text('İstatistiklerim', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  _ctaButton(context, label: 'Çalış', icon: Icons.psychology_alt, onTap: () => Navigator.of(context).pushNamed('/study/flashcards')),
                  const SizedBox(width: 8),
                  _ctaButton(context, label: 'Quiz', icon: Icons.quiz, onTap: () => Navigator.of(context).pushNamed('/study/quiz')),
                ],
              ),
              const SizedBox(height: 16),

              // Ana istatistikler
              Row(
                children: [
                  Expanded(child: _buildStatItem(context, 'Toplam', '${stats.totalWords}', Icons.book_outlined, Colors.blue)),
                  Expanded(child: _buildStatItem(context, 'Tekrar Gerekli', '${stats.wordsNeedingReview}', Icons.schedule, Colors.orange)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatItem(context, 'Bugün Eklenen', '${stats.wordsAddedToday}', Icons.add_circle_outline, Colors.green)),
                  Expanded(child: _buildStatItem(context, 'Bugün Tekrar', '${stats.wordsReviewedToday}', Icons.refresh, Colors.purple)),
                ],
              ),
              const SizedBox(height: 16),

              // İlerleme çubuğu
              _buildProgressSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color.withOpacity(0.8)), textAlign: TextAlign.center),
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
            Text('Öğrenme İlerlemesi', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            Text('${(stats.learningProgress * 100).toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: stats.learningProgress,
            backgroundColor: Colors.white.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
            minHeight: 10,
          ),
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

  Widget _buildProgressItem(BuildContext context, String emoji, String label, int count) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 2),
        Text('$count', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _ctaButton(BuildContext context, {required String label, required IconData icon, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
