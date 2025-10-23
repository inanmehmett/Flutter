import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../../../core/di/injection.dart';

class FlashcardWidget extends StatefulWidget {
  final VocabularyWord word;
  final Function(bool isCorrect, int responseTimeMs) onAnswerSubmitted;

  const FlashcardWidget({
    super.key,
    required this.word,
    required this.onAnswerSubmitted,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with TickerProviderStateMixin {
  bool _isFlipped = false;
  bool _showAnswer = false;
  DateTime? _startTime;
  late AnimationController _flipController;
  late AnimationController _resultController;
  late Animation<double> _flipAnimation;
  late Animation<double> _resultAnimation;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOut,
    ));

    _resultAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _flipController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_showAnswer) return;

    HapticFeedback.lightImpact();
    _flipController.forward().then((_) {
      setState(() {
        _isFlipped = !_isFlipped;
      });
      _flipController.reverse();
    });
  }

  void _submitAnswer(bool isCorrect) {
    if (_showAnswer) return;

    final responseTime = DateTime.now().difference(_startTime!).inMilliseconds;

    setState(() {
      _showAnswer = true;
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    _resultController.forward();

    // Delay before submitting
    Future.delayed(const Duration(milliseconds: 2000), () {
      widget.onAnswerSubmitted(isCorrect, responseTime);
    });
  }

  void _speakWord() async {
    try {
      final tts = getIt<FlutterTts>();
      await tts.stop();
      await tts.setLanguage('en-US');
      await tts.speak(widget.word.word);
    } catch (e) {
      // Handle TTS error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Flashcard
          Expanded(
            flex: 4,
            child: _buildFlashcard(context),
          ),

          const SizedBox(height: 24),

          // Action buttons
          if (!_showAnswer) ...[
            Expanded(
              flex: 1,
              child: _buildActionButtons(context),
            ),
          ] else ...[
            Expanded(
              flex: 1,
              child: _buildResultButtons(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlashcard(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _flipAnimation,
        builder: (context, child) {
          final isShowingFront = _flipAnimation.value < 0.5;
          final frontScale = isShowingFront ? 1.0 : 0.0;
          final backScale = isShowingFront ? 0.0 : 1.0;

          return Stack(
            children: [
              // Front side
              Transform.scale(
                scale: frontScale,
                child: Opacity(
                  opacity: frontScale,
                  child: _buildCardSide(
                    context,
                    isFront: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Word
                        Text(
                          widget.word.word,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 24),

                        // Speak button
                        GestureDetector(
                          onTap: _speakWord,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.volume_up_rounded,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Tap to flip hint
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Anlamını görmek için dokun',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Back side
              Transform.scale(
                scale: backScale,
                child: Opacity(
                  opacity: backScale,
                  child: _buildCardSide(
                    context,
                    isFront: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Meaning
                        Text(
                          widget.word.meaning,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (widget.word.exampleSentence != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '"${widget.word.exampleSentence}"',
                              style: TextStyle(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Tap to flip back hint
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Kelimeyi görmek için dokun',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCardSide(
    BuildContext context, {
    required bool isFront,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFront
              ? [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ]
              : [
                  Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _submitAnswer(false),
            icon: const Icon(Icons.close),
            label: const Text('Bilmiyorum'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _submitAnswer(true),
            icon: const Icon(Icons.check),
            label: const Text('Biliyorum'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultButtons(BuildContext context) {
    return AnimatedBuilder(
      animation: _resultAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _resultAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Colors.green,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sonraki kelimeye geçiliyor...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
