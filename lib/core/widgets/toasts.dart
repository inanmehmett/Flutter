import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ToastOverlay {
  static final Map<String, DateTime> _lastShown = <String, DateTime>{};

  static void show(
    BuildContext context,
    Widget child, {
    Duration duration = const Duration(seconds: 3),
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
    final key = GlobalKey<_AnimatedToastState>();
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
              child: _AnimatedToast(key: key, duration: duration, child: _ToastContainer(child: child)),
            ),
          ]),
        ),
      ),
    );
    overlay.insert(entry);
    // Play exit animation slightly before removal for polish
    final int exitLeadMs = 140;
    final int totalMs = duration.inMilliseconds;
    final int startExitMs = (totalMs - exitLeadMs).clamp(0, totalMs);
    Future.delayed(Duration(milliseconds: startExitMs), () async {
      try { await key.currentState?.playOut(); } catch (_) {}
      entry.remove();
    });
  }
}

class _AnimatedToast extends StatefulWidget {
  final Duration duration;
  final Widget child;
  const _AnimatedToast({required this.duration, required this.child, super.key});

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(begin: const Offset(0, -0.12), end: Offset.zero).animate(_fade);
    _scale = Tween<double>(begin: 0.98, end: 1.0).animate(_fade);
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
      child: FadeTransition(opacity: _fade, child: ScaleTransition(scale: _scale, child: widget.child)),
    );
  }

  Future<void> playOut() async {
    try {
      if (!_controller.isDismissed) {
        await _controller.reverse();
      }
    } catch (_) {}
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color outline = (isDark ? Colors.white : Colors.black).withOpacity(0.08);
    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors.map((c) => c.withOpacity(isDark ? 0.85 : 0.95)).toList(),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withOpacity(isDark ? 0.35 : 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: outline, width: 1),
            ),
            child: DefaultTextStyle.merge(style: TextStyle(color: textColor), child: child),
          ),
        ),
      ),
    );
  }
}

class XpToast extends StatefulWidget {
  final int deltaXP;
  const XpToast(this.deltaXP, {super.key});
  
  @override
  State<XpToast> createState() => _XpToastState();
}

class _XpToastState extends State<XpToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    
    _rotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animasyonlu yıldız ikonu
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: Colors.amberAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP Kazandınız!',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+${widget.deltaXP} XP',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LevelUpToast extends StatefulWidget {
  final String levelLabel;
  const LevelUpToast(this.levelLabel, {super.key});
  
  @override
  State<LevelUpToast> createState() => _LevelUpToastState();
}

class _LevelUpToastState extends State<LevelUpToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );
    
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    _controller.forward();
    _controller.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = _controller.value < 0.3 ? _scaleAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animasyonlu kupa ikonu
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orangeAccent.withOpacity(_glowAnimation.value),
                      Colors.deepOrange.withOpacity(_glowAnimation.value),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.5 * _glowAnimation.value),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎉 Seviye Atladınız!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.levelLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class BadgeToast extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;
  
  const BadgeToast(this.name, {super.key, this.imageUrl, this.onTap});
  
  @override
  State<BadgeToast> createState() => _BadgeToastState();
}

class _BadgeToastState extends State<BadgeToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated badge icon
            ScaleTransition(
              scale: CurvedAnimation(
                parent: _controller,
                curve: Curves.elasticOut,
              ),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.emoji_events,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎉 Yeni Rozet!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (widget.onTap != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Text(
                  'Görüntüle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StreakToast extends StatefulWidget {
  final int days;
  const StreakToast(this.days, {super.key});
  
  @override
  State<StreakToast> createState() => _StreakToastState();
}

class _StreakToastState extends State<StreakToast> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _flameAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );
    
    _flameAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animasyonlu alev ikonu
              Transform.scale(
                scale: _flameAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.red.shade400,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 Streak Devam Ediyor!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.days} Gün',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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


