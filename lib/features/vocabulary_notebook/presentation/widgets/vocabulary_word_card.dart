import 'package:flutter/material.dart';
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kelime ve durum
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.word,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          word.meaning,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(context),
                ],
              ),
              
              // Kişisel not
              if (word.personalNote != null && word.personalNote!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          word.personalNote!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Örnek cümle
              if (word.exampleSentence != null && word.exampleSentence!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '"${word.exampleSentence!}"',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Alt bilgiler ve aksiyonlar
              Row(
                children: [
                  // İstatistikler
                  Expanded(
                    child: _buildStatsRow(context),
                  ),
                  
                  // Aksiyon butonları
                  Row(
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.edit_outlined,
                        onPressed: onTap,
                        tooltip: 'Düzenle',
                      ),
                      const SizedBox(width: 8),
                      _buildActionButton(
                        context,
                        icon: Icons.delete_outline,
                        onPressed: onDelete,
                        tooltip: 'Sil',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
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
