import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../../../core/di/injection.dart';

class QuizWidget extends StatefulWidget {
  final VocabularyWord word;
  final Function(bool isCorrect, int responseTimeMs) onAnswerSubmitted;
  final bool practiceMode;

  const QuizWidget({
    super.key,
    required this.word,
    required this.onAnswerSubmitted,
    this.practiceMode = false,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget>
    with TickerProviderStateMixin {
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  DateTime? _startTime;
  late AnimationController _shakeController;
  late AnimationController _resultController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _resultAnimation;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
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
    _shakeController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  void _onAnswerSelected(String answer) {
    if (_showResult) return;

    setState(() {
      _selectedAnswer = answer;
    });

    HapticFeedback.selectionClick();
  }

  void _submitAnswer() {
    if (_selectedAnswer == null || _showResult) return;

    final isCorrect = _selectedAnswer == widget.word.meaning;
    final responseTime = DateTime.now().difference(_startTime!).inMilliseconds;

    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
      _resultController.forward();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward();
    }

    // Delay before submitting
    Future.delayed(const Duration(milliseconds: 1500), () {
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
          // Word card
          Expanded(
            flex: 3,
            child: _buildWordCard(context),
          ),

          const SizedBox(height: 24),

          // Answer options
          Expanded(
            flex: 2,
            child: _buildAnswerOptions(context),
          ),

          const SizedBox(height: 24),

          // Submit button
          _buildSubmitButton(context),
        ],
      ),
    );
  }

  Widget _buildWordCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _showResult
                    ? (_isCorrect ? Colors.green : Colors.red)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: _showResult ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Word
                Text(
                  widget.word.word,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Speak button
                GestureDetector(
                  onTap: _speakWord,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                if (widget.word.exampleSentence != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '"${widget.word.exampleSentence}"',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerOptions(BuildContext context) {
    // Generate wrong answers (simplified)
    final wrongAnswers = [
      'incorrect answer 1',
      'incorrect answer 2',
      'incorrect answer 3',
    ];
    
    final allAnswers = [widget.word.meaning, ...wrongAnswers]..shuffle();

    return Column(
      children: allAnswers.map((answer) {
        final isSelected = _selectedAnswer == answer;
        final isCorrectAnswer = answer == widget.word.meaning;
        final showCorrect = _showResult && isCorrectAnswer;
        final showWrong = _showResult && isSelected && !isCorrectAnswer;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: AnimatedBuilder(
            animation: _resultAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: showCorrect ? _resultAnimation.value : 1.0,
                child: GestureDetector(
                  onTap: () => _onAnswerSelected(answer),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: showCorrect
                          ? Colors.green.withOpacity(0.1)
                          : showWrong
                              ? Colors.red.withOpacity(0.1)
                              : isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: showCorrect
                            ? Colors.green
                            : showWrong
                                ? Colors.red
                                : isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: showCorrect || showWrong || isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: showCorrect
                                ? Colors.green
                                : showWrong
                                    ? Colors.red
                                    : isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: showCorrect
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : showWrong
                                  ? const Icon(Icons.close, color: Colors.white, size: 16)
                                  : isSelected
                                      ? const Icon(Icons.radio_button_checked, color: Colors.white, size: 16)
                                      : const Icon(Icons.radio_button_unchecked, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            answer,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: showCorrect || showWrong
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedAnswer != null && !_showResult ? _submitAnswer : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _showResult
              ? (_isCorrect ? 'Doğru!' : 'Yanlış!')
              : 'Cevabı Gönder',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
