import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DailyMediaBar extends StatelessWidget {
  final bool isSpeaking;
  final bool isPaused;
  final double speechRate;
  final int currentPage;
  final int totalPages;
  // Removed sentence rail: no pageContent or sentence index highlighting
  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onStop;
  final VoidCallback onCycleRate;
  final ValueChanged<double> onScrubToPageFraction; // 0..1

  const DailyMediaBar({
    super.key,
    required this.isSpeaking,
    required this.isPaused,
    required this.speechRate,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevPage,
    required this.onNextPage,
    required this.onTogglePlayPause,
    required this.onStop,
    required this.onCycleRate,
    required this.onScrubToPageFraction,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;
    final Color fgMuted = fg.withOpacity(0.7);
    final Color glass = isDark ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.85);
    final Color border = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06);

    final double progress = totalPages > 0 ? (currentPage + 1) / totalPages : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: glass,
              border: Border.all(color: border, width: 1),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page scrub + label
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: fg,
                          inactiveTrackColor: fg.withOpacity(0.2),
                          thumbColor: fg,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          trackHeight: 3,
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          value: progress.clamp(0.0, 1.0),
                          onChanged: (v) {
                            HapticFeedback.selectionClick();
                            onScrubToPageFraction(v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${currentPage + 1}/$totalPages',
                      style: TextStyle(fontSize: 12, color: fgMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Sentence rail removed for cleaner UI
                // Controls
                Row(
                  children: [
                    _SpeedPill(
                      rate: _formatRate(speechRate),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onCycleRate();
                      },
                      fg: fg,
                      isDark: isDark,
                    ),
                    const Spacer(),
                    _IconCircle(
                      icon: CupertinoIcons.backward_end_fill,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onPrevPage();
                      },
                      fg: fg,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _PlayBtn(
                      isSpeaking: isSpeaking,
                      isPaused: isPaused,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onTogglePlayPause();
                      },
                    ),
                    const SizedBox(width: 8),
                    _IconCircle(
                      icon: CupertinoIcons.forward_end_fill,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onNextPage();
                      },
                      fg: fg,
                      isDark: isDark,
                    ),
                    const Spacer(),
                    _IconCircle(
                      icon: CupertinoIcons.stop_fill,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onStop();
                      },
                      fg: fg,
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRate(double ttsRate) {
    if (ttsRate <= 0.40) return '0.9x';
    if (ttsRate <= 0.50) return '1.0x';
    if (ttsRate <= 0.65) return '1.1x';
    return '1.2x';
  }
}

class _PlayBtn extends StatelessWidget {
  final bool isSpeaking;
  final bool isPaused;
  final VoidCallback onTap;
  const _PlayBtn({required this.isSpeaking, required this.isPaused, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.orange.shade600,
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              isSpeaking ? (isPaused ? Icons.play_arrow : Icons.pause) : Icons.play_arrow,
              key: ValueKey(isSpeaking ? (isPaused ? 'play' : 'pause') : 'play'),
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color fg;
  final bool isDark;
  const _IconCircle({required this.icon, required this.onTap, required this.fg, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Icon(icon, color: fg.withOpacity(0.9), size: 22),
        ),
      ),
    );
  }
}

class _SpeedPill extends StatelessWidget {
  final String rate;
  final VoidCallback onTap;
  final Color fg;
  final bool isDark;
  const _SpeedPill({required this.rate, required this.onTap, required this.fg, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.speedometer, size: 16),
            const SizedBox(width: 8),
            Text(rate, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}


