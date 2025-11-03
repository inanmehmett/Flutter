import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Level-Up Celebration Widget
/// Displays a beautiful full-screen celebration when user levels up
/// 
/// Usage:
/// ```dart
/// LevelUpCelebration.show(
///   context,
///   levelLabel: 'B1.2',
///   xpEarned: 150,
/// );
/// ```
class LevelUpCelebration {
  static void show(
    BuildContext context, {
    required String levelLabel,
    int? xpEarned,
  }) {
    final OverlayState overlay = Overlay.of(context);

    final AnimationController controller = AnimationController(
      vsync: Navigator.of(context),
      duration: const Duration(milliseconds: 1600),
    );
    final curved = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) {
        final theme = Theme.of(context);
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            final opacity = Tween<double>(begin: 0.0, end: 1.0).evaluate(curved);
            final scale = TweenSequence<double>([
              TweenSequenceItem(
                tween: Tween(begin: 0.7, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)),
                weight: 60,
              ),
              TweenSequenceItem(
                tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
                weight: 40,
              ),
            ]).evaluate(curved);

            return Stack(
              fit: StackFit.expand,
              children: [
                // Backdrop blur
                IgnorePointer(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(color: Colors.black.withValues(alpha: 0.18)),
                  ),
                ),
                
                // Confetti
                IgnorePointer(
                  child: Stack(
                    children: _buildConfetti(theme, controller.value, MediaQuery.of(context).size),
                  ),
                ),

                // Level-up card
                Center(
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: _LevelUpCard(
                        levelLabel: levelLabel,
                        xpEarned: xpEarned,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    overlay.insert(entry);
    controller.forward();
    
    // Auto-dismiss after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      controller.reverse();
      Future.delayed(const Duration(milliseconds: 250), () {
        controller.dispose();
        entry.remove();
      });
    });
  }

  static List<Widget> _buildConfetti(ThemeData theme, double t, Size screenSize) {
    final rnd = Random(42);
    final stars = <Widget>[];
    
    if (screenSize.width <= 0 || screenSize.height <= 0) return stars;
    
    for (int i = 0; i < 50; i++) {
      final dx = rnd.nextDouble();
      final delay = (i % 6) * 0.05;
      final progress = (t - delay).clamp(0.0, 1.0);
      final top = -90.0 + progress * (screenSize.height + 160);
      final left = dx * (screenSize.width - 24);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      
      if (alpha > 0) {
        stars.add(Positioned(
          top: top,
          left: left,
          child: Opacity(
            opacity: alpha,
            child: Icon(
              i % 2 == 0 ? Icons.star_rounded : Icons.auto_awesome,
              color: [
                Colors.purpleAccent,
                Colors.cyanAccent,
                Colors.amberAccent,
                theme.colorScheme.primary,
              ][i % 4].withValues(alpha: 0.9),
              size: 16 + rnd.nextInt(18).toDouble(),
            ),
          ),
        ));
      }
    }
    return stars;
  }
}

class _LevelUpCard extends StatelessWidget {
  final String levelLabel;
  final int? xpEarned;

  const _LevelUpCard({
    required this.levelLabel,
    this.xpEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9C27B0), Color(0xFF673AB7)], // Purple gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.6),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Level Up Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.arrow_upward_rounded,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          
          // "Level Up!" text
          const Text(
            'Level Up!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.2,
              decoration: TextDecoration.none,
              shadows: [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Level label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              levelLabel,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          
          if (xpEarned != null && xpEarned! > 0) ...[
            const SizedBox(height: 20),
            
            // XP earned
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '+$xpEarned XP',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Congratulations text
          Text(
            'Tebrikler! Yeni seviye! 🎉',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

