import 'package:flutter/material.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/enums/cefr_level.dart';

class GamificationHeader extends StatelessWidget {
  final UserProfile profile;
  final int? streakDays;
  final int? totalXP;
  final int? weeklyXP;
  final int? dailyGoal;
  final int? dailyProgress;

  const GamificationHeader({
    super.key,
    required this.profile,
    this.streakDays,
    this.totalXP,
    this.weeklyXP,
    this.dailyGoal,
    this.dailyProgress,
  });

  @override
  Widget build(BuildContext context) {
    final currentXP = totalXP ?? profile.experiencePoints ?? 0;
    final cefrLevel = CefrLevel.fromXP(currentXP);
    final levelColor = Color(int.parse(cefrLevel.color.replaceFirst('#', '0xff')));
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            levelColor.withOpacity(0.1),
            levelColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: levelColor.withOpacity(0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(context),
          const SizedBox(height: 16),
          _buildXPProgress(context),
          const SizedBox(height: 12),
          _buildBottomRow(context),
        ],
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(
      children: [
        // Level Chip
        _buildLevelChip(context),
        const Spacer(),
        // Streak Pill
        _buildStreakPill(context),
      ],
    );
  }

  Widget _buildLevelChip(BuildContext context) {
    // Profil sayfasındaki gibi backend'den gelen levelLabel'ı kullan
    final levelLabel = profile.levelDisplay ?? profile.levelName ?? 'Beginner';
    final currentXP = totalXP ?? profile.experiencePoints ?? 0;
    
    // CEFR seviyesine göre renk belirle
    final cefrLevel = CefrLevel.fromXP(currentXP);
    final levelColor = Color(int.parse(cefrLevel.color.replaceFirst('#', '0xff')));
    
    // Debug: XP ve seviye bilgilerini logla
    print('🎯 [GamificationHeader] levelLabel: $levelLabel');
    print('🎯 [GamificationHeader] currentXP: $currentXP');
    print('🎯 [GamificationHeader] cefrLevel: ${cefrLevel.code}');
    print('🎯 [GamificationHeader] profile.experiencePoints: ${profile.experiencePoints}');
    print('🎯 [GamificationHeader] totalXP: $totalXP');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor, levelColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: levelColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cefrLevel.icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            levelLabel,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakPill(BuildContext context) {
    final streak = streakDays ?? profile.currentStreak ?? 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.orange.shade700,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$streak gün',
            style: TextStyle(
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPProgress(BuildContext context) {
    final currentXP = totalXP ?? profile.experiencePoints ?? 0;
    final cefrLevel = CefrLevel.fromXP(currentXP);
    final progress = cefrLevel.getProgressInLevel(currentXP);
    final xpToNext = cefrLevel.getXPToNextLevel(currentXP);
    final levelColor = Color(int.parse(cefrLevel.color.replaceFirst('#', '0xff')));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'XP Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '$currentXP XP',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: levelColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(levelColor),
          minHeight: 8,
        ),
        const SizedBox(height: 4),
        Text(
          '${(progress * 100).toInt()}% to next level',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(BuildContext context) {
    final dailyGoal = this.dailyGoal ?? 30; // Default 30 minutes
    final dailyProgress = this.dailyProgress ?? 0;
    final progressPercent = dailyProgress / dailyGoal;
    
    return Row(
      children: [
        // Daily Goal Ring
        Expanded(
          child: _buildDailyGoalRing(context, dailyGoal, dailyProgress, progressPercent),
        ),
        const SizedBox(width: 16),
        // Weekly XP
        _buildWeeklyXP(context),
      ],
    );
  }

  Widget _buildDailyGoalRing(BuildContext context, int goal, int progress, double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Günlük Hedef',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                children: [
                  CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 4,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green,
                    ),
                  ),
                  Center(
                    child: Text(
                      '${(percent * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$progress / $goal dk',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Kalan: ${goal - progress} dk',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyXP(BuildContext context) {
    final weeklyXP = this.weeklyXP ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            color: Colors.blue.shade700,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            'Haftalık',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            '$weeklyXP XP',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
