import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/vocabulary_quiz_models.dart';
import '../../../../core/widgets/toasts.dart';

class VocabularyQuizResultWidget extends StatefulWidget {
  final VocabularyQuizResult result;
  final List<VocabularyQuizAnswer> allAnswers;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const VocabularyQuizResultWidget({
    super.key,
    required this.result,
    required this.allAnswers,
    required this.onRestart,
    required this.onClose,
  });

  @override
  State<VocabularyQuizResultWidget> createState() => _VocabularyQuizResultState();
}

class _VocabularyQuizResultState extends State<VocabularyQuizResultWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scoreAnimationController;
  late AnimationController _xpAnimationController;
  late AnimationController _celebrationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _scoreAnimation;
  late Animation<double> _xpAnimation;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _xpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.easeOut,
    ));

    _xpAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _xpAnimationController,
      curve: Curves.easeOut,
    ));

    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.easeOut,
    ));

    _startAnimations();
    _showGamificationEffects();
  }

  void _startAnimations() {
    _animationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _scoreAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _xpAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _celebrationController.forward();
    });
  }

  void _showGamificationEffects() {
    // Haptic feedback for result
    if (widget.result.isPassed) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    // ✅ Real-time notifications removed to prevent duplicates
    // All gamification events (XP, Level Up, Badge, Streak) are now handled by:
    // - SignalR real-time system (0-500ms latency) via main.dart listener
    // - Polling fallback (8s interval) if SignalR is unavailable
    // 
    // This prevents double notifications when quiz completes.
    // Backend sends SignalR events → main.dart listens → shows appropriate celebrations/toasts
    //
    // If you need local feedback for debugging, use channel-based toasts:
    // ToastOverlay.show(context, XpToast(xp), channel: 'xp');  // ✅ Throttled
    
    // Optional: Keep XP toast with channel throttling to prevent duplicates
    if (widget.result.xpEarned > 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ToastOverlay.show(
            context,
            XpToast(widget.result.xpEarned),
            duration: const Duration(seconds: 3),
            channel: 'xp', // ✅ Prevents duplicate if SignalR also fires
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scoreAnimationController.dispose();
    _xpAnimationController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Result header
                    _buildResultHeader(),
                    const SizedBox(height: 24),
                    
                    // Score card
                    _buildScoreCard(),
                    const SizedBox(height: 24),
                    
                    // XP and rewards
                    _buildXPCard(),
                    const SizedBox(height: 24),
                    
                    // Streak info
                    _buildStreakCard(),
                    const SizedBox(height: 24),
                    
                    // Performance analysis
                    _buildPerformanceCard(),
                    const SizedBox(height: 24),
                    
                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultHeader() {
    final isPassed = widget.result.isPassed;
    final icon = isPassed ? Icons.celebration : Icons.sentiment_dissatisfied;
    final color = isPassed ? Colors.green : Colors.red;
    final title = isPassed ? 'Tebrikler!' : 'Tekrar Deneyin';
    final subtitle = isPassed 
        ? 'Quiz\'i başarıyla tamamladınız!' 
        : 'Geçer not alamadınız (%70 gerekli)';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: color,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Quiz Sonucu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),
          
          // Score circle
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: _scoreAnimation.value * (widget.result.quizScore / 100),
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getScoreColor(widget.result.quizScore),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.result.quizScore}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(widget.result.quizScore),
                            ),
                          ),
                          Text(
                            'Puan',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Doğru',
                  '${widget.allAnswers.where((a) => a.isCorrect).length}',
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Yanlış',
                  '${widget.allAnswers.where((a) => !a.isCorrect).length}',
                  Colors.red,
                  Icons.cancel,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Toplam',
                  '${widget.allAnswers.length}',
                  Colors.blue,
                  Icons.quiz,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildXPCard() {
    return AnimatedBuilder(
      animation: _xpAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _xpAnimation.value),
          child: Opacity(
            opacity: _xpAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade400,
                    Colors.amber.shade400,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _xpAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _xpAnimation.value * 0.5,
                            child: Icon(
                              Icons.stars,
                              color: Colors.white,
                              size: 28,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'XP Kazanımı',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildXPItem('Kazanılan', '${widget.result.xpEarned}', Icons.add),
                      _buildXPItem('Toplam', '${widget.result.newTotalXP}', Icons.star),
                      if (widget.result.levelUp)
                        _buildXPItem('Yeni Seviye', widget.result.newLevel ?? '', Icons.trending_up),
                    ],
                  ),
                  
                  if (widget.result.rewards.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _celebrationAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 0.9 + (0.1 * _celebrationAnimation.value),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Ödüller',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...widget.result.rewards.map((reward) => Text(
                                  '• $reward',
                                  style: const TextStyle(color: Colors.white),
                                )),
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
          ),
        );
      },
    );
  }

  Widget _buildXPItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Streak Bilgisi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStreakItem(
                  'Mevcut',
                  '${widget.result.streak.currentStreak}',
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStreakItem(
                  'En Uzun',
                  '${widget.result.streak.longestStreak}',
                  Colors.red,
                ),
              ),
              Expanded(
                child: _buildStreakItem(
                  'Bonus',
                  '${widget.result.streak.streakBonus}',
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceCard() {
    final correctAnswers = widget.allAnswers.where((a) => a.isCorrect).length;
    final totalAnswers = widget.allAnswers.length;
    final accuracy = totalAnswers > 0 ? (correctAnswers / totalAnswers * 100).round() : 0;
    final averageTime = widget.allAnswers.isNotEmpty 
        ? widget.allAnswers.map((a) => a.timeSpentSeconds).reduce((a, b) => a + b) / widget.allAnswers.length
        : 0.0;
    
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + (0.1 * _celebrationAnimation.value),
          child: Opacity(
            opacity: _celebrationAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.analytics,
                        color: Colors.purple,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Performans Analizi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildPerformanceItem(
                          'Doğruluk',
                          '$accuracy%',
                          _getAccuracyColor(accuracy),
                          Icons.check_circle,
                        ),
                      ),
                      Expanded(
                        child: _buildPerformanceItem(
                          'Ortalama Süre',
                          '${averageTime.toStringAsFixed(1)}s',
                          Colors.blue,
                          Icons.timer,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Performance message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getPerformanceColor(accuracy).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPerformanceColor(accuracy).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getPerformanceIcon(accuracy),
                          color: _getPerformanceColor(accuracy),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getPerformanceMessage(accuracy),
                            style: TextStyle(
                              color: _getPerformanceColor(accuracy),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildPerformanceItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Color _getAccuracyColor(int accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getPerformanceColor(int accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getPerformanceIcon(int accuracy) {
    if (accuracy >= 80) return Icons.emoji_events;
    if (accuracy >= 60) return Icons.thumb_up;
    return Icons.trending_up;
  }

  String _getPerformanceMessage(int accuracy) {
    if (accuracy >= 80) return 'Mükemmel performans! Harika iş çıkardınız!';
    if (accuracy >= 60) return 'İyi bir performans! Biraz daha pratik yaparak gelişebilirsiniz.';
    return 'Daha iyi olmak için daha fazla pratik yapmanız gerekiyor.';
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Restart button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onRestart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.refresh),
                SizedBox(width: 8),
                Text(
                  'Tekrar Dene',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Close button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onClose();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.close),
                SizedBox(width: 8),
                Text(
                  'Kapat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score < 30) return Colors.red;
    if (score < 70) return Colors.orange;
    return Colors.green;
  }
}
