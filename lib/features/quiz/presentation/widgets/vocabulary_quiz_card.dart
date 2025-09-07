import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../domain/entities/vocabulary_quiz_models.dart';

class VocabularyQuizCard extends StatefulWidget {
  final VocabularyQuizQuestion question;
  final Function(String) onAnswerSelected;
  final bool isAnswered;
  final String? selectedAnswer;
  final bool? isCorrect;
  final int timeRemaining;
  final VoidCallback? onNextQuestion;
  final bool isLastQuestion;

  const VocabularyQuizCard({
    super.key,
    required this.question,
    required this.onAnswerSelected,
    this.isAnswered = false,
    this.selectedAnswer,
    this.isCorrect,
    required this.timeRemaining,
    this.onNextQuestion,
    this.isLastQuestion = false,
  });

  @override
  State<VocabularyQuizCard> createState() => _VocabularyQuizCardState();
}

class _VocabularyQuizCardState extends State<VocabularyQuizCard>
    with TickerProviderStateMixin {
  late AnimationController _cardAnimationController;
  late AnimationController _optionAnimationController;
  late Animation<double> _cardScaleAnimation;
  late Animation<double> _optionSlideAnimation;
  Timer? _timer;
  int _currentTimeRemaining = 0;

  @override
  void initState() {
    super.initState();
    
    _currentTimeRemaining = widget.timeRemaining;
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _optionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _cardScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.elasticOut,
    ));

    _optionSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _optionAnimationController,
      curve: Curves.easeOut,
    ));

    _cardAnimationController.forward();
    _optionAnimationController.forward();
    
    // Start timer if not answered
    if (!widget.isAnswered) {
      _startTimer();
    }
  }

  @override
  void didUpdateWidget(VocabularyQuizCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Eğer soru değiştiyse timer'ı reset et
    if (widget.question.id != oldWidget.question.id) {
      _currentTimeRemaining = widget.timeRemaining;
      if (!widget.isAnswered) {
        _startTimer();
      }
    } else {
      // Update timer if time remaining changed
      if (widget.timeRemaining != oldWidget.timeRemaining) {
        _currentTimeRemaining = widget.timeRemaining;
      }
    }
    
    // Start timer if question changed and not answered
    if (!widget.isAnswered && oldWidget.isAnswered) {
      _startTimer();
    } else if (widget.isAnswered && !oldWidget.isAnswered) {
      _stopTimer();
    }
  }

  void _startTimer() {
    _stopTimer(); // Stop any existing timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentTimeRemaining > 0) {
        setState(() {
          _currentTimeRemaining--;
        });
      } else {
        _stopTimer();
        // Auto-answer with wrong answer when time runs out
        if (!widget.isAnswered) {
          final wrongAnswer = widget.question.options.firstWhere((opt) => !opt.isCorrect).text;
          widget.onAnswerSelected(wrongAnswer);
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopTimer();
    _cardAnimationController.dispose();
    _optionAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _cardScaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade400,
                  Colors.purple.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question header
                    _buildQuestionHeader(),
                    const SizedBox(height: 16),
                    
                    // Question text
                    _buildQuestionText(),
                    const SizedBox(height: 20),
                    
                    // Answer options
                    _buildAnswerOptions(),
                    
                    // Next button (only when answered)
                    if (widget.isAnswered) ...[
                      const SizedBox(height: 20),
                      _buildNextButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Difficulty badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getDifficultyText(widget.question.difficulty),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Timer
        _buildTimer(),
      ],
    );
  }

  Widget _buildTimer() {
    final isUrgent = _currentTimeRemaining <= 5;
    final color = isUrgent ? Colors.red : Colors.white;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${_currentTimeRemaining}s',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kelime Çevirisi',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "'${widget.question.originalWord}' kelimesinin Türkçe karşılığı nedir?",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerOptions() {
    return AnimatedBuilder(
      animation: _optionSlideAnimation,
      builder: (context, child) {
        return Column(
          children: widget.question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = widget.selectedAnswer == option.text;
            
            return Transform.translate(
              offset: Offset(0, _optionSlideAnimation.value * (index + 1)),
              child: _buildAnswerOption(option, isSelected),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAnswerOption(VocabularyQuizOption option, bool isSelected) {
    Color backgroundColor = Colors.white.withOpacity(0.1);
    Color borderColor = Colors.white.withOpacity(0.2);
    Color textColor = Colors.white;
    
    if (widget.isAnswered) {
      if (option.isCorrect) {
        backgroundColor = Colors.green.withOpacity(0.3);
        borderColor = Colors.green;
        textColor = Colors.white;
      } else if (isSelected && !option.isCorrect) {
        backgroundColor = Colors.red.withOpacity(0.3);
        borderColor = Colors.red;
        textColor = Colors.white;
      }
    } else if (isSelected) {
      backgroundColor = Colors.white.withOpacity(0.2);
      borderColor = Colors.white.withOpacity(0.5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.isAnswered ? null : () => _selectAnswer(option.text),
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: Row(
              children: [
                // Option indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + widget.question.options.indexOf(option)),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Option text
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Correct/Incorrect indicator
                if (widget.isAnswered && option.isCorrect)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  )
                else if (widget.isAnswered && isSelected && !option.isCorrect)
                  const Icon(
                    Icons.cancel,
                    color: Colors.red,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _selectAnswer(String answer) {
    HapticFeedback.lightImpact();
    widget.onAnswerSelected(answer);
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: widget.onNextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.isCorrect == true ? Colors.green : Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
        child: Text(
          widget.isLastQuestion ? 'Sonuçları Gör' : 'Sonraki Soru',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getDifficultyText(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
      case 'easy':
        return 'Kolay';
      case 'intermediate':
      case 'medium':
        return 'Orta';
      case 'advanced':
      case 'hard':
        return 'Zor';
      default:
        return 'Orta';
    }
  }
}
