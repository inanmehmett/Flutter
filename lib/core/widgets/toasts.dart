import 'package:flutter/material.dart';

class ToastOverlay {
  static final Map<String, DateTime> _lastShown = <String, DateTime>{};

  static void show(
    BuildContext context,
    Widget child, {
    Duration duration = const Duration(seconds: 2),
    String? channel,
    Duration throttle = const Duration(milliseconds: 1200),
  }) {
    final overlay = Navigator.maybeOf(context)?.overlay ?? Overlay.of(context, rootOverlay: true);
    if (overlay == null) return;

    // Throttle repeated toasts for the same channel (avoid duplicates from SignalR + local)
    if (channel != null && channel.isNotEmpty) {
      final now = DateTime.now();
      final last = _lastShown[channel];
      if (last != null && now.difference(last) < throttle) {
        return;
      }
      _lastShown[channel] = now;
    }
    final mq = MediaQuery.maybeOf(context);
    final topInset = (mq?.padding.top ?? 0) + 12;
    final entry = OverlayEntry(
      builder: (entryCtx) => MediaQuery(
        data: mq ?? const MediaQueryData(),
        child: IgnorePointer(
          ignoring: true,
          child: Stack(children: [
            Positioned(
              top: topInset,
              left: 12,
              right: 12,
              child: _AnimatedToast(
                duration: duration,
                child: _ToastContainer(child: child),
              ),
            ),
          ]),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(duration, () => entry.remove());
  }
}

class _AnimatedToast extends StatefulWidget {
  final Duration duration;
  final Widget child;
  const _AnimatedToast({required this.duration, required this.child});

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(_fade);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(opacity: _fade, child: widget.child),
    );
  }
}

class _ToastContainer extends StatelessWidget {
  final Widget child;
  const _ToastContainer({required this.child});

  (List<Color>, Color) _paletteForChild() {
    if (child is XpToast) {
      return (
        [const Color(0xFF10B981), const Color(0xFF059669)],
        Colors.white,
      );
    }
    if (child is XpTotalToast) {
      return (
        [const Color(0xFF10B981), const Color(0xFF059669)],
        Colors.white,
      );
    }
    if (child is LevelUpToast) {
      return (
        [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        Colors.white,
      );
    }
    if (child is BadgeToast) {
      return (
        [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
        Colors.white,
      );
    }
    if (child is StreakToast) {
      return (
        [const Color(0xFFFB923C), const Color(0xFFF97316)],
        Colors.white,
      );
    }
    return ([Colors.black87, Colors.black87], Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    final (colors, textColor) = _paletteForChild();
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: colors.last.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6)),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: DefaultTextStyle.merge(style: TextStyle(color: textColor), child: child),
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


