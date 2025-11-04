import 'package:flutter/material.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/config/app_config.dart';
import 'level_chip.dart';
import 'xp_progress_ring.dart';

/// Home page header showing user profile, level, and XP progress.
/// 
/// Features:
/// - Profile picture with level badge
/// - Personalized greeting
/// - XP progress ring
/// - Streak indicator
/// - Responsive layout
/// 
/// Example:
/// ```dart
/// HomeHeader(
///   profile: userProfile,
///   greeting: 'Günaydın, Mehmet!',
///   streakDays: 7,
/// )
/// ```
class HomeHeader extends StatelessWidget {
  final UserProfile profile;
  final String greeting;
  final int? streakDays;
  final VoidCallback? onTap;

  const HomeHeader({
    super.key,
    required this.profile,
    required this.greeting,
    this.streakDays,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile picture + level badge
            _buildProfileSection(isCompact),
            SizedBox(width: isCompact ? 12 : 16),
            // Greeting + stats
            Expanded(
              child: _buildInfoSection(isCompact),
            ),
            // XP ring
            _buildXPSection(isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isCompact) {
    final size = isCompact ? 52.0 : 60.0;
    final level = profile.levelDisplay ?? profile.levelName ?? 'A1';
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Profile picture
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.2), AppColors.primaryLight.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: _buildProfileImage(),
          ),
        ),
        // Level badge
        Positioned(
          bottom: -4,
          right: -4,
          child: LevelChip(
            level: level,
            height: isCompact ? 22 : 26,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    final imageUrl = _resolveImageUrl(profile.profileImageUrl);
    
    if (imageUrl.isEmpty) {
      return Icon(
        Icons.person,
        size: 32,
        color: AppColors.primary,
      );
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.person,
          size: 32,
          color: AppColors.primary,
        );
      },
    );
  }

  Widget _buildInfoSection(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting
        Text(
          greeting,
          style: TextStyle(
            fontSize: isCompact ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Stats row
        Row(
          children: [
            if (streakDays != null && streakDays! > 0) ...[
              Icon(
                Icons.local_fire_department,
                size: isCompact ? 14 : 16,
                color: const Color(0xFFFF6D00),
              ),
              const SizedBox(width: 4),
              Text(
                '$streakDays',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Icon(
              Icons.star_rounded,
              size: isCompact ? 14 : 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${profile.experiencePoints ?? 0} XP',
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildXPSection(bool isCompact) {
    final currentXP = profile.experiencePoints ?? 0;
    // Calculate next level XP (simplified - can be enhanced)
    final nextLevelXP = _calculateNextLevelXP(currentXP);
    
    return XPProgressRing(
      currentXP: currentXP,
      totalXP: nextLevelXP,
      size: isCompact ? 48 : 56,
      strokeWidth: 4,
    );
  }

  /// Calculate next level XP based on current XP
  /// Formula: Next level at every 1000 XP milestone
  int _calculateNextLevelXP(int currentXP) {
    if (currentXP < 1000) return 1000;
    final nextMilestone = ((currentXP / 1000).ceil() + 1) * 1000;
    return nextMilestone;
  }

  String _resolveImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    if (imageUrl.startsWith('/')) {
      return '${AppConfig.apiBaseUrl}$imageUrl';
    }
    return '${AppConfig.apiBaseUrl}/$imageUrl';
  }
}

