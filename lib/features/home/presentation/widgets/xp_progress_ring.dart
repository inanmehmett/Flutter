import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';

/// Circular XP progress ring showing current and total XP.
/// 
/// Features:
/// - Animated circular progress
/// - Current/Total XP display
/// - Responsive sizing
/// - Duolingo-style design
/// 
/// Example:
/// ```dart
/// XPProgressRing(
///   currentXP: 1250,
///   totalXP: 2000,
///   size: 64,
/// )
/// ```
class XPProgressRing extends StatelessWidget {
  final int currentXP;
  final int totalXP;
  final double size;
  final double strokeWidth;

  const XPProgressRing({
    super.key,
    required this.currentXP,
    required this.totalXP,
    this.size = 56,
    this.strokeWidth = 4,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalXP > 0 ? (currentXP / totalXP).clamp(0.0, 1.0) : 0.0;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primary.withOpacity(0.15),
              ),
            ),
          ),
          // Progress ring
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0.0, end: progress),
              builder: (context, value, child) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatXP(currentXP),
                style: TextStyle(
                  fontSize: size * 0.2,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              Text(
                'XP',
                style: TextStyle(
                  fontSize: size * 0.14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Format XP number for display
  /// - < 1000: Show as is (e.g., 850)
  /// - >= 1000: Show with K suffix (e.g., 1.2K)
  String _formatXP(int xp) {
    if (xp < 1000) {
      return xp.toString();
    } else if (xp < 10000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(xp / 1000).toStringAsFixed(0)}K';
    }
  }
}

/// Alternative: Compact XP ring with just the number
class CompactXPRing extends StatelessWidget {
  final int currentXP;
  final int totalXP;
  final double size;

  const CompactXPRing({
    super.key,
    required this.currentXP,
    required this.totalXP,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalXP > 0 ? (currentXP / totalXP).clamp(0.0, 1.0) : 0.0;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CompactRingPainter(
              progress: progress,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              progressColor: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          Text(
            _formatXP(currentXP),
            style: TextStyle(
              fontSize: size * 0.28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatXP(int xp) {
    if (xp < 1000) return xp.toString();
    if (xp < 10000) return '${(xp / 1000).toStringAsFixed(1)}K';
    return '${(xp / 1000).toStringAsFixed(0)}K';
  }
}

/// Custom painter for compact ring
class _CompactRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  _CompactRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    const startAngle = -math.pi / 2; // Start from top
    final sweepAngle = 2 * math.pi * progress;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CompactRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

