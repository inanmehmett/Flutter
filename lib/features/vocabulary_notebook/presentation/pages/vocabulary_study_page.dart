import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../bloc/vocabulary_bloc.dart';
import '../bloc/vocabulary_event.dart';
import '../bloc/vocabulary_state.dart';
import '../../domain/services/review_session.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/study_mode.dart';
import '../widgets/quiz_widget.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/practice_widget.dart';
import '../widgets/quiz_score_display.dart';
import '../constants/study_constants.dart';

/// Modern, beautiful study page with glassmorphism and micro-interactions
class VocabularyStudyPage extends StatefulWidget {
  const VocabularyStudyPage({super.key});

  @override
  State<VocabularyStudyPage> createState() => _VocabularyStudyPageState();
}

class _VocabularyStudyPageState extends State<VocabularyStudyPage>
    with TickerProviderStateMixin {
  StudyMode _currentMode = StudyMode.study;
  ReviewSession? _currentSession;
  int _currentWordIndex = 0;
  bool _sessionCompleted = false;
  
  late AnimationController _progressController;
  late AnimationController _cardController;
  late AnimationController _headerController;
  late Animation<double> _cardAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadStudySession();
  }

  void _initAnimations() {
    _progressController = AnimationController(
      duration: StudyConstants.progressAnimationDuration,
      vsync: this,
    );
    
    _cardController = AnimationController(
      duration: StudyConstants.cardEntranceDuration,
      vsync: this,
    );
    
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardAnimation = Tween<double>(
      begin: StudyConstants.scaleAnimationBegin,
      end: StudyConstants.scaleAnimationEnd,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.elasticOut,
    ));
    
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));
    
    _headerController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _cardController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  void _loadStudySession() {
    // Filter words based on study mode
    final filter = switch (_currentMode) {
      StudyMode.study => 'due',          // Due words priority (SRS)
      StudyMode.practice => 'difficult', // Difficult words only
      StudyMode.flashcards => null,      // Random batch
    };
    
    context.read<VocabularyBloc>().add(StartReviewSession(modeFilter: filter));
  }

  void _onModeChanged(StudyMode mode) {
    if (_currentMode == mode) return;
    
    setState(() {
      _currentMode = mode;
      _currentWordIndex = 0;
      _sessionCompleted = false;
      _currentSession = null;
    });
    
    HapticFeedback.mediumImpact();
    
    // Reload session with new filter
    _loadStudySession();
  }

  void _onAnswerSubmitted(bool isCorrect, int responseTimeMs) {
    if (_currentSession == null) return;

    final currentWord = _currentSession!.words[_currentWordIndex];
    _currentSession!.addResult(ReviewResult(
      wordId: currentWord.id.toString(),
      isCorrect: isCorrect,
      responseTimeMs: responseTimeMs,
      completedAt: DateTime.now(),
    ));

    _progressController.forward(from: 0);

    if (_currentWordIndex < _currentSession!.words.length - 1) {
      setState(() {
        _currentWordIndex++;
      });
      _cardController.reset();
      _cardController.forward();
    } else {
      _completeSession();
    }
  }

  void _completeSession() {
    if (_currentSession == null) return;

    _currentSession!.complete();
    context.read<VocabularyBloc>().add(
      CompleteReviewSession(session: _currentSession!),
    );

    setState(() {
      _sessionCompleted = true;
    });

    HapticFeedback.heavyImpact();
  }

  void _restartSession() {
    setState(() {
      _currentWordIndex = 0;
      _sessionCompleted = false;
      _currentSession = null;
    });
    _loadStudySession();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final clampedScale = math.min(mq.textScaleFactor, 1.2);
    
    return MediaQuery(
      data: mq.copyWith(textScaleFactor: clampedScale),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildModernAppBar(context),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.03),
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.background,
              ],
            ),
          ),
          child: BlocConsumer<VocabularyBloc, VocabularyState>(
            listener: (context, state) {
              if (state is ReviewSessionLoaded) {
                setState(() {
                  _currentSession = state.session;
                });
                _cardController.forward();
              }
            },
            builder: (context, state) {
              if (state is VocabularyLoading) {
                return _buildModernLoading(context);
              }

              if (state is VocabularyError) {
                return _buildModernError(context, state.message);
              }

              if (_currentSession == null || _currentSession!.words.isEmpty) {
                return _buildModernEmptyState(context);
              }

              return _sessionCompleted
                  ? _buildModernSessionComplete(context)
                  : _buildModernStudyContent(context);
            },
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.close_rounded, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!_sessionCompleted && _currentSession != null)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.refresh_rounded, size: 20),
            ),
            onPressed: _restartSession,
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildModernLoading(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Oturum hazırlanıyor...',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelimeleriniz yükleniyor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Bir şeyler ters gitti',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            FilledButton.icon(
              onPressed: _loadStudySession,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(StudyConstants.tryAgainLabel),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Modern empty state illustration with particle effect
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.15),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.celebration_outlined,
                      size: 90,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              'Harika İş!',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bugün için çalışacak kelime kalmadı.\nYeni kelimeler ekleyin veya yarın tekrar gelin.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(StudyConstants.goBackLabel),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStudyContent(BuildContext context) {
    final currentWord = _currentSession!.words[_currentWordIndex];
    final progress = (_currentWordIndex + 1) / _currentSession!.words.length;

    return SafeArea(
      child: Column(
        children: [
          // Modern Header with glassmorphism
          SlideTransition(
            position: _headerSlideAnimation,
            child: _buildGlassmorphicHeader(context, progress),
          ),

          // Study Mode Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildModernModeSelector(context),
          ),

          const SizedBox(height: 16),

          // Study content with smooth animation
          Expanded(
            child: AnimatedBuilder(
              animation: _cardAnimation,
              builder: (context, child) {
                final clampedValue = _cardAnimation.value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: clampedValue,
                  child: Opacity(
                    opacity: clampedValue,
                    child: _buildStudyWidget(context, currentWord),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassmorphicHeader(BuildContext context, double progress) {
    final currentIndex = _currentWordIndex + 1;
    final totalWords = _currentSession!.totalWords;
    final estimatedMinutes = (totalWords * 15 / 60).round().clamp(1, 60);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withBlue(220).withGreen(180),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Title row with icon and stats
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Çalışma Oturumu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$totalWords kelime · ~$estimatedMinutes dk',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Circular progress indicator
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    // Background circle
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    // Animated progress circle
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0, end: progress),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 5,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        );
                      },
                    ),
                    // Percentage text
                    Center(
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 18),
          
          // Linear progress bar with gradient
          Stack(
            children: [
              // Background
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Animated progress
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 600),
                tween: Tween(begin: 0, end: progress),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Colors.white70],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          // Word counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kelime ${currentIndex}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$currentIndex / $totalWords',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernModeSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildModeChip(context, StudyMode.study, Icons.school_rounded, 'Çalış'),
          _buildModeChip(context, StudyMode.practice, Icons.fitness_center_rounded, 'Pratik'),
          _buildModeChip(context, StudyMode.flashcards, Icons.style_rounded, 'Kart'),
        ],
      ),
    );
  }

  Widget _buildModeChip(BuildContext context, StudyMode mode, IconData icon, String label) {
    final isSelected = _currentMode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withBlue(200),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  letterSpacing: 0.3,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyWidget(BuildContext context, VocabularyWord word) {
    switch (_currentMode) {
      case StudyMode.study:
        return QuizWidget(
          word: word,
          onAnswerSubmitted: _onAnswerSubmitted,
          showTimer: false,  // Rahat tempo, timer yok
          compact: true,     // Compact layout
        );
      case StudyMode.practice:
        return PracticeWidget(
          word: word,
          onAnswerSubmitted: _onAnswerSubmitted,
          maxAttempts: 2,
        );
      case StudyMode.flashcards:
        return FlashcardWidget(
          word: word,
          onAnswerSubmitted: _onAnswerSubmitted,
        );
    }
  }

  Widget _buildModernSessionComplete(BuildContext context) {
    final stats = _currentSession!;
    final accuracy = stats.accuracyRate;
    final duration = stats.duration;
    final isExcellent = accuracy >= 0.9;
    final isGood = accuracy >= 0.7;
    final isPerfect = accuracy == 1.0;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated success icon with particle effect
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (isExcellent ? Colors.amber : (isGood ? Colors.green : Colors.blue))
                                  .withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Main icon
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isPerfect
                                ? [Colors.amber.shade400, Colors.deepOrange.shade400]
                                : isExcellent
                                    ? [Colors.green.shade400, Colors.teal.shade400]
                                    : isGood
                                        ? [Colors.blue.shade400, Colors.indigo.shade400]
                                        : [Colors.purple.shade400, Colors.pink.shade400],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isPerfect ? Colors.amber : (isExcellent ? Colors.green : (isGood ? Colors.blue : Colors.purple)))
                                  .withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPerfect ? Icons.stars_rounded : (isExcellent ? Icons.emoji_events_rounded : Icons.check_circle_rounded),
                          size: 75,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 36),

            // Animated title
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Column(
                      children: [
                        Text(
                          isPerfect ? 'Mükemmel! 🎉' : (isExcellent ? 'Harika! ⭐' : (isGood ? 'Aferin! 👏' : 'Tamamlandı! ✓')),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: isPerfect
                                ? Colors.amber.shade700
                                : isExcellent
                                    ? Colors.green.shade700
                                    : isGood
                                        ? Colors.blue.shade700
                                        : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Çalışma oturumunu başarıyla tamamladınız',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 44),

            // Modern stats grid
            _buildModernStatsGrid(context, stats, accuracy, duration),

            const SizedBox(height: 44),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _restartSession,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tekrar Çalış'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Ana Sayfa'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatsGrid(BuildContext context, ReviewSession stats, double accuracy, Duration duration) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildGlassStatCard(
                context,
                icon: Icons.insights_rounded,
                label: 'Doğruluk',
                value: '${(accuracy * 100).toInt()}%',
                color: accuracy >= 0.8 ? Colors.green : (accuracy >= 0.6 ? Colors.orange : Colors.red),
                delay: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassStatCard(
                context,
                icon: Icons.timer_outlined,
                label: 'Süre',
                value: '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                color: Colors.blue,
                delay: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGlassStatCard(
                context,
                icon: Icons.check_circle_rounded,
                label: 'Doğru',
                value: '${stats.correctAnswers}',
                color: Colors.green,
                delay: 200,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGlassStatCard(
                context,
                icon: Icons.cancel_rounded,
                label: 'Yanlış',
                value: '${stats.completedWords - stats.correctAnswers}',
                color: Colors.red,
                delay: 300,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassStatCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int delay,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animValue)),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(icon, color: color, size: 36),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
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
}
