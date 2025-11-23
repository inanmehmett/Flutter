import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../../../core/di/injection.dart';
import '../../domain/services/tts_service.dart';
import '../constants/study_constants.dart';

/// Practice widget with typing input, hints, and multiple attempts
class PracticeWidget extends StatefulWidget {
  final VocabularyWord word;
  final Function(bool isCorrect, int responseTimeMs) onAnswerSubmitted;
  final int maxAttempts;

  const PracticeWidget({
    super.key,
    required this.word,
    required this.onAnswerSubmitted,
    this.maxAttempts = 2,
  });

  @override
  State<PracticeWidget> createState() => _PracticeWidgetState();
}

class _PracticeWidgetState extends State<PracticeWidget>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _speakButtonKey = GlobalKey();
  
  int _currentAttempt = 0;
  String? _currentHint;
  bool _showResult = false;
  bool _isCorrect = false;
  DateTime? _startTime;
  
  late AnimationController _shakeController;
  late AnimationController _hintController;
  late AnimationController _successController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _hintAnimation;
  late Animation<double> _successAnimation;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _initAnimations();

    // Klavye açıldığında scroll yap
    _focusNode.addListener(_onFocusChange);

    // Auto-focus input field ve kelimeyi otomatik seslendir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _speakWord();
    });
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && mounted) {
      // Klavye açıldığında ses butonunu görünür hale getir
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _focusNode.hasFocus) {
          _scrollToSpeakButton();
        }
      });
    }
  }

  void _scrollToSpeakButton() {
    if (!mounted || !_scrollController.hasClients) return;
    final buttonContext = _speakButtonKey.currentContext;
    if (buttonContext == null) return;
    
    try {
      final box = buttonContext.findRenderObject() as RenderBox?;
      if (box == null) return;
      
      // Ses butonunun pozisyonunu al
      final position = box.localToGlobal(Offset.zero);
      
      // Build context'ten MediaQuery al
      final buildContext = context;
      final mediaQuery = MediaQuery.of(buildContext);
      final screenHeight = mediaQuery.size.height;
      final keyboardHeight = mediaQuery.viewInsets.bottom;
      final availableHeight = screenHeight - keyboardHeight;
      
      // Ses butonu görünür alanın dışındaysa scroll yap
      if (position.dy > availableHeight - 150) {
        final targetPosition = _scrollController.offset + (position.dy - availableHeight + 150);
        _scrollController.animateTo(
          targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      // Scroll hatası olursa sessizce devam et
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _shakeController.dispose();
    _hintController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PracticeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state when word changes
    if (oldWidget.word.id != widget.word.id) {
      setState(() {
        _controller.clear();
        _currentAttempt = 0;
        _currentHint = null;
        _showResult = false;
        _isCorrect = false;
        _startTime = DateTime.now();
      });
      _shakeController.reset();
      _hintController.reset();
      _successController.reset();
      // Refocus input ve yeni kelimeyi otomatik seslendir
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
        _speakWord();
      });
    }
  }

  void _initAnimations() {
    _shakeController = AnimationController(
      duration: StudyConstants.shakeDuration,
      vsync: this,
    );
    
    _hintController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: StudyConstants.shakeAnimationAmplitude,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _hintAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hintController,
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

  void _submitAnswer() async {
    if (_showResult) return;

    final userAnswer = _controller.text.trim().toLowerCase();
    // Pratik modunda kullanıcıdan duyduğu İngilizce kelimeyi yazması beklenir.
    // Bu yüzden cevabı kelimenin kendisiyle (word) karşılaştırıyoruz.
    final correctAnswer = widget.word.word.toLowerCase();
    final isCorrect = userAnswer == correctAnswer || _isSimilar(userAnswer, correctAnswer);
    final responseTime = DateTime.now().difference(_startTime!).inMilliseconds;

    if (isCorrect) {
      // Correct answer!
      setState(() {
        _showResult = true;
        _isCorrect = true;
      });
      
      HapticFeedback.mediumImpact();
      _successController.forward();
      
      await Future.delayed(StudyConstants.resultDisplayDelay);
      
      if (mounted) {
        widget.onAnswerSubmitted(true, responseTime);
      }
    } else {
      // Wrong answer
      _currentAttempt++;
      
      if (_currentAttempt < widget.maxAttempts) {
        // Show hint and allow retry
        _showHint(_currentAttempt);
        _showRetryFeedback();
      } else {
        // Failed after max attempts
        setState(() {
          _showResult = true;
          _isCorrect = false;
        });
        
        HapticFeedback.heavyImpact();
        _shakeController.forward();
        
        await Future.delayed(StudyConstants.resultDisplayDelay);
        
        if (mounted) {
          widget.onAnswerSubmitted(false, responseTime);
        }
      }
    }
  }

  bool _isSimilar(String answer, String correct) {
    // Allow minor typos (Levenshtein distance <= 1)
    if (answer.length != correct.length) return false;
    
    int differences = 0;
    for (int i = 0; i < answer.length; i++) {
      if (answer[i] != correct[i]) {
        differences++;
        if (differences > 1) return false;
      }
    }
    
    return differences <= 1;
  }

  void _showHint(int attemptNumber) {
    final hints = _generateHints();
    
    if (attemptNumber <= hints.length) {
      setState(() {
        _currentHint = hints[attemptNumber - 1];
      });
      _hintController.forward(from: 0.0);
      HapticFeedback.lightImpact();
    }
  }

  List<String> _generateHints() {
    final hints = <String>[];
    
    // Hint 1: İlk harf (İngilizce kelime)
    if (widget.word.word.isNotEmpty) {
      hints.add('İlk harf: ${widget.word.word[0].toUpperCase()}...');
    }
    
    // Hint 2: Eş anlamlı veya uzunluk bilgisi
    if (widget.word.synonyms.isNotEmpty) {
      hints.add('Eş anlamlısı: ${widget.word.synonyms.first}');
    } else {
      hints.add('Uzunluk: ${widget.word.word.length} harf');
    }
    
    // Hint 3: Kelimenin bir kısmını göster
    if (widget.word.word.length > 3) {
      final revealed = widget.word.word.substring(0, (widget.word.word.length / 2).round());
      final hidden = '_' * (widget.word.word.length - revealed.length);
      hints.add('$revealed$hidden');
    }
    
    return hints;
  }

  void _showRetryFeedback() {
    HapticFeedback.mediumImpact();
    _shakeController.forward(from: 0.0).then((_) {
      _shakeController.reverse();
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yanlış! ${widget.maxAttempts - _currentAttempt} deneme hakkınız kaldı.'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _speakWord() async {
    try {
      final ttsService = getIt<TtsService>();
      // Pratik modunda kelimeyi biraz daha yavaş (yaklaşık %10) seslendir
      await ttsService.setSpeechRate(0.45);
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
      debugPrint('TTS error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 600;
        
        return SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(isCompactHeight ? StudyConstants.contentPadding * 0.75 : StudyConstants.contentPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Word card
              _buildWordCard(context),

              SizedBox(height: isCompactHeight ? 12 : 20),

              // Hint card (if available)
              if (_currentHint != null) ...[
                _buildHintCard(context),
                SizedBox(height: isCompactHeight ? 12 : 16),
              ],

              // Ses butonu - input field'ın hemen üstünde
              _buildSpeakButton(context),

              SizedBox(height: isCompactHeight ? 12 : 16),

              // Typing input
              _buildTypingInput(context),

              SizedBox(height: isCompactHeight ? 12 : 16),

              // Attempts indicator
              _buildAttemptsIndicator(context),

              SizedBox(height: isCompactHeight ? 16 : 20),

              // Submit button
              _buildSubmitButton(context),
              
              // Extra bottom padding for safe scrolling
              SizedBox(height: isCompactHeight ? 8 : 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWordCard(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 600;
        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value, 0),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(isCompactHeight ? 20 : 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _showResult
                        ? (_isCorrect
                            ? [Colors.green.shade50, Colors.green.shade100]
                            : [Colors.red.shade50, Colors.red.shade100])
                        : [
                            Colors.green.shade50,
                            Colors.teal.shade50,
                          ],
                  ),
                  borderRadius: BorderRadius.circular(StudyConstants.cardBorderRadius),
                  border: Border.all(
                    color: _showResult
                        ? (_isCorrect ? Colors.green : Colors.red)
                        : Colors.green.withOpacity(0.3),
                    width: _showResult ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_showResult
                          ? (_isCorrect ? Colors.green : Colors.red)
                          : Colors.green).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Instruction text instead of showing the word itself
                    AnimatedBuilder(
                      animation: _successAnimation,
                      builder: (context, child) {
                        final clampedValue = _successAnimation.value.clamp(0.0, 1.0);
                        return Transform.scale(
                          scale: 1.0 + (0.04 * clampedValue),
                          child: Text(
                            'Kelimeyi dinleyin ve yazın',
                            style: TextStyle(
                              fontSize: StudyConstants.exampleFontSize + 2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: _showResult
                                  ? (_isCorrect ? Colors.green.shade700 : Colors.red.shade700)
                                  : Colors.green.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),

                    SizedBox(height: isCompactHeight ? 16 : 20),

                    // Example sentence
                    if (widget.word.exampleSentence != null) ...[
                      SizedBox(height: isCompactHeight ? 16 : 20),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompactHeight ? 14 : 18,
                          vertical: isCompactHeight ? 12 : 14,
                        ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isCorrect ? StudyConstants.correctAnswerMessage : 'Doğru cevap:',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            if (!_isCorrect) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.word.word,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHintCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _hintAnimation,
      builder: (context, child) {
        final clampedValue = _hintAnimation.value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: clampedValue,
          child: Opacity(
            opacity: clampedValue,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.amber.shade100,
                    Colors.amber.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.amber.shade400,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    color: Colors.amber.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentHint!,
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeakButton(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 600;
        return Container(
          key: _speakButtonKey,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: _speakWord,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompactHeight ? 20 : 24,
                vertical: isCompactHeight ? 12 : 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.withOpacity(0.2),
                    Colors.green.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    size: isCompactHeight ? 24 : 28,
                    color: Colors.green,
                  ),
                  SizedBox(width: isCompactHeight ? 8 : 12),
                  Text(
                    'Tekrar Dinle',
                    style: TextStyle(
                      fontSize: isCompactHeight ? 14 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _showResult
              ? (_isCorrect ? Colors.green : Colors.red)
              : Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: !_showResult,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        decoration: InputDecoration(
          // Kullanıcıdan duyduğu İngilizce kelimeyi yazması istenir.
          hintText: 'Duyduğunuz kelimeyi yazın...',
          hintStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        onSubmitted: (_) => _submitAnswer(),
      ),
    );
  }

  Widget _buildAttemptsIndicator(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Deneme Hakkı: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 8),
        ...List.generate(widget.maxAttempts, (index) {
          final isUsed = index < _currentAttempt;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isUsed ? Icons.favorite : Icons.favorite_border,
                color: isUsed ? Colors.grey.shade400 : Colors.red,
                size: 24,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final canSubmit = _controller.text.trim().isNotEmpty && !_showResult;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      child: FilledButton(
        onPressed: canSubmit ? _submitAnswer : null,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.green,
          disabledBackgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          disabledForegroundColor: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4),
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
          ),
          elevation: canSubmit ? 4 : 0,
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
                  : 'Kontrol Et',
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

