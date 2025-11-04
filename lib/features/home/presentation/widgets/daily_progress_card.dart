import 'package:flutter/material.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';

/// Daily progress card showing user's daily XP goal, streak, and mini goals.
/// 
/// Features:
/// - Daily XP progress bar
/// - Motivational messages based on progress
/// - Mini goals: Streak, Study, XP Target
/// - Orange gradient theme (Duolingo-style)
class DailyProgressCard extends StatelessWidget {
  final UserProfile profile;
  final int? streakDays;
  final int dailyXP;
  final int dailyGoal;

  const DailyProgressCard({
    super.key,
    required this.profile,
    this.streakDays,
    required this.dailyXP,
    this.dailyGoal = 50,
  });

  @override
  Widget build(BuildContext context) {
    final streak = streakDays ?? profile.currentStreak ?? 0;
    final progressPercentage = (dailyXP / dailyGoal * 100).clamp(0, 100).toInt();
    
    // Motivational message based on progress
    final motivationMessage = _getMotivationMessage(progressPercentage);
    
    // Mini goals status
    final hasStreak = streak > 0;
    final hasStudied = dailyXP > 0;
    final reachedGoal = progressPercentage >= 100;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.cardRadius),
        boxShadow: AppShadows.cardShadowElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(progressPercentage, motivationMessage),
          const SizedBox(height: 12),
          _buildProgressBar(progressPercentage),
          const SizedBox(height: 4),
          _buildProgressLabel(dailyXP, dailyGoal),
          const SizedBox(height: 12),
          _buildMiniGoals(streak, hasStreak, hasStudied, reachedGoal),
        ],
      ),
    );
  }

  Widget _buildHeader(int progressPercentage, String motivationMessage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Günlük Hedefler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                motivationMessage,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '%$progressPercentage',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int progressPercentage) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LinearProgressIndicator(
        value: (progressPercentage / 100).clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: Colors.white.withOpacity(0.3),
        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildProgressLabel(int currentXP, int goalXP) {
    return Text(
      '$currentXP / $goalXP XP',
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.8),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildMiniGoals(
    int streak,
    bool hasStreak,
    bool hasStudied,
    bool reachedGoal,
  ) {
    return Row(
      children: [
        _MiniGoalChip(
          icon: hasStudied ? Icons.check_circle : Icons.circle_outlined,
          label: 'Bugün Çalış',
          isCompleted: hasStudied,
        ),
        const SizedBox(width: 12),
        _MiniGoalChip(
          icon: reachedGoal ? Icons.check_circle : Icons.circle_outlined,
          label: 'Günlük Hedef',
          isCompleted: reachedGoal,
        ),
      ],
    );
  }

  String _getMotivationMessage(int progressPercentage) {
    if (progressPercentage == 0) {
      return 'Bugünkü hedefine başla! 💪';
    } else if (progressPercentage < 50) {
      return 'Güzel! Devam et 🚀';
    } else if (progressPercentage < 100) {
      return 'Neredeyse! 🔥';
    } else {
      return 'Hedef tamamlandı! 🎉';
    }
  }
}

/// Mini goal chip showing completion status
class _MiniGoalChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCompleted;

  const _MiniGoalChip({
    required this.icon,
    required this.label,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isCompleted ? Colors.white : Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(isCompleted ? 0.95 : 0.7),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

