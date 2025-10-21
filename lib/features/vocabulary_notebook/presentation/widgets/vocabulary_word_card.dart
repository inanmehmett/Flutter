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
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          word.meaning,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context),
                  const SizedBox(width: 4),
                  _overflowMenu(context),
                ],
              ),
              if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '"${word.exampleSentence!}"',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              _buildStatsRow(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return GestureDetector(
      onTap: () => _showStatusMenu(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor(context).withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.status.emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              word.status.displayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStatusColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        if (word.reviewCount > 0) ...[
          Icon(
            Icons.analytics_outlined,
            size: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 4),
          Text(
            '${(word.accuracyRate * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getAccuracyColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
        ],
        Icon(
          Icons.access_time,
          size: 14,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(word.addedAt),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            icon,
            size: 18,
            color: color ?? Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _overflowMenu(BuildContext context) {
    return PopupMenuButton<String>(
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'speak', child: Text('Seslendir')),
        const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
        const PopupMenuItem(value: 'delete', child: Text('Sil')),
      ],
      onSelected: (value) async {
        switch (value) {
          case 'speak':
            try {
              final tts = getIt<FlutterTts>();
              await tts.stop();
              await tts.setLanguage('en-US');
              await tts.speak(word.word);
            } catch (_) {}
            break;
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Durum Değiştir',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...VocabularyStatus.values.map(
              (status) => ListTile(
                leading: Text(
                  status.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(status.displayName),
                trailing: word.status == status
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).primaryColor,
                      )
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  onStatusChanged(status);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context) {
    switch (word.status) {
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
}
