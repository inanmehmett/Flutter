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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _todayBanner(context, primary, surface, text),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final int columns = maxWidth < 360 ? 2 : 3;
              final double spacing = 8.0;
              final double totalSpacing = spacing * (columns - 1);
              // Subtract a tiny epsilon to avoid fractional rounding overflow on some devices
              final double itemWidth = ((maxWidth - totalSpacing - 0.5) / columns).floorToDouble();

              final items = <Widget>[
                SizedBox(width: itemWidth, child: _miniStat(context, label: 'Toplam', value: stats.totalWords.toString(), icon: Icons.menu_book_outlined)),
                SizedBox(width: itemWidth, child: _miniStat(context, label: 'Tekrar', value: stats.wordsNeedingReview.toString(), icon: Icons.refresh_outlined)),
                SizedBox(width: itemWidth, child: _progressStat(context, label: 'İlerleme', progress: stats.learningProgress)),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: items,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _todayBanner(BuildContext context, Color primary, Color surface, Color textColor) {
    final int due = stats.wordsNeedingReview;
    final int added = stats.wordsAddedToday;
    
    // Motivational message based on due words
    String motivationMessage;
    String emoji;
    if (due == 0) {
      motivationMessage = 'Harika! Tüm kelimeler güncel 🎉';
      emoji = '✨';
    } else if (due <= 5) {
      motivationMessage = 'Az kaldı! Hızlıca tamamla 💪';
      emoji = '🎯';
    } else if (due <= 15) {
      motivationMessage = 'Bugünkü hedefine odaklan 🔥';
      emoji = '🔥';
    } else {
      motivationMessage = '$due kelime seni bekliyor!';
      emoji = '📚';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(0.85),
            primary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bugün Çalışılacak',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      motivationMessage,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$due tekrar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$added yeni',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _primaryCta(
                  context,
                  label: 'Başla',
                  icon: Icons.play_arrow_rounded,
                  onTap: (stats.wordsNeedingReview > 0 || stats.totalWords > 0) ? onWorkToday : null,
                  isWhite: true,
                  enabled: stats.wordsNeedingReview > 0 || stats.totalWords > 0,
                ),
              ),
              if (onQuiz != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _secondaryCta(
                    context,
                    label: 'Quiz',
                    icon: Icons.quiz_rounded,
                    onTap: stats.totalWords > 0 ? onQuiz! : null,
                    isWhite: true,
                    enabled: stats.totalWords > 0,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(BuildContext context, {required String label, required String value, required IconData icon}) {
    final colors = _getStatGradient(label);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors[1].withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getStatGradient(String label) {
    if (label.contains('Toplam')) {
      return [const Color(0xFF667eea), const Color(0xFF764ba2)];
    } else if (label.contains('Tekrar')) {
      return [const Color(0xFFf093fb), const Color(0xFFf5576c)];
    } else {
      return [const Color(0xFF4facfe), const Color(0xFF00f2fe)];
    }
  }

  Widget _progressStat(BuildContext context, {required String label, required double progress}) {
    final int percent = (progress.clamp(0, 1) * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFffecd2), Color(0xFFfcb69f)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFfcb69f).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress.clamp(0, 1),
                        strokeWidth: 3,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryCta(BuildContext context, {required String label, required IconData icon, VoidCallback? onTap, bool isWhite = false, bool enabled = true}) {
    return ElevatedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.2,
        ),
      ),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: enabled 
            ? (isWhite ? Colors.white : Theme.of(context).colorScheme.primary)
            : (isWhite ? Colors.white.withOpacity(0.5) : Theme.of(context).colorScheme.primary.withOpacity(0.5)),
        foregroundColor: enabled
            ? (isWhite ? Theme.of(context).colorScheme.primary : Colors.white)
            : (isWhite ? Theme.of(context).colorScheme.primary.withOpacity(0.5) : Colors.white.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _secondaryCta(BuildContext context, {required String label, required IconData icon, VoidCallback? onTap, bool isWhite = false, bool enabled = true}) {
    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          letterSpacing: -0.2,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled
            ? (isWhite ? Colors.white : Theme.of(context).colorScheme.primary)
            : (isWhite ? Colors.white.withOpacity(0.5) : Theme.of(context).colorScheme.primary.withOpacity(0.5)),
        side: BorderSide(
          color: enabled
              ? (isWhite ? Colors.white.withOpacity(0.4) : Theme.of(context).colorScheme.primary.withOpacity(0.6))
              : (isWhite ? Colors.white.withOpacity(0.2) : Theme.of(context).colorScheme.primary.withOpacity(0.3)),
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}


