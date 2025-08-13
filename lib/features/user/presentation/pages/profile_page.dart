import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            UserProfile? profile;
            if (state is AuthAuthenticated) {
              profile = state.user;
            }
            profile ??= UserProfile(
              id: 'guest',
              userName: 'Misafir',
              email: '',
              profileImageUrl: null,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: false,
              level: 0,
              experiencePoints: 0,
              totalReadBooks: 0,
              totalQuizScore: 0,
            );

            final level = (profile.level ?? 0).clamp(0, 100);
            final xp = (profile.experiencePoints ?? 0).toDouble();
            final currentLevelThreshold = 100.0; // simple placeholder
            final xpProgress = (xp % currentLevelThreshold) / currentLevelThreshold;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                        backgroundImage: profile.profileImageUrl != null
                            ? NetworkImage(profile.profileImageUrl!)
                            : null,
                        child: profile.profileImageUrl == null
                            ? Text(
                                profile.userName.isNotEmpty ? profile.userName[0] : 'U',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.displayName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text('Level $level', style: TextStyle(color: Colors.grey[700])),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: xpProgress.isNaN ? 0 : xpProgress,
                                      minHeight: 8,
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit),
                        tooltip: 'Profili Düzenle',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.bio?.isNotEmpty == true ? profile.bio! : 'Kısa biyografinizi ekleyin...',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  _buildStatRow(context, profile),
                  const SizedBox(height: 24),
                  const Text('Rozetler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildBadgesPlaceholder(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, UserProfile profile) {
    return Row(
      children: [
        _statCard(context, Icons.local_fire_department, 'Streak', '0 gün'),
        const SizedBox(width: 12),
        _statCard(context, Icons.menu_book, 'Okunan', '${profile.totalReadBooks ?? 0}'),
        const SizedBox(width: 12),
        _statCard(context, Icons.quiz, 'Quiz Puanı', '${profile.totalQuizScore ?? 0}')
      ],
    );
  }

  Widget _statCard(BuildContext context, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesPlaceholder(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 6),
                const Text('Badge', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}

