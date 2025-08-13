import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';

class ProfileSamplePage extends StatelessWidget {
  const ProfileSamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            tooltip: 'Çıkış Yap',
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final UserProfile? profile = state is AuthAuthenticated ? state.user : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      backgroundImage: profile?.profileImageUrl != null
                          ? NetworkImage(profile!.profileImageUrl!)
                          : null,
                      child: profile?.profileImageUrl == null
                          ? Text(
                              (profile?.userName ?? 'U').isNotEmpty
                                  ? (profile?.userName ?? 'U')[0]
                                  : 'U',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      profile?.displayName ?? 'mehmet',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      profile?.email ?? 'mehmet@mehmet.com',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      profile?.userName ?? 'mehmet',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Joined: ${_formatJoined(profile?.createdAt)}',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StatsStrip(
                    levelLabel: profile?.level != null ? 'Level ${profile!.level}' : 'Level',
                    xp: (profile?.experiencePoints ?? 0).toString(),
                    books: (profile?.totalReadBooks ?? 0).toString(),
                  ),
                  const SizedBox(height: 20),
                  _LearningProgressCard(
                    reading: 0,
                    listening: 0,
                    speaking: 0,
                  ),
                  const SizedBox(height: 24),
                  const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _settingsTile(context, Icons.person_outline, 'Profile Details'),
                  _settingsTile(context, Icons.notifications_outlined, 'Notifications'),
                  _settingsTile(context, Icons.privacy_tip_outlined, 'Privacy'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  static String _formatJoined(DateTime? dt) {
    if (dt == null) return '—';
    final d = dt.toLocal();
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd-$mm-$yyyy';
  }

  Widget _settingsTile(BuildContext context, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final String levelLabel;
  final String xp;
  final String books;

  const _StatsStrip({
    required this.levelLabel,
    required this.xp,
    required this.books,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _stat(context, Icons.stairs, levelLabel, 'Level'),
          const SizedBox(width: 12),
          _stat(context, Icons.star, xp, 'XP'),
          const SizedBox(width: 12),
          _stat(context, Icons.menu_book, books, 'Books'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _LearningProgressCard extends StatelessWidget {
  final double reading;
  final double listening;
  final double speaking;

  const _LearningProgressCard({
    required this.reading,
    required this.listening,
    required this.speaking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Learning Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _ring(context, reading, 'Reading'),
              const SizedBox(width: 12),
              _ring(context, listening, 'Listening'),
              const SizedBox(width: 12),
              _ring(context, speaking, 'Speaking'),
            ],
          )
        ],
      ),
    );
  }

  Widget _ring(BuildContext context, double value, String label) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: clamped,
                  strokeWidth: 8,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
                Text('${(clamped * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}

