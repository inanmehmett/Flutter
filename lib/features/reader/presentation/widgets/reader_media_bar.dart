import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReaderMediaBar extends StatelessWidget {
  final bool isSpeaking;
  final bool isPaused;
  final double speechRate; // 0.30, 0.40, 0.50, 0.65
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onStop;
  final VoidCallback onCycleRate;
  final ValueChanged<double> onScrubToPageFraction; // 0..1

  const ReaderMediaBar({
    super.key,
    required this.isSpeaking,
    required this.isPaused,
    required this.speechRate,
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
    required this.onTogglePlayPause,
    required this.onStop,
    required this.onCycleRate,
    required this.onScrubToPageFraction,
  });

  double _mapTtsToAudioRate(double ttsRate) {
    if (ttsRate <= 0.40) return 0.9;
    if (ttsRate <= 0.50) return 1.0;
    if (ttsRate <= 0.65) return 1.1;
    return 1.2;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final Color fg = isDark ? Colors.white : Colors.black;
    final Color fgMuted = fg.withOpacity(0.7);
    final Color glass = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.8);
    final Color border = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06);

    final double progress = totalPages > 0 ? (currentPage + 1) / totalPages : 0.0;
    final String rateLabel = '${_mapTtsToAudioRate(speechRate).toStringAsFixed(1)}x';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: glass,
              border: Border.all(color: border, width: 1),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress + Page
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
                    const SizedBox(width: 10),
                    Text(
                      '${currentPage + 1}/$totalPages',
                      style: TextStyle(fontSize: 12, color: fgMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Controls row
                Row(
                  children: [
                    // Speed chip
                    _SpeedChip(
                      label: rateLabel,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onCycleRate();
                      },
                      fg: fg,
                      isDark: isDark,
                    ),
                    const Spacer(),
                    _IconButtonCircle(
                      icon: CupertinoIcons.backward_end_fill,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onPrev();
                      },
                      fg: fg,
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _PlayButton(
                      isSpeaking: isSpeaking,
                      isPaused: isPaused,
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        onTogglePlayPause();
                      },
                    ),
                    const SizedBox(width: 8),
                    _IconButtonCircle(
                      icon: CupertinoIcons.forward_end_fill,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onNext();
                      },
                      fg: fg,
                      isDark: isDark,
                    ),
                    const Spacer(),
                    _IconButtonCircle(
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
}

class _PlayButton extends StatelessWidget {
  final bool isSpeaking;
  final bool isPaused;
  final VoidCallback onTap;

  const _PlayButton({
    required this.isSpeaking,
    required this.isPaused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.shade600,
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
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

class _IconButtonCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color fg;
  final bool isDark;

  const _IconButtonCircle({
    required this.icon,
    required this.onTap,
    required this.fg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Icon(icon, color: fg.withOpacity(0.9), size: 20),
        ),
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color fg;
  final bool isDark;

  const _SpeedChip({
    required this.label,
    required this.onTap,
    required this.fg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.speedometer, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}


