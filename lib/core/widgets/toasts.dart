import 'package:flutter/material.dart';

class ToastOverlay {
  static void show(BuildContext context, Widget child, {Duration duration = const Duration(seconds: 2)}) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: _ToastContainer(child: child),
      ),
    );
    overlay.insert(entry);
    Future.delayed(duration, () => entry.remove());
  }
}

class _ToastContainer extends StatelessWidget {
  final Widget child;
  const _ToastContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: Colors.white),
          child: child,
        ),
      ),
    );
  }
}

class XpToast extends StatelessWidget {
  final int deltaXP;
  const XpToast(this.deltaXP, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.stars, color: Colors.amberAccent),
        const SizedBox(width: 8),
        Text('+$deltaXP XP', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class LevelUpToast extends StatelessWidget {
  final String levelLabel;
  const LevelUpToast(this.levelLabel, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.emoji_events, color: Colors.orangeAccent),
        const SizedBox(width: 8),
        Text('Level Up: $levelLabel', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class BadgeToast extends StatelessWidget {
  final String name;
  const BadgeToast(this.name, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.military_tech, color: Colors.lightBlueAccent),
        const SizedBox(width: 8),
        Text('Yeni rozet: $name', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class StreakToast extends StatelessWidget {
  final int days;
  const StreakToast(this.days, {super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.local_fire_department, color: Colors.orangeAccent),
        const SizedBox(width: 8),
        Text('Streak: $days gün', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class XpTotalToast extends StatelessWidget {
  final int from;
  final int to;
  const XpTotalToast({super.key, required this.from, required this.to});
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: from.toDouble(), end: to.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final int shown = value.round();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars, color: Colors.amberAccent),
            const SizedBox(width: 8),
            Text('XP: $shown', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        );
      },
    );
  }
}


