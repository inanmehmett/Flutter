import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/network_manager.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<_LevelGoalData> _levelGoalFuture;

  @override
  void initState() {
    super.initState();
    _levelGoalFuture = _fetchLevelAndGoals();
  }

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

            return FutureBuilder<_LevelGoalData>(
              future: _levelGoalFuture,
              builder: (context, snapshot) {
                final levelInfo = snapshot.data;
                final level = levelInfo?.level ?? (profile.level ?? 0);
                final xpProgress = levelInfo?.xpProgress ?? _fallbackProgress(profile.experiencePoints ?? 0);
                final streakLabel = levelInfo?.streakDays != null ? '${levelInfo!.streakDays} gün' : '—';

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
                      _buildStatRow(context, profile, streakLabel),
                      const SizedBox(height: 24),
                      const Text('Rozetler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildBadgesPlaceholder(context),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<_LevelGoalData> _fetchLevelAndGoals() async {
    try {
      final client = getIt<NetworkManager>();
      final levelResp = await client.get('/api/ApiGamification/level');
      final goalsResp = await client.get('/api/ApiProgressStats/goals');

      double xpProgress = 0;
      int? level;
      int? streakDays;

      // Parse level response
      final ldata = levelResp.data is Map<String, dynamic> ? levelResp.data as Map<String, dynamic> : {};
      final ldat = ldata['data'] is Map<String, dynamic> ? ldata['data'] as Map<String, dynamic> : {};
      final currentXP = (ldat['currentXP'] as num?)?.toDouble() ?? 0;
      final xpForNext = (ldat['xpForNextLevel'] as num?)?.toDouble() ?? 1000;
      xpProgress = xpForNext > 0 ? (currentXP / xpForNext).clamp(0, 1).toDouble() : 0;
      // Level name exists, numeric level may be separate; fall back to profile later
      level = null;

      // Parse goals for streak
      final gdata = goalsResp.data is Map<String, dynamic> ? goalsResp.data as Map<String, dynamic> : {};
      final gdat = gdata['data'] is Map<String, dynamic> ? gdata['data'] as Map<String, dynamic> : {};
      streakDays = (gdat['streakDays'] ?? gdat['currentStreak'] ?? gdat['streak']) as int?;

      return _LevelGoalData(level: level, xpProgress: xpProgress, streakDays: streakDays);
    } catch (_) {
      return _LevelGoalData(level: null, xpProgress: 0, streakDays: null);
    }
  }

  double _fallbackProgress(int xp) {
    const threshold = 1000.0;
    return ((xp % threshold) / threshold).clamp(0.0, 1.0);
  }

  Widget _buildStatRow(BuildContext context, UserProfile profile, String streakLabel) {
    return Row(
      children: [
        _statCard(context, Icons.local_fire_department, 'Streak', streakLabel),
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

