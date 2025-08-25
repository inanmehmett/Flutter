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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildProfileImage(),
          const SizedBox(width: 15),
          _buildUserInfo(context),
          const Spacer(),
          // profile button removed; whole card is tappable in parent
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
          print('🖼️ [ProfileHeader] Image load error: $exception');
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
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 16),
            const SizedBox(width: 4),
            Text('${(streakDays ?? profile.currentStreak ?? 0)} gün streak', style: TextStyle(fontSize: 13, color: Colors.orange.shade700)),
          ],
        ),
      ],
    );
  }

  String _formatLevel(int? level) {
    if (level == null || level <= 0) return '—';
    return 'Level $level';
  }

  Widget _buildProfileButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/profile');
      },
      style: TextButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: const Text('Profil'),
    );
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
