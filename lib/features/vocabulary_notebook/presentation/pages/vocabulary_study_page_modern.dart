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
import '../constants/study_constants.dart';

/// Modern, beautiful study page with glassmorphism and micro-interactions
class VocabularyStudyPageModern extends StatefulWidget {
  const VocabularyStudyPageModern({super.key});

  @override
  State<VocabularyStudyPageModern> createState() => _VocabularyStudyPageModernState();
}

class _VocabularyStudyPageModernState extends State<VocabularyStudyPageModern>
    with TickerProviderStateMixin {
  StudyMode _currentMode = StudyMode.review;
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
    context.read<VocabularyBloc>().add(StartReviewSession());
  }

  void _onModeChanged(StudyMode mode) {
    if (_currentMode == mode) return;
    setState(() {
      _currentMode = mode;
    });
    HapticFeedback.mediumImpact();
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
    return Scaffold(
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
          child: const Icon(Icons.close, size: 20),
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
              child: const Icon(Icons.refresh, size: 20),
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
                width: 80,
                height: 80,
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
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Oturum hazırlanıyor...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bir şeyler ters gitti',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadStudySession,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(StudyConstants.tryAgainLabel),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
            // Modern empty state illustration
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
              ),
              child: Icon(
                Icons.celebration_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Harika İş!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bugün için çalışacak kelime kalmadı.\nYeni kelimeler ekleyin veya yarın tekrar gelin.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text(StudyConstants.goBackLabel),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
          // Modern Header
          SlideTransition(
            position: _headerSlideAnimation,
            child: _buildModernHeader(context, progress),
          ),

          // Study Mode Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildModernModeSelector(context),
          ),

          const SizedBox(height: 16),

          // Study content with animation
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

  Widget _buildModernHeader(BuildContext context, double progress) {
    final currentIndex = _currentWordIndex + 1;
    final totalWords = _currentSession!.totalWords;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withBlue(200),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title and progress
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Çalışma Modu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$currentIndex / $totalWords kelime',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Circular progress
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  children: [
                    // Background circle
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    // Progress circle
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween(begin: 0, end: progress),
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 4,
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Linear progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0, end: progress),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernModeSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildModeButton(context, StudyMode.review, Icons.repeat_rounded, 'Tekrar'),
          _buildModeButton(context, StudyMode.quiz, Icons.quiz_rounded, 'Quiz'),
          _buildModeButton(context, StudyMode.flashcards, Icons.flip_rounded, 'Flash'),
          _buildModeButton(context, StudyMode.practice, Icons.fitness_center_rounded, 'Pratik'),
        ],
      ),
    );
  }

  Widget _buildModeButton(BuildContext context, StudyMode mode, IconData icon, String label) {
    final isSelected = _currentMode == mode;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
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
      case StudyMode.quiz:
      case StudyMode.practice:
        return QuizWidget(
          word: word,
          onAnswerSubmitted: _onAnswerSubmitted,
          practiceMode: _currentMode == StudyMode.practice,
        );
      case StudyMode.flashcards:
        return FlashcardWidget(
          word: word,
          onAnswerSubmitted: _onAnswerSubmitted,
        );
      case StudyMode.review:
      default:
        return QuizWidget(
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

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success animation
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isExcellent
                            ? [Colors.amber, Colors.orange]
                            : isGood
                                ? [Colors.green, Colors.teal]
                                : [Colors.blue, Colors.indigo],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isExcellent ? Colors.amber : (isGood ? Colors.green : Colors.blue))
                              .withOpacity(0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      isExcellent ? Icons.emoji_events_rounded : Icons.check_circle_rounded,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Title
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
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
                          isExcellent ? 'Mükemmel!' : (isGood ? 'Harika!' : 'Tebrikler!'),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1.0,
                            color: isExcellent
                                ? Colors.amber.shade700
                                : isGood
                                    ? Colors.green.shade700
                                    : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Çalışma oturumunu tamamladınız',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            // Stats cards
            _buildModernStatsGrid(context, stats, accuracy, duration),

            const SizedBox(height: 40),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _restartSession,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Tekrar Çalış'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Ana Sayfa'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
              child: _buildStatCard(
                context,
                icon: Icons.psychology_rounded,
                label: 'Doğruluk',
                value: '${(accuracy * 100).toInt()}%',
                color: accuracy >= 0.8 ? Colors.green : (accuracy >= 0.6 ? Colors.orange : Colors.red),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.timer_outlined,
                label: 'Süre',
                value: '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.check_circle_rounded,
                label: 'Doğru',
                value: '${stats.correctAnswers}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                icon: Icons.cancel_rounded,
                label: 'Yanlış',
                value: '${stats.completedWords - stats.correctAnswers}',
                color: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

