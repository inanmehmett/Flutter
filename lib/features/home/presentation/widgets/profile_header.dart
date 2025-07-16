import 'package:flutter/material.dart';
import '../../../auth/data/models/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildProfileImage(),
          const SizedBox(width: 15),
          _buildUserInfo(),
          const Spacer(),
          _buildProfileButton(context),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    if (profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 30,
        backgroundImage: NetworkImage(profile.profileImageUrl!),
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
      backgroundColor: Colors.orange.withOpacity(0.2),
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

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.userName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          'Seviye: ${profile.level ?? "Başlangıç"}',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
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
}
