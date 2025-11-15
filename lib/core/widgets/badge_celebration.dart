import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'badge_icon.dart';

class BadgeCelebration {
  static void show(
    BuildContext context, {
    required String name,
    String? subtitle,
    String? imageUrl,
    String? rarity,
    String? rarityColorHex,
    bool earned = true,
  }) {
    // Use rootOverlay to ensure it shows even if context is from a nested route
    final OverlayState? overlay = Navigator.maybeOf(context)?.overlay ?? Overlay.of(context, rootOverlay: true);
    if (overlay == null) {
      print('❌ BadgeCelebration: Could not find overlay');
      return;
    }

    final navigator = Navigator.maybeOf(context) ?? Navigator.of(context, rootNavigator: true);
    final AnimationController controller = AnimationController(
      vsync: navigator,
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
                          // Rarity-based gradient ring + glowing badge icon
                          _buildRarityRing(context, rarity, rarityColorHex, name, earned),
                          const SizedBox(height: 12),
                          // Title with rarity-based gradient ink + soft halo
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ShaderMask(
                              shaderCallback: (bounds) => _getRarityGradient(rarity, rarityColorHex).createShader(bounds),
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white, // masked by shader
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 12),
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
                // Share button with rarity-based styling
                Positioned(
                  bottom: MediaQuery.of(context).padding.bottom + 28,
                  left: 0,
                  right: 0,
                  child: ScaleTransition(
                    scale: CurvedAnimation(parent: controller, curve: const Interval(0.6, 1.0, curve: Curves.elasticOut)),
                    child: Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getRarityColor(rarity, rarityColorHex),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 8,
                          shadowColor: _getRarityColor(rarity, rarityColorHex).withOpacity(0.5),
                        ),
                        onPressed: () {
                          final rarityLabel = _getRarityLabel(rarity);
                          Share.share('🏆 $rarityLabel rozet kazandım: $name!\n\n$subtitle');
                        },
                        icon: const Icon(Icons.ios_share, size: 22),
                        label: const Text(
                          'Paylaş',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Rarity Badge Display
                if (rarity != null && rarity.isNotEmpty)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 20,
                    left: 0,
                    right: 0,
                    child: FadeTransition(
                      opacity: CurvedAnimation(parent: controller, curve: const Interval(0.4, 1.0)),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _getRarityColor(rarity, rarityColorHex).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getRarityColor(rarity, rarityColorHex).withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getRarityColor(rarity, rarityColorHex).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                color: _getRarityColor(rarity, rarityColorHex),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getRarityLabel(rarity),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _getRarityColor(rarity, rarityColorHex),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
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

  static Widget _buildRarityRing(
    BuildContext context,
    String? rarity,
    String? rarityColorHex,
    String name,
    bool earned,
  ) {
    final rarityColor = _getRarityColor(rarity, rarityColorHex);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            rarityColor,
            rarityColor.withOpacity(0.7),
            rarityColor,
            rarityColor.withOpacity(0.5),
            rarityColor,
          ],
          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withOpacity(0.6),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: rarityColor.withOpacity(0.3),
            blurRadius: 80,
            spreadRadius: 16,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: rarityColor.withOpacity(0.4),
              blurRadius: 60,
              spreadRadius: 4,
            ),
            BoxShadow(
              color: rarityColor.withOpacity(0.2),
              blurRadius: 100,
              spreadRadius: 8,
            ),
          ],
        ),
        child: BadgeIcon(
          name: name,
          rarity: rarity,
          rarityColorHex: rarityColorHex,
          earned: earned,
          size: 150,
        ),
      ),
    );
  }

  static Color _getRarityColor(String? rarity, String? rarityColorHex) {
    if (rarityColorHex != null) {
      final color = _parseHexColor(rarityColorHex);
      if (color != null) return color;
    }
    
    switch ((rarity ?? '').toLowerCase()) {
      case 'legendary':
      case 'diamond':
        return Colors.cyan.shade400;
      case 'epic':
      case 'gold':
        return Colors.amber.shade600;
      case 'rare':
      case 'silver':
        return Colors.blue.shade400;
      case 'uncommon':
      case 'bronze':
        return Colors.orange.shade400;
      default:
        return Colors.amber.shade600;
    }
  }

  static LinearGradient _getRarityGradient(String? rarity, String? rarityColorHex) {
    final baseColor = _getRarityColor(rarity, rarityColorHex);
    
    return LinearGradient(
      colors: [
        baseColor,
        baseColor.withOpacity(0.8),
        baseColor,
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static String _getRarityLabel(String? rarity) {
    switch ((rarity ?? '').toLowerCase()) {
      case 'legendary':
      case 'diamond':
        return 'Efsanevi';
      case 'epic':
      case 'gold':
        return 'Epik';
      case 'rare':
      case 'silver':
        return 'Nadir';
      case 'uncommon':
      case 'bronze':
        return 'Yaygın';
      default:
        return 'Ortak';
    }
  }

  static Color? _parseHexColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '').trim();
      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
      if (cleaned.length == 8) {
        return Color(int.parse(cleaned, radix: 16));
      }
      return null;
    } catch (_) {
      return null;
    }
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


