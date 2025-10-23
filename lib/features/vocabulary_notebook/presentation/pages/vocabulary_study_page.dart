import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../bloc/vocabulary_bloc.dart';
import '../bloc/vocabulary_event.dart';
import '../bloc/vocabulary_state.dart';
import '../../domain/services/spaced_repetition_service.dart';
import '../../domain/services/review_session.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/study_mode.dart';
import '../widgets/quiz_widget.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/study_session_header.dart';
import '../widgets/study_progress_indicator.dart';

class VocabularyStudyPage extends StatefulWidget {
  const VocabularyStudyPage({super.key});

  @override
  State<VocabularyStudyPage> createState() => _VocabularyStudyPageState();
}

class _VocabularyStudyPageState extends State<VocabularyStudyPage>
    with TickerProviderStateMixin {
  StudyMode _currentMode = StudyMode.review;
  ReviewSession? _currentSession;
  int _currentWordIndex = 0;
  bool _sessionCompleted = false;
  
  late AnimationController _progressController;
  late AnimationController _cardController;
  late Animation<double> _cardAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _cardAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardController,
      curve: Curves.easeOutBack,
    ));
    
    _loadStudySession();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _loadStudySession() {
    context.read<VocabularyBloc>().add(StartReviewSession());
  }

  void _onModeChanged(StudyMode mode) {
    setState(() {
      _currentMode = mode;
    });
    HapticFeedback.selectionClick();
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

    // Progress animation
    _progressController.forward();

    // Next word or complete session
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocConsumer<VocabularyBloc, VocabularyState>(
        listener: (context, state) {
          if (state is VocabularyLoaded && state.words.isNotEmpty) {
            final session = SpacedRepetitionService.startReviewSession(state.words);
            setState(() {
              _currentSession = session;
            });
            _cardController.forward();
          }
        },
        builder: (context, state) {
          if (state is VocabularyLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is VocabularyError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hata: ${state.message}',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStudySession,
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (_currentSession == null || _currentSession!.words.isEmpty) {
            return _buildEmptyState(context);
          }

          return _buildStudyContent(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 24),
          Text(
            'Çalışacak Kelime Yok',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bugün için review edilecek kelime bulunmuyor.\nYeni kelimeler ekleyin veya yarın tekrar deneyin.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Geri Dön'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyContent(BuildContext context) {
    if (_sessionCompleted) {
      return _buildSessionComplete(context);
    }

    final currentWord = _currentSession!.words[_currentWordIndex];
    final progress = (_currentWordIndex + 1) / _currentSession!.words.length;

    return Column(
      children: [
        // Header
        StudySessionHeader(
          mode: _currentMode,
          onModeChanged: _onModeChanged,
          session: _currentSession!,
        ),

        // Progress indicator
        StudyProgressIndicator(
          progress: progress,
          currentIndex: _currentWordIndex + 1,
          totalWords: _currentSession!.words.length,
          animationController: _progressController,
        ),

        // Study content
        Expanded(
          child: AnimatedBuilder(
            animation: _cardAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _cardAnimation.value,
                child: Opacity(
                  opacity: _cardAnimation.value,
                  child: _buildStudyWidget(context, currentWord),
                ),
              );
            },
          ),
        ),

        // Bottom actions
        _buildBottomActions(context),
      ],
    );
  }

  Widget _buildStudyWidget(BuildContext context, VocabularyWord word) {
    switch (_currentMode) {
      case StudyMode.quiz:
        return QuizWidget(
          word: word,
          onAnswerSubmitted: _onAnswerSubmitted,
        );
      case StudyMode.flashcards:
        return FlashcardWidget(
          word: word,
          onAnswerSubmitted: _onAnswerSubmitted,
        );
      case StudyMode.practice:
        return QuizWidget(
          word: word,
          onAnswerSubmitted: _onAnswerSubmitted,
          practiceMode: true,
        );
      case StudyMode.review:
      default:
        return QuizWidget(
          word: word,
          onAnswerSubmitted: _onAnswerSubmitted,
        );
    }
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _restartSession,
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden Başla'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Çıkış'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionComplete(BuildContext context) {
    final stats = _currentSession!;
    final accuracy = stats.accuracyRate;
    final duration = stats.duration;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              'Tebrikler!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Çalışma oturumu tamamlandı',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 32),

            // Stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  _buildStatRow(
                    context,
                    'Doğruluk Oranı',
                    '${(accuracy * 100).toStringAsFixed(1)}%',
                    Icons.flag_outlined,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    context,
                    'Tamamlanan Kelime',
                    '${stats.completedWords}/${stats.totalWords}',
                    Icons.check_circle_outline,
                    Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    context,
                    'Süre',
                    '${duration.inMinutes} dakika',
                    Icons.timer_outlined,
                    Colors.orange,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _restartSession,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Çalış'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.home),
                    label: const Text('Ana Sayfa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
