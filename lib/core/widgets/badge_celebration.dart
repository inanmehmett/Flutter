import 'dart:math';
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
                // Confetti across entire screen, non-blocking
                IgnorePointer(child: Stack(children: _buildStars(theme, controller.value, MediaQuery.of(context).size))),
                // Center spotlight badge with glow + closer labels just beneath the badge
                Center(
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(26),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.45), blurRadius: 52),
                                BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.25), blurRadius: 104),
                              ],
                            ),
                            child: BadgeIcon(name: name, earned: earned, size: 168),
                          ),
                          const SizedBox(height: 12),
                          // Title (high-contrast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                shadows: [
                                  Shadow(color: Colors.white70, blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                          if (subtitle != null && subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                subtitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  shadows: [
                                    Shadow(color: Colors.white54, blurRadius: 4),
                                  ],
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
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                  right: 24,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                    ),
                    onPressed: () {
                      Share.share('Yeni rozet kazandım: $name');
                    },
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Paylaş'),
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
    return stars;
  }
}


