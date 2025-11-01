import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/injection.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/services/tts_service.dart';
import '../../domain/services/quiz_answer_generator.dart';
import '../constants/study_constants.dart';

/// Modern quiz widget with enhanced micro-interactions and smooth animations
class QuizWidgetModern extends StatefulWidget {
  final VocabularyWord word;
  final Function(bool isCorrect, int responseTimeMs) onAnswerSubmitted;
  final bool practiceMode;

  const QuizWidgetModern({
    super.key,
    required this.word,
    required this.onAnswerSubmitted,
    this.practiceMode = false,
  });

  @override
  State<QuizWidgetModern> createState() => _QuizWidgetModernState();
}

class _QuizWidgetModernState extends State<QuizWidgetModern>
    with TickerProviderStateMixin {
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  DateTime? _startTime;
  List<QuizAnswer>? _quizOptions;
  bool _isLoadingOptions = true;
  
  late AnimationController _shakeController;
  late AnimationController _resultController;
  late AnimationController _successController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _resultAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initAnimations();
    _loadQuizOptions();
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      duration: StudyConstants.shakeDuration,
      vsync: this,
    );
    
    _resultController = AnimationController(
      duration: StudyConstants.resultAnimationDuration,
      vsync: this,
    );
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: StudyConstants.shakeAnimationAmplitude,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _resultAnimation = Tween<double>(
      begin: StudyConstants.scaleAnimationBegin,
      end: StudyConstants.scaleAnimationEnd,
    ).animate(CurvedAnimation(
      parent: _resultController,
      curve: Curves.easeOutBack,
    ));
    
    _successAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));
  }

  Future<void> _loadQuizOptions() async {
    try {
      final generator = getIt<QuizAnswerGenerator>();
      final options = await generator.generateQuizOptions(
        widget.word,
        wrongAnswerCount: StudyConstants.wrongAnswerCount,
      );
      
      if (!mounted) return;
      
      setState(() {
        _quizOptions = options;
        _isLoadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      // Fallback to simple options if generation fails
      setState(() {
        _quizOptions = [
          QuizAnswer(text: widget.word.meaning, isCorrect: true),
          QuizAnswer(text: 'Option A', isCorrect: false),
          QuizAnswer(text: 'Option B', isCorrect: false),
          QuizAnswer(text: 'Option C', isCorrect: false),
        ]..shuffle();
        _isLoadingOptions = false;
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _resultController.dispose();
    _successController.dispose();
    super.dispose();
  }

  void _onAnswerSelected(String answer) {
    if (_showResult) return;

    setState(() {
      _selectedAnswer = answer;
    });

    HapticFeedback.selectionClick();
  }

  void _submitAnswer() async {
    if (_selectedAnswer == null || _showResult) return;

    final isCorrect = _quizOptions!
        .firstWhere((opt) => opt.text == _selectedAnswer)
        .isCorrect;
    final responseTime = DateTime.now().difference(_startTime!).inMilliseconds;

    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      _resultController.forward();
      _successController.forward();
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward();
    }

    await Future.delayed(StudyConstants.resultDisplayDelay);
    
    if (mounted) {
      widget.onAnswerSubmitted(isCorrect, responseTime);
    }
  }

  Future<void> _speakWord() async {
    try {
      final ttsService = getIt<TtsService>();
      final result = await ttsService.speak(widget.word.word);
      
      if (result.isFailure && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? StudyConstants.ttsErrorMessage),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      // Fallback: silent fail but log for debugging
      debugPrint('TTS error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOptions) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 600;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(StudyConstants.contentPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Modern word card
                  Flexible(
                    flex: isCompactHeight ? 2 : 3,
                    child: _buildModernWordCard(context),
                  ),

                  SizedBox(height: isCompactHeight ? 12 : 20),

                  // Answer options
                  Flexible(
                    flex: 2,
                    child: _buildModernAnswerOptions(context),
                  ),

                  SizedBox(height: isCompactHeight ? 12 : 20),

                  // Submit button
                  _buildModernSubmitButton(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernWordCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _showResult
                    ? (_isCorrect
                        ? [Colors.green.shade50, Colors.green.shade100]
                        : [Colors.red.shade50, Colors.red.shade100])
                    : [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      ],
              ),
              borderRadius: BorderRadius.circular(StudyConstants.cardBorderRadius),
              border: Border.all(
                color: _showResult
                    ? (_isCorrect ? Colors.green : Colors.red)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.15),
                width: _showResult ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _showResult
                      ? (_isCorrect ? Colors.green : Colors.red).withOpacity(0.2)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: _showResult ? 20 : 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Word display
                AnimatedBuilder(
                  animation: _successAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (0.1 * _successAnimation.value),
                      child: Text(
                        widget.word.word,
                        style: TextStyle(
                          fontSize: StudyConstants.wordFontSize,
                          fontWeight: FontWeight.w900,
                          letterSpacing: StudyConstants.wordLetterSpacing,
                          color: _showResult
                              ? (_isCorrect ? Colors.green.shade700 : Colors.red.shade700)
                              : Theme.of(context).textTheme.headlineLarge?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Speak button with glassmorphic design
                GestureDetector(
                  onTap: _speakWord,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          Theme.of(context).colorScheme.primary.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 28,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                // Example sentence with fade-in
                if (widget.word.exampleSentence != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '"${widget.word.exampleSentence}"',
                      style: TextStyle(
                        fontSize: StudyConstants.exampleFontSize,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.75),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                // Result badge
                if (_showResult) ...[
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _resultAnimation,
                    builder: (context, child) {
                      final clampedValue = _resultAnimation.value.clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: clampedValue,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isCorrect
                                  ? [Colors.green, Colors.green.shade600]
                                  : [Colors.red, Colors.red.shade600],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (_isCorrect ? Colors.green : Colors.red).withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isCorrect ? StudyConstants.correctAnswerMessage : StudyConstants.wrongAnswerMessage,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernAnswerOptions(BuildContext context) {
    if (_quizOptions == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: _quizOptions!.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final answer = option.text;
        final isSelected = _selectedAnswer == answer;
        final isCorrectAnswer = option.isCorrect;
        final showCorrect = _showResult && isCorrectAnswer;
        final showWrong = _showResult && isSelected && !isCorrectAnswer;

        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 300 + (index * 100)),
          tween: Tween(begin: 0, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, animValue, child) {
            return Opacity(
              opacity: animValue,
              child: Transform.translate(
                offset: Offset(30 * (1 - animValue), 0),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildAnswerOption(
                    context,
                    answer,
                    isSelected,
                    showCorrect,
                    showWrong,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildAnswerOption(
    BuildContext context,
    String answer,
    bool isSelected,
    bool showCorrect,
    bool showWrong,
  ) {
    final backgroundColor = showCorrect
        ? Colors.green.withOpacity(0.15)
        : showWrong
            ? Colors.red.withOpacity(0.15)
            : isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                : Theme.of(context).colorScheme.surface;

    final borderColor = showCorrect
        ? Colors.green
        : showWrong
            ? Colors.red
            : isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.15);

    return AnimatedBuilder(
      animation: _resultAnimation,
      builder: (context, child) {
        final scale = showCorrect ? (1.0 + (0.05 * _resultAnimation.value.clamp(0.0, 1.0))) : 1.0;
        
        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () => _onAnswerSelected(answer),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: borderColor,
                  width: (showCorrect || showWrong || isSelected) ? 2.5 : 1.5,
                ),
                boxShadow: (showCorrect || showWrong || isSelected)
                    ? [
                        BoxShadow(
                          color: borderColor.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Radio icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      gradient: (showCorrect || showWrong || isSelected)
                          ? LinearGradient(
                              colors: showCorrect
                                  ? [Colors.green, Colors.green.shade600]
                                  : showWrong
                                      ? [Colors.red, Colors.red.shade600]
                                      : [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(context).colorScheme.primary.withBlue(200),
                                        ],
                            )
                          : null,
                      color: !(showCorrect || showWrong || isSelected)
                          ? Theme.of(context).colorScheme.outline.withOpacity(0.2)
                          : null,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      showCorrect
                          ? Icons.check_rounded
                          : showWrong
                              ? Icons.close_rounded
                              : isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                      color: (showCorrect || showWrong || isSelected)
                          ? Colors.white
                          : Theme.of(context).colorScheme.outline.withOpacity(0.4),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Answer text
                  Expanded(
                    child: Text(
                      answer,
                      style: TextStyle(
                        fontSize: StudyConstants.answerOptionFontSize,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: showCorrect || showWrong
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  // Success checkmark animation
                  if (showCorrect) ...[
                    AnimatedBuilder(
                      animation: _successAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _successAnimation.value,
                          child: Icon(
                            Icons.verified_rounded,
                            color: Colors.green.shade600,
                            size: 24,
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernSubmitButton(BuildContext context) {
    final canSubmit = _selectedAnswer != null && !_showResult;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      child: FilledButton(
        onPressed: canSubmit ? _submitAnswer : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
          ),
          disabledBackgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          disabledForegroundColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
          elevation: canSubmit ? 8 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_showResult)
              Icon(
                _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 22,
              ),
            if (_showResult) const SizedBox(width: 8),
            Text(
              _showResult
                  ? (_isCorrect ? StudyConstants.correctAnswerMessage : StudyConstants.wrongAnswerMessage)
                  : StudyConstants.submitAnswerLabel,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

