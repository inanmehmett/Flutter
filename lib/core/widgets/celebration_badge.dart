import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class CelebrationBadge extends StatefulWidget {
  final String title;
  final String description;
  final int level;

  const CelebrationBadge({Key? key, required this.title, required this.description, required this.level}) : super(key: key);

  @override
  State<CelebrationBadge> createState() => _CelebrationBadgeState();
}

class _CelebrationBadgeState extends State<CelebrationBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Level → gradient colors
  List<Color> _getGradientForLevel(int level) {
    if (level >= 10) {
      return [const Color(0xffFFD700), const Color(0xffFFA500)]; // Gold
    } else if (level >= 5) {
      return [const Color(0xffC0C0C0), const Color(0xffA9A9A9)]; // Silver
    }
    return [const Color(0xffCD7F32), const Color(0xff8B4513)]; // Bronze
  }

  String _getIconForLevel(int level) {
    if (level >= 10) return 'assets/icons/crown.png';
    if (level >= 5) return 'assets/icons/trophy.png';
    return 'assets/icons/star.png';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = _getGradientForLevel(widget.level);
    final String iconPath = _getIconForLevel(widget.level);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti background
        Lottie.asset(
          'assets/animations/confetti.json',
          controller: _controller,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration
              ..forward();
          },
          repeat: false,
        ),

        // Main badge card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: colors.last.withValues(alpha: 0.6), blurRadius: 20, spreadRadius: 3),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon (fallback to Material icon if asset missing)
              Image.asset(
                iconPath,
                height: 60,
                width: 60,
                errorBuilder: (_, __, ___) => const Icon(Icons.emoji_events_rounded, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 10),
              // Title (animated)
              AnimatedTextKit(
                repeatForever: true,
                animatedTexts: [
                  ColorizeAnimatedText(
                    widget.title,
                    textAlign: TextAlign.center,
                    textStyle: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    colors: const [Colors.white, Colors.yellowAccent, Colors.orangeAccent],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                widget.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(offset: Offset(1, 1), blurRadius: 4, color: Colors.black45)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


