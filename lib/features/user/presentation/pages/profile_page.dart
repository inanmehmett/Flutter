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
            final UserProfile profile = (state is AuthAuthenticated)
                ? state.user
                : UserProfile(
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Center(
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          backgroundImage: profile.profileImageUrl != null
                              ? NetworkImage(profile.profileImageUrl!)
                              : null,
                          child: profile.profileImageUrl == null
                              ? Text(
                                  profile.userName.isNotEmpty ? profile.userName[0] : 'U',
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
                          profile.displayName,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          profile.email.isNotEmpty ? profile.email : '—',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          profile.userName,
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
                              'Joined: ${_formatJoined(profile.createdAt)}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _StatsStrip(
                        levelLabel: 'Level $level',
                        xp: (profile.experiencePoints ?? 0).toString(),
                        books: (profile.totalReadBooks ?? 0).toString(),
                      ),
                      const SizedBox(height: 20),
                      _LearningProgressCard(reading: xpProgress, listening: 0, speaking: 0),
                      const SizedBox(height: 24),
                      const Text('Rozetler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildBadgesPlaceholder(context),
                      const SizedBox(height: 12),
                      _buildStatRow(context, profile, streakLabel),
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

  String _formatJoined(DateTime dt) {
    final d = dt.toLocal();
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd-$mm-$yyyy';
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

class _LevelGoalData {
  final int? level;
  final double xpProgress;
  final int? streakDays;

  _LevelGoalData({
    required this.level,
    required this.xpProgress,
    required this.streakDays,
  });
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

