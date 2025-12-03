import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../bloc/vocabulary_bloc.dart';
import '../bloc/vocabulary_event.dart';
import '../bloc/vocabulary_state.dart';
import '../../domain/services/review_session.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/vocabulary_stats.dart';
import '../../domain/entities/study_mode.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../../../core/di/injection.dart';
import '../widgets/quiz_widget.dart';
import '../widgets/flashcard_widget.dart';
import '../widgets/practice_widget.dart';
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
  VocabularyStats? _stats;
  bool _shouldStartSessionAfterStatsLoad = false;
  
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
    // Set flag to start session after stats are loaded
    _shouldStartSessionAfterStatsLoad = true;
    
    // Load vocabulary stats first - session will start in listener after stats load
    context.read<VocabularyBloc>().add(LoadVocabulary());
  }
  
  void _startReviewSession() {
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

    // Do not write per-answer to backend; results will be persisted on session completion

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
    final keyboardHeight = mq.viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    
    return MediaQuery(
      data: mq.copyWith(textScaleFactor: clampedScale),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: _buildModernAppBar(context),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              AnimatedScale(
                scale: isKeyboardOpen ? 0.9 : 1.0,
                alignment: Alignment.topCenter,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Container(
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
                      } else if (state is VocabularyLoaded) {
                        // Stats bilgisini sakla
                        setState(() {
                          _stats = state.stats;
                        });
                        
                        // Stats yüklendikten sonra session başlat (race condition önlemi)
                        if (_shouldStartSessionAfterStatsLoad) {
                          _shouldStartSessionAfterStatsLoad = false;
                          _startReviewSession();
                        }
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
                        // Session yükleniyor veya boş - empty state göster
                        // Eğer stats varsa ve toplam kelime 0 ise, gerçekten kelime yok
                        // Eğer stats varsa ve toplam kelime > 0 ise ama session boşsa, hata var
                        return _buildModernEmptyState(context);
                      }

                      return _sessionCompleted
                          ? _buildModernSessionComplete(context)
                          : _buildModernStudyContent(context);
                    },
                  ),
                ),
              ),
              _buildFloatingControls(context, isKeyboardOpen),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return AppBar(
      toolbarHeight: isKeyboardOpen ? 0 : kToolbarHeight,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: isKeyboardOpen
          ? null
          : IconButton(
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
      actions: isKeyboardOpen
          ? const []
          : [
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

  Widget _buildFloatingControls(BuildContext context, bool isKeyboardOpen) {
    final canRestart = !_sessionCompleted && _currentSession != null;
    if (!isKeyboardOpen) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: !isKeyboardOpen,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        opacity: isKeyboardOpen ? 1 : 0,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 12, right: 16),
              child: Material(
                color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Çıkış',
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (canRestart)
                      Container(
                        height: 28,
                        width: 1,
                        color: Theme.of(context).dividerColor.withOpacity(0.2),
                      ),
                    if (canRestart)
                      IconButton(
                        tooltip: 'Yeniden Başla',
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        onPressed: _restartSession,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
    // If stats are still loading, show a loading indicator
    if (_stats == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    final hasWords = _stats!.totalWords > 0;
    
    // Duruma göre mesaj ve aksiyon belirle
    final String title;
    final String message;
    final IconData icon;
    final List<Widget> actions;
    
    if (!hasWords) {
      // Hiç kelime yok - motivasyon ve action-oriented CTA
      title = 'İngilizce Yolculuğun Başlasın! 🚀';
      message = 'İlk kelimelerin seni bekliyor!\n\nKitap okuyarak otomatik olarak yeni kelimeler keşfedecek ve günlük hedeflerini tamamlayarak İngilizceni geliştireceksin.';
      icon = Icons.auto_stories;
      actions = [
        FilledButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/books');
          },
          icon: const Icon(Icons.auto_stories),
          label: const Text('Hemen Kitap Keşfet'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Daha Sonra'),
        ),
      ];
    } else {
      // Kelime var ama bu mod için uygun kelime yok
      final isDueMode = _currentMode == StudyMode.study;
      
      if (isDueMode) {
        // Due mode: Çalışma zamanı gelen kelime yok - başarı kutlaması ve kitap okumaya yönlendirme
        final learnedCount = _stats!.totalWords;
        title = '🌟 Mükemmel! Bugünkü Hedefin Tamamlandı!';
        message = 'Tebrikler! ${learnedCount} kelimeyi başarıyla öğrendin.\n\n💡 Yeni kelimeleri keşfetmek için kitap okumaya devam et. Her okuma yeni bir kelime hazinesi demek!';
        icon = Icons.workspace_premium;
        actions = [
          // Primary CTA - Kitap okuma
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/books');
              },
              icon: const Icon(Icons.auto_stories),
              label: const Text('Yeni Kelimeler Keşfet'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Secondary info - Motivasyon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Her gün yeni kelimeler öğrenenlerin %80\'i kitap okuyarak ilerliyor',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Daha Sonra'),
          ),
        ];
      } else {
        // Diğer modlar için başarı odaklı mesajlar
        switch (_currentMode) {
          case StudyMode.practice:
            title = '💪 Süpersin! Hiç Zor Kelime Yok';
            message = 'Tüm kelimelerini mükemmel biliyorsun!\n\nYeni zorluklar için daha fazla kelime ekle veya kitap okumaya devam et.';
            icon = Icons.emoji_events;
            actions = [
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/books');
                },
                icon: const Icon(Icons.auto_stories),
                label: const Text('Yeni Kelimeler Keşfet'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ];
          case StudyMode.flashcards:
            title = '🎴 Flashcard Hazırlığı';
            message = 'Flashcard çalışması için yeterli kelime yok.\n\nKitap okuyarak yeni kelimeler ekle ve flashcard\'larla pratik yap!';
            icon = Icons.style;
            actions = [
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/books');
                },
                icon: const Icon(Icons.auto_stories),
                label: const Text('Kitap Okuyarak Ekle'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Geri Dön'),
              ),
            ];
          case StudyMode.study:
            // Bu durum yukarıda handle edildi
            title = '';
            message = '';
            icon = Icons.celebration_outlined;
            actions = [];
        }
      }
    }
    
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
                      icon,
                      size: 90,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ...actions,
          ],
        ),
      ),
    );
  }

  Widget _buildModernStudyContent(BuildContext context) {
    final currentWord = _currentSession!.words[_currentWordIndex];
    final progress = (_currentWordIndex + 1) / _currentSession!.words.length;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return SafeArea(
      top: !isKeyboardOpen,
      bottom: true,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        offset: Offset(0, isKeyboardOpen ? -0.1 : 0),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isKeyboardOpen
                  ? const SizedBox.shrink(key: ValueKey('header-empty'))
                  : SlideTransition(
                      key: const ValueKey('header-full'),
                      position: _headerSlideAnimation,
                      child: _buildGlassmorphicHeader(context, progress),
                    ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isKeyboardOpen
                  ? const SizedBox.shrink(key: ValueKey('mode-empty'))
                  : Padding(
                      key: const ValueKey('mode-full'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildModernModeSelector(context),
                    ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              height: isKeyboardOpen ? 4 : 16,
            ),
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
      ),
    );
  }

  Widget _buildGlassmorphicHeader(BuildContext context, double progress) {
    final currentIndex = _currentWordIndex + 1;
    final totalWords = _currentSession!.totalWords;
    final estimatedMinutes = (totalWords * 15 / 60).round().clamp(1, 60);
    
    // Klavye açıksa header'ı küçült
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.all(isKeyboardOpen ? 2 : 16),
      padding: EdgeInsets.all(isKeyboardOpen ? 4 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withBlue(220).withGreen(180),
          ],
        ),
        borderRadius: BorderRadius.circular(isKeyboardOpen ? 12 : 24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: isKeyboardOpen ? 6 : 24,
            offset: Offset(0, isKeyboardOpen ? 2 : 10),
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
                padding: EdgeInsets.all(isKeyboardOpen ? 4 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(isKeyboardOpen ? 6 : 14),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: isKeyboardOpen ? 14 : 26,
                ),
              ),
              SizedBox(width: isKeyboardOpen ? 4 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Çalışma Oturumu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isKeyboardOpen ? 12 : 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: isKeyboardOpen ? 1 : 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: isKeyboardOpen ? 10 : 16,
                          color: Colors.white.withOpacity(0.85),
                        ),
                        SizedBox(width: isKeyboardOpen ? 2 : 6),
                        Text(
                          '$totalWords kelime · ~$estimatedMinutes dk',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: isKeyboardOpen ? 9 : 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Circular progress indicator (yüzde etrafında hizalanmış halka)
              SizedBox(
                width: isKeyboardOpen ? 30 : 60,
                height: isKeyboardOpen ? 30 : 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    SizedBox.expand(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                    ),
                    // Animated progress circle
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: 0, end: progress),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 5,
                            backgroundColor: Colors.transparent,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      },
                    ),
                    // Percentage text
                    Center(
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isKeyboardOpen ? 8 : 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: isKeyboardOpen ? 2 : 18),
          
          // Linear progress bar with gradient
          Stack(
            children: [
              // Background
              Container(
                height: isKeyboardOpen ? 3 : 12,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(isKeyboardOpen ? 2 : 8),
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
                      height: isKeyboardOpen ? 3 : 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.white, Colors.white70],
                        ),
                        borderRadius: BorderRadius.circular(isKeyboardOpen ? 2 : 8),
                        boxShadow: isKeyboardOpen ? [] : [
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
          
          SizedBox(height: isKeyboardOpen ? 3 : 10),
          
          // Word counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kelime ${currentIndex}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: isKeyboardOpen ? 8 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isKeyboardOpen ? 6 : 10,
                  vertical: isKeyboardOpen ? 2 : 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(isKeyboardOpen ? 6 : 12),
                ),
                child: Text(
                  '$currentIndex / $totalWords',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isKeyboardOpen ? 9 : 13,
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isKeyboardOpen ? 2 : 5),
      margin: EdgeInsets.symmetric(horizontal: isKeyboardOpen ? 4 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(isKeyboardOpen ? 10 : 18),
        boxShadow: isKeyboardOpen ? [] : [
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
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardOpen = keyboardHeight > 0;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _onModeChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(vertical: isKeyboardOpen ? 6 : 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withBlue(200),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(isKeyboardOpen ? 8 : 14),
            boxShadow: isSelected && !isKeyboardOpen
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
                size: isKeyboardOpen ? 16 : 24,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
              ),
              SizedBox(height: isKeyboardOpen ? 2 : 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: isKeyboardOpen ? 9 : 11,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 720;
        final isNarrow = constraints.maxWidth < 380;
        final iconSize = isCompact ? 110.0 : 150.0;
        final glowSize = iconSize + (isCompact ? 18.0 : 30.0);
        final spacingLarge = isCompact ? 20.0 : 32.0;
        final spacingMedium = isCompact ? 12.0 : 20.0;
        final padding = EdgeInsets.symmetric(horizontal: 20, vertical: spacingMedium);

        final column = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: glowSize,
                        height: glowSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (isExcellent ? Colors.amber : (isGood ? Colors.green : Colors.blue))
                                  .withOpacity(0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: iconSize,
                        height: iconSize,
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
                                  .withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          isPerfect
                              ? Icons.stars_rounded
                              : (isExcellent ? Icons.emoji_events_rounded : Icons.check_circle_rounded),
                          size: iconSize * 0.45,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: spacingLarge),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: Column(
                      children: [
                        Text(
                          isPerfect
                              ? '🏆 Mükemmel! 100% Doğru!'
                              : (isExcellent
                                  ? '⭐ Muhteşem Performans!'
                                  : (isGood ? '👏 Harika İş Başardın!' : '✨ İyi Çalışma!')),
                          style: (isCompact
                                  ? Theme.of(context).textTheme.headlineMedium
                                  : Theme.of(context).textTheme.headlineLarge)
                              ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: isPerfect
                                ? Colors.amber.shade700
                                : isExcellent
                                    ? Colors.green.shade700
                                    : isGood
                                        ? Colors.blue.shade700
                                        : Theme.of(context).colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: spacingMedium / 2),
                        Text(
                          isPerfect
                              ? '${stats.correctAnswers} kelimeyi hatasız tamamladın! Sen bir yıldızsın! ⭐'
                              : isExcellent
                                  ? 'Bugün ${stats.correctAnswers} kelime öğrendin. İngilizce\'n güçleniyor! 💪'
                                  : isGood
                                      ? 'Harika ilerleme! ${stats.correctAnswers} doğru cevap. Devam et! 🚀'
                                      : '${stats.correctAnswers} kelime öğrendin. Her gün daha iyisin! 📈',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.75),
                                height: 1.4,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: spacingLarge),
            _buildModernStatsGrid(context, stats, accuracy, duration, compact: isCompact),
            SizedBox(height: spacingMedium),
            if (isExcellent)
              Container(
                padding: EdgeInsets.all(isCompact ? 12 : 16),
                margin: EdgeInsets.only(bottom: spacingMedium),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primaryContainer.withOpacity(0.25),
                      Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.25),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 6 : 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.trending_up,
                        color: Theme.of(context).colorScheme.primary,
                        size: isCompact ? 18 : 22,
                      ),
                    ),
                    SizedBox(width: spacingMedium),
                    Expanded(
                      child: Text(
                        'Günlük çalışma yapanlar, yapmayanlardan 5x daha hızlı öğreniyor.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/books');
                    },
                    icon: const Icon(Icons.auto_stories, size: 20),
                    label: const Text('Yeni Kelimeler Keşfet'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isCompact ? 14 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: spacingMedium),
                if (isNarrow)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _restartSession,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Tekrar'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: spacingMedium),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.home_rounded, size: 18),
                          label: const Text('Ana Sayfa'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _restartSession,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Tekrar'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(StudyConstants.buttonBorderRadius),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.home_rounded, size: 18),
                          label: const Text('Ana Sayfa'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 14),
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
          ],
        );
        final constrainedColumn = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: column,
          ),
        );

        return SingleChildScrollView(
          padding: padding,
          physics: const BouncingScrollPhysics(),
          child: constrainedColumn,
        );
      },
    );
  }

  Widget _buildModernStatsGrid(
    BuildContext context,
    ReviewSession stats,
    double accuracy,
    Duration duration, {
    bool compact = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
                compact: compact,
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            Expanded(
              child: _buildGlassStatCard(
                context,
                icon: Icons.timer_outlined,
                label: 'Süre',
                value: '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                color: Colors.blue,
                delay: 100,
                compact: compact,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 12),
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
                compact: compact,
              ),
            ),
            SizedBox(width: compact ? 8 : 12),
            Expanded(
              child: _buildGlassStatCard(
                context,
                icon: Icons.cancel_rounded,
                label: 'Yanlış',
                value: '${stats.completedWords - stats.correctAnswers}',
                color: Colors.red,
                delay: 300,
                compact: compact,
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
    bool compact = false,
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
              padding: EdgeInsets.all(compact ? 12 : 18),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(compact ? 14 : 18),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: compact ? 1.5 : 2,
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
                  Icon(icon, color: color, size: compact ? 28 : 36),
                  SizedBox(height: compact ? 6 : 10),
                  Text(
                    value,
                    style: (compact
                            ? Theme.of(context).textTheme.headlineSmall
                            : Theme.of(context).textTheme.headlineMedium)
                        ?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
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
