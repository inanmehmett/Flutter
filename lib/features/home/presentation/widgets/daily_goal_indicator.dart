import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Compact daily goal progress indicator.
/// 
/// Features:
/// - Linear progress bar
/// - Percentage and fraction display
/// - Color coding (progress-based)
/// - Motivational states
/// 
/// Example:
/// ```dart
/// DailyGoalIndicator(
///   currentXP: 35,
///   goalXP: 50,
/// )
/// ```
class DailyGoalIndicator extends StatelessWidget {
  final int currentXP;
  final int goalXP;
  final bool showPercentage;
  final bool showFraction;

  const DailyGoalIndicator({
    super.key,
    required this.currentXP,
    required this.goalXP,
    this.showPercentage = true,
    this.showFraction = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goalXP > 0 ? (currentXP / goalXP).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();
    final progressColor = _getProgressColor(progress);
    
    return Row(
      children: [
        // Progress bar
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showFraction) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Günlük Hedef',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '$currentXP / $goalXP XP',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.0, end: progress),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: progressColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: progressColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: progressColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: progressColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Get progress color based on completion percentage
  Color _getProgressColor(double progress) {
    if (progress >= 1.0) {
      return const Color(0xFF4CAF50); // Green - Complete
    } else if (progress >= 0.5) {
      return AppColors.primary; // Orange - In progress
    } else {
      return Colors.grey.shade600; // Grey - Just started
    }
  }
}

/// Minimal daily goal ring (alternative design)
class DailyGoalRing extends StatelessWidget {
  final int currentXP;
  final int goalXP;
  final double size;

  const DailyGoalRing({
    super.key,
    required this.currentXP,
    required this.goalXP,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goalXP > 0 ? (currentXP / goalXP).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();
    final isComplete = progress >= 1.0;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isComplete 
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : AppColors.primary.withOpacity(0.1),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size - 4,
            height: size - 4,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 3,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete ? const Color(0xFF4CAF50) : AppColors.primary,
              ),
            ),
          ),
          if (isComplete)
            Icon(
              Icons.check_rounded,
              size: size * 0.5,
              color: const Color(0xFF4CAF50),
            )
          else
            Text(
              '$percentage',
              style: TextStyle(
                fontSize: size * 0.3,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }
}

