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
    final mediaQuery = MediaQuery.of(context);
    final isCompactScreen = mediaQuery.size.height < 700;
    final textScale = mediaQuery.textScaleFactor.clamp(1.0, 1.2); // Limit text scaling
    
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
          child: MediaQuery(
            data: mediaQuery.copyWith(textScaleFactor: textScale),
            child: Padding(
              padding: EdgeInsets.all(isCompactScreen ? 14 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Hero(
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
                                ),
                                // CEFR seviyesi - kelimenin yanında göster
                                if (word.wordLevel != null && word.wordLevel!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getWordLevelColor(context).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _getWordLevelColor(context).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      word.wordLevel!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _getWordLevelColor(context),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: MediaQuery.of(context).size.height < 700 ? 4 : 6),
                            Text(
                              word.meaning,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.75),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
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
                      _buildDeleteButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ), // Material
    ); // Container
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

  Widget _buildDeleteButton(BuildContext context) {
    return GestureDetector(
      onTap: () => onDelete(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          size: 18,
          color: Colors.red.shade600,
        ),
      ),
    );
  }

  Color _getAccuracyColor(BuildContext context) {
    final accuracy = word.accuracyRate;
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getWordLevelColor(BuildContext context) {
    if (word.wordLevel == null || word.wordLevel!.isEmpty) {
      return Colors.grey;
    }
    // CEFR seviyelerine göre renk kodlama
    final level = word.wordLevel!.toUpperCase();
    switch (level) {
      case 'A1':
        return Colors.blue.shade400;
      case 'A2':
        return Colors.blue.shade600;
      case 'B1':
        return Colors.green.shade500;
      case 'B2':
        return Colors.green.shade700;
      case 'C1':
        return Colors.orange.shade600;
      case 'C2':
        return Colors.red.shade600;
      default:
        return Colors.purple;
    }
  }
}
