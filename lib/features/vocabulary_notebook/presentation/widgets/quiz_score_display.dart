import 'package:flutter/material.dart';

/// Score display for quiz mode with animations and bonuses
class QuizScoreDisplay extends StatefulWidget {
  final int score;
  final int streak;
  final int? lastBonus;

  const QuizScoreDisplay({
    super.key,
    required this.score,
    this.streak = 0,
    this.lastBonus,
  });

  @override
  State<QuizScoreDisplay> createState() => _QuizScoreDisplayState();
}

class _QuizScoreDisplayState extends State<QuizScoreDisplay>
    with SingleTickerProviderStateMixin {
  late AnimationController _bonusController;
  late Animation<double> _bonusAnimation;
  late Animation<Offset> _bonusSlideAnimation;
  int _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _previousScore = widget.score;
    
    _bonusController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _bonusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bonusController,
      curve: Curves.easeOutCubic,
    ));
    
    _bonusSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(
      parent: _bonusController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didUpdateWidget(QuizScoreDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Animate when score increases
    if (widget.score > _previousScore) {
      _bonusController.forward(from: 0.0);
      _previousScore = widget.score;
    }
  }

  @override
  void dispose() {
    _bonusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasStreak = widget.streak > 0;
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main score display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withBlue(200),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy icon
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              
              // Score
              TweenAnimationBuilder<int>(
                duration: const Duration(milliseconds: 500),
                tween: IntTween(begin: _previousScore, end: widget.score),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  );
                },
              ),
              
              // Streak indicator
              if (hasStreak) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.streak}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Bonus animation (floating +points)
        if (widget.lastBonus != null && widget.lastBonus! > 0) ...[
          Positioned(
            right: 0,
            top: -10,
            child: AnimatedBuilder(
              animation: _bonusAnimation,
              builder: (context, child) {
                final clampedOpacity = (1.0 - _bonusAnimation.value).clamp(0.0, 1.0);
                return Opacity(
                  opacity: clampedOpacity,
                  child: SlideTransition(
                    position: _bonusSlideAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.amber, Colors.orange],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '+${widget.lastBonus}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

