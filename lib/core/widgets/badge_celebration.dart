import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'badge_icon.dart';

class BadgeCelebration {
  static void show(BuildContext context, {required String name, String? subtitle, String? imageUrl, bool earned = true}) {
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
              TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.1).chain(CurveTween(curve: Curves.easeOutBack)), weight: 60),
              TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
            ]).evaluate(curved);
            return Stack(
              fit: StackFit.expand,
              children: [
                // Soft dark blur scrim for contrast
                IgnorePointer(
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(color: Colors.black.withValues(alpha: 0.18)),
                  ),
                ),
                // Confetti across entire screen, non-blocking
                IgnorePointer(
                  child: Stack(
                    children: _buildStars(theme, controller.value, MediaQuery.of(context).size),
                  ),
                ),
                // Center spotlight badge with glow + closer labels just beneath the badge
                Center(
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Gradient ring + glowing badge icon
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: SweepGradient(
                                colors: [
                                  Colors.amber,
                                  Colors.purpleAccent,
                                  Colors.amber,
                                ],
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.35), blurRadius: 52),
                                  BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.18), blurRadius: 96),
                                ],
                              ),
                              child: BadgeIcon(name: name, earned: earned, size: 134),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Title with gradient ink + soft halo
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white, // masked by shader
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(color: Colors.black45, blurRadius: 8),
                                  ],
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          if (subtitle != null && subtitle.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.38),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
                                      boxShadow: [
                                        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12),
                                      ],
                                    ),
                                    child: Text(
                                      subtitle,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.25,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                        color: Colors.white.withValues(alpha: 0.98),
                                        shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
                                        decoration: TextDecoration.none,
                                        decorationColor: Colors.transparent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                // Share button (optional)
                // Centered Share button with pop-in
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 28,
                  left: 0,
                  right: 0,
                  child: ScaleTransition(
                    scale: CurvedAnimation(parent: controller, curve: const Interval(0.6, 1.0, curve: Curves.elasticOut)),
                    child: Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                          elevation: 6,
                        ),
                        onPressed: () {
                          Share.share('Yeni rozet kazandım: $name');
                        },
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Paylaş'),
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
    Future.delayed(const Duration(milliseconds: 2200), () {
      controller.reverse();
      Future.delayed(const Duration(milliseconds: 250), () {
        controller.dispose();
        entry.remove();
      });
    });
  }

  static List<Widget> _buildStars(ThemeData theme, double t, Size screenSize) {
    final rnd = Random(12);
    final stars = <Widget>[];
    
    // Ensure we have valid screen size
    if (screenSize.width <= 0 || screenSize.height <= 0) {
      return stars;
    }
    
    for (int i = 0; i < 42; i++) {
      final dx = rnd.nextDouble();
      final delay = (i % 6) * 0.05;
      final progress = (t - delay).clamp(0.0, 1.0);
      final top = -90.0 + progress * (screenSize.height + 160);
      final left = dx * (screenSize.width - 24);
      final alpha = (1.0 - progress).clamp(0.0, 1.0);
      final angle = (rnd.nextDouble() - 0.5) * 0.8;
      final colorPick = i % 5;
      final color = {
        0: Colors.amberAccent,
        1: Colors.cyanAccent,
        2: Colors.pinkAccent,
        3: Colors.limeAccent,
        4: theme.colorScheme.primary,
      }[colorPick]!
          .withValues(alpha: colorPick == 4 ? 0.85 : 0.95);
      
      // Only add star if alpha is greater than 0 (visible)
      if (alpha > 0) {
        stars.add(Positioned(
          top: top,
          left: left,
          child: Opacity(
            opacity: alpha,
            child: Transform.rotate(
              angle: angle,
              child: Icon(
                i % 3 == 0 ? Icons.auto_awesome : Icons.star_rounded,
                color: color,
                size: 16 + rnd.nextInt(22).toDouble(),
              ),
            ),
          ),
        ));
      }
    }
    return stars;
  }
}


