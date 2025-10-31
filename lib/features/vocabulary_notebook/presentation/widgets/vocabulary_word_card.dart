import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/vocabulary_word.dart';

class VocabularyWordCard extends StatelessWidget {
  final VocabularyWord word;
  final VoidCallback onTap;
  final ValueChanged<VocabularyStatus> onStatusChanged;
  final VoidCallback onDelete;

  const VocabularyWordCard({
    super.key,
    required this.word,
    required this.onTap,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'vocab_word_${word.id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                word.word,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            word.meaning,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.75),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _showStatusMenu(context),
                      behavior: HitTestBehavior.opaque,
                      child: _buildStatusChip(context),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        try {
                          final tts = getIt<FlutterTts>();
                          await tts.stop();
                          await tts.setLanguage('en-US');
                          await tts.speak(word.word);
                        } catch (_) {}
                      },
                      behavior: HitTestBehavior.opaque,
                      child: _buildSpeakButton(context),
                    ),
                    const SizedBox(width: 4),
                    _overflowMenu(context),
                  ],
                ),
                if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '"${word.exampleSentence!}"',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildStatsRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor(context).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(context).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForStatus(word.status),
            size: 14,
            color: _getStatusColor(context),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              word.status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(context),
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeakButton(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.volume_up_rounded,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Progress indicator
          if (word.reviewCount > 0) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getAccuracyColor(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      '${(word.accuracyRate * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _getAccuracyColor(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Doğruluk Oranı',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  LinearProgressIndicator(
                    value: word.accuracyRate,
                    backgroundColor: _getAccuracyColor(context).withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(_getAccuracyColor(context)),
                    minHeight: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // Review count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${word.reviewCount}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Next review time (if available)
          if (word.nextReviewAt != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.alarm_rounded,
                    size: 12,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatNextReview(word.nextReviewAt!),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Added date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(word.addedAt),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _overflowMenu(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
        const PopupMenuItem(value: 'delete', child: Text('Sil')),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            onTap();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _showStatusMenu(BuildContext context) {
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
                  Text(
                    'Durum Değiştir',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kelime öğrenme ilerlemenizi güncelleyin',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...VocabularyStatus.values.map(
              (status) => Column(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      onStatusChanged(status);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _getStatusColor(context, status: status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                _getIconForStatus(status),
                                size: 20,
                                color: _getStatusColor(context, status: status),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              status.displayName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (word.status == status)
                            Icon(
                              Icons.check_circle_rounded,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (status != VocabularyStatus.values.last)
                    const Divider(height: 1, indent: 76),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
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

  Color _getStatusColor(BuildContext context, {VocabularyStatus? status}) {
    final s = status ?? word.status;
    switch (s) {
      case VocabularyStatus.new_:
        return Colors.blue;
      case VocabularyStatus.learning:
        return Colors.orange;
      case VocabularyStatus.known:
        return Colors.green;
      case VocabularyStatus.mastered:
        return Colors.purple;
    }
  }

  Color _getAccuracyColor(BuildContext context) {
    final accuracy = word.accuracyRate;
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) return 'Bugün';
    if (difference == 1) return 'Dün';
    if (difference < 7) return '$difference gün önce';
    if (difference < 30) return '${(difference / 7).round()} hafta önce';
    return '${(difference / 30).round()} ay önce';
  }

  String _formatNextReview(DateTime when) {
    final now = DateTime.now();
    if (when.isBefore(now)) return 'Şimdi';
    final diff = when.difference(now);
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
    if (diff.inHours < 24) return '${diff.inHours} sa';
    return '${diff.inDays} gün';
  }
}
