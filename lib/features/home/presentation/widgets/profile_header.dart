import 'package:flutter/material.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/config/app_config.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final String? levelName;
  final int? streakDays;

  const ProfileHeader({super.key, required this.profile, this.levelName, this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileImage(),
          const SizedBox(width: 12),
          Expanded(child: _buildUserInfo(context)),
          const SizedBox(width: 8),
          _buildRightSide(context),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty) {
      final imageUrl = _normalize(profile.profileImageUrl!);
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(imageUrl),
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('🖼️ [ProfileHeader] Image load error: $exception');
        },
        child: profile.profileImageUrl!.contains('placeholder') || 
               profile.profileImageUrl!.contains('default') 
            ? Text(
                _getInitials(profile.userName),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : null,
      );
    }

    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.orange.withValues(alpha: 0.2),
      child: Text(
        _getInitials(profile.userName),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.orange,
        ),
      ),
    );
  }

  Widget _buildUserInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.userName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Icon(Icons.workspace_premium, color: Theme.of(context).colorScheme.primary, size: 16),
            const SizedBox(width: 4),
            Text(
              (levelName ?? profile.levelName ?? _formatLevel(profile.level)).toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        // Streak kaldırıldı (sadece seviye gösterimi)
      ],
    );
  }

  Widget _buildRightSide(BuildContext context) {
    final int streak = (streakDays ?? profile.currentStreak ?? 0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 6),
              Text('$streak gün', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Icon(Icons.chevron_right, color: Colors.grey[700]),
      ],
    );
  }

  String _formatLevel(int? level) {
    if (level == null || level <= 0) return '—';
    return 'Level $level';
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts.first[0]}${parts.last[0]}';
    }
    return name.isNotEmpty ? name[0] : 'U';
  }

  String _normalize(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '${AppConfig.apiBaseUrl}$url';
    return '${AppConfig.apiBaseUrl}/$url';
  }
}
