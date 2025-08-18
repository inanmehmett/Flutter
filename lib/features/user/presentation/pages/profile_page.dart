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
  late Future<_ProgressData> _progressFuture;
  late Future<List<_BadgeItem>> _badgesFuture;
  // Son başarılı değerleri tutarak geçici hatalarda UI'nin sıfırlanmasını önler
  UserProfile? _lastProfile;
  _LevelGoalData? _lastLevelGoal;
  _ProgressData? _lastProgress;
  List<_BadgeItem>? _lastBadges;

  @override
  void initState() {
    super.initState();
    _levelGoalFuture = _fetchLevelAndGoals();
    _progressFuture = _fetchProgress();
    _badgesFuture = _fetchBadges();
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
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              _lastProfile = state.user;
              setState(() {
                _levelGoalFuture = _fetchLevelAndGoals();
                _progressFuture = _fetchProgress();
                _badgesFuture = _fetchBadges();
              });
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
            final UserProfile? authenticated = (state is AuthAuthenticated) ? state.user : null;
            if (authenticated != null) {
              _lastProfile = authenticated;
            }
            final UserProfile profile = _lastProfile ?? UserProfile(
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
              currentStreak: 0,
              longestStreak: 0,
            );

            return FutureBuilder<_LevelGoalData>(
              future: _levelGoalFuture,
              builder: (context, snapshot) {
                final _LevelGoalData? levelInfo = snapshot.data ?? _lastLevelGoal;
                if (snapshot.hasData && snapshot.data != null) {
                  _lastLevelGoal = snapshot.data;
                }
                final int profileXP = profile.experiencePoints ?? 0;
                final int apiXP = levelInfo?.currentXP ?? 0;
                // API 0 döndüyse veya veri yoksa ekranda 0'a düşme; mevcut/profil değerini koru
                final int displayedXP = apiXP > 0 ? apiXP : profileXP;
                final double xpProgress = levelInfo?.xpProgress ?? _fallbackProgress(displayedXP);
                
                // Level bilgilerini hazırla - hem numeric hem de label
                final int? numericLevel = levelInfo?.currentLevel ?? _lastLevelGoal?.currentLevel;
                final String levelDisplayText = numericLevel != null ? 'Level $numericLevel' : (levelInfo?.levelLabel ?? 'Level');
                
                // Streak bilgilerini hazırla - robust fallback ile
                final int? streakDaysVal = levelInfo?.streakDays ?? _lastLevelGoal?.streakDays ?? profile.currentStreak;
                final int? longestStreakVal = levelInfo?.longestStreak ?? _lastLevelGoal?.longestStreak ?? profile.longestStreak;
                final String streakLabel = _formatStreakDisplay(streakDaysVal, longestStreakVal);
                
                // Streak progress hesapla - _StatsStrip widget'ında hesaplanıyor

                final String xpValue = displayedXP.toString();

                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        Theme.of(context).colorScheme.background,
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                radius: 52,
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
                          levelLabel: levelDisplayText,
                          xp: xpValue,
                          books: (profile.totalReadBooks ?? 0).toString(),
                          streak: streakLabel,
                          streakProgress: _StatsStrip.calculateProgress(streakDaysVal, longestStreakVal),
                          streakDays: streakDaysVal,
                          longestStreak: longestStreakVal,
                        ),
                        const SizedBox(height: 20),
                        FutureBuilder<_ProgressData>(
                          future: _progressFuture,
                          builder: (context, progSnap) {
                            final p = progSnap.data;
                            return _LearningProgressCard(
                              reading: p?.reading ?? 0,
                              listening: p?.listening ?? 0,
                              speaking: p?.speaking ?? 0,
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text('Rozetler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        FutureBuilder<List<_BadgeItem>>(
                          future: _badgesFuture,
                          builder: (context, badgeSnap) {
                 final items = badgeSnap.data ?? _lastBadges ?? [];
                 if (badgeSnap.hasData && (badgeSnap.data?.isNotEmpty ?? false)) {
                   _lastBadges = badgeSnap.data;
                 }
                 if (items.isEmpty) {
                              return _buildBadgesPlaceholder(context);
                            }
                            return GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: items.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                              itemBuilder: (context, index) {
                                final b = items[index];
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
                                        if (b.imageUrl != null && b.imageUrl!.isNotEmpty)
                                          SizedBox(
                                            width: 36,
                                            height: 36,
                                            child: Image.network(b.imageUrl!, fit: BoxFit.contain),
                                          )
                                        else
                                          Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary),
                                        const SizedBox(height: 6),
                                        Text(b.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile-details'),
                          child: _settingsTile(context, Icons.person_outline, 'Profile Details'),
                        ),
                        _settingsTile(context, Icons.notifications_outlined, 'Notifications'),
                        _settingsTile(context, Icons.privacy_tip_outlined, 'Privacy'),
                        const SizedBox(height: 12),
                        _buildStatRow(context, profile),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      ),
    );
  }

  Future<_LevelGoalData> _fetchLevelAndGoals() async {
    try {
      final client = getIt<NetworkManager>();
      final levelResp = await client.get('/api/ApiGamification/level');
      final goalsResp = await client.get('/api/ApiProgressStats/goals');
      
      // Streak bilgilerini yeni endpoint'ten al
      int? streakDays;
      int? longestStreak;
      try {
        final streakResp = await client.get('/api/ApiProgressStats/streak');
        final sroot = streakResp.data is Map<String, dynamic> ? streakResp.data as Map<String, dynamic> : {};
        final sdat = sroot['data'] is Map<String, dynamic> ? sroot['data'] as Map<String, dynamic> : {};
        streakDays = _asNum(sdat['currentStreak'] ?? sdat['CurrentStreak'] ?? sdat['streak']).toInt();
        longestStreak = _asNum(sdat['longestStreak'] ?? sdat['LongestStreak']).toInt();
      } catch (_) {
        // Streak endpoint'i çalışmazsa goals'dan dene
        try {
          final groot = goalsResp.data is Map<String, dynamic> ? goalsResp.data as Map<String, dynamic> : {};
          final gdat = groot['data'] is Map<String, dynamic> ? groot['data'] as Map<String, dynamic> : {};
          streakDays = _asNum(gdat['streakDays'] ?? gdat['currentStreak'] ?? gdat['streak']).toInt();
          longestStreak = _asNum(gdat['longestStreak'] ?? gdat['LongestStreak']).toInt();
        } catch (_) {}
      }

      double xpProgress = 0;
      String? levelLabel;
      int? currentXP;
      int? currentLevel;

      final lroot = levelResp.data is Map<String, dynamic> ? levelResp.data as Map<String, dynamic> : {};
      final ldat = lroot['data'] is Map<String, dynamic> ? lroot['data'] as Map<String, dynamic> : {};
      
      // XP bilgilerini al
      final dynamic currentXPRaw = ldat['currentXP'] ?? ldat['CurrentXP'] ?? ldat['totalXP'] ?? ldat['TotalXP'];
      final currentXPd = _asNum(currentXPRaw).toDouble();
      final dynamic xpForNextRaw = ldat['xpForNextLevel'] ?? ldat['XPForNextLevel'] ?? 1000;
      final xpForNext = _asNum(xpForNextRaw, 1000).toDouble();
      final dynamic progressRaw = ldat['progressPercentage'] ?? ldat['ProgressPercentage'];
      final progressVal = _asNum(progressRaw).toDouble();
      
      xpProgress = progressVal > 0 && progressVal <= 1 ? progressVal : (xpForNext > 0 ? (currentXPd / xpForNext).clamp(0, 1).toDouble() : 0);
      currentXP = currentXPd.toInt();
      
      // Level bilgilerini al - hem label hem de numeric değer
      levelLabel = (ldat['currentLevelEnglish'] ?? ldat['CurrentLevelEnglish'] ?? ldat['currentLevel'] ?? ldat['CurrentLevel'] ?? 'Level').toString();
      
      // Numeric level değerini hesapla - XP'ye göre
      if (currentXP > 0) {
        // Basit level hesaplama: her 1000 XP = 1 level
        currentLevel = ((currentXP - 1) ~/ 1000) + 1;
      }

      final result = _LevelGoalData(
        levelLabel: levelLabel, 
        currentXP: currentXP, 
        xpProgress: xpProgress, 
        streakDays: streakDays,
        currentLevel: currentLevel,
        longestStreak: longestStreak,
      );
      _lastLevelGoal = result;
      return result;
    } catch (_) {
      // Ağ/401 durumunda UI'yı sıfırlamamak için son bilinen profilden türet
      if (_lastLevelGoal != null) return _lastLevelGoal!;
      final xp = _lastProfile?.experiencePoints ?? 0;
      final level = xp > 0 ? ((xp - 1) ~/ 1000) + 1 : 1;
      return _LevelGoalData(
        levelLabel: 'Level $level',
        currentXP: xp,
        xpProgress: _fallbackProgress(xp),
        streakDays: null,
        currentLevel: level,
        longestStreak: null,
      );
    }
  }

  num _asNum(dynamic value, [num fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value;
    if (value is String) {
      final p = num.tryParse(value);
      if (p != null) return p;
    }
    return fallback;
  }

  Future<_ProgressData> _fetchProgress() async {
    try {
      final client = getIt<NetworkManager>();
      final resp = await client.get('/api/ApiProgressStats/detailed');
      final root = resp.data is Map<String, dynamic> ? resp.data as Map<String, dynamic> : {};
      final data = root['data'] is Map<String, dynamic> ? root['data'] as Map<String, dynamic> : {};
      final map = (data['activityTypeDistribution'] ?? data['ActivityTypeDistribution']) as Map<String, dynamic>?;
      if (map == null || map.isEmpty) {
        return const _ProgressData(reading: 0, listening: 0, speaking: 0);
      }
      double read = 0, listen = 0, speak = 0;
      map.forEach((k, v) {
        final key = k.toString().toLowerCase();
        final val = (v as num?)?.toDouble() ?? 0;
        if (key.contains('read')) read = val; else if (key.contains('listen')) listen = val; else if (key.contains('speak')) speak = val;
      });
      final total = (read + listen + speak);
      if (total <= 0) {
        return const _ProgressData(reading: 0, listening: 0, speaking: 0);
      }
      final result = _ProgressData(reading: read / total, listening: listen / total, speaking: speak / total);
      _lastProgress = result;
      return result;
    } catch (_) {
      return _lastProgress ?? const _ProgressData(reading: 0, listening: 0, speaking: 0);
    }
  }

  Future<List<_BadgeItem>> _fetchBadges() async {
    try {
      final client = getIt<NetworkManager>();
      // Backend'de doğrudan badges endpointi yok; önerilen yol: /api/ApiGamification/badges
      // Geçici: varsa kullan; yoksa boş liste dön
      final resp = await client.get('/api/ApiGamification/badges');
      final root = resp.data is Map<String, dynamic> ? resp.data as Map<String, dynamic> : {};
      final list = (root['data'] ?? root['Data']) as List<dynamic>?;
      if (list == null) return _lastBadges ?? [];
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return _BadgeItem(
          name: (m['name'] ?? m['Name'] ?? '') as String,
          imageUrl: (m['imageUrl'] ?? m['ImageUrl']) as String?,
          isEarned: ((m['isEarned'] ?? m['IsEarned']) as bool?) ?? false,
        );
      }).toList();
    } catch (_) {
      return _lastBadges ?? [];
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

  String _formatStreakDisplay(int? streakDays, int? longestStreak) {
    if (streakDays == null || streakDays == 0) return '—';
    if (streakDays == 1) return '1 gün';
    return '$streakDays gün';
  }

  Widget _buildStatRow(BuildContext context, UserProfile profile) {
    return Row(
      children: [
        _statCard(context, Icons.menu_book, 'Okunan', '${profile.totalReadBooks ?? 0}'),
        const SizedBox(width: 12),
        _statCard(context, Icons.quiz, 'Quiz Puanı', '${profile.totalQuizScore ?? 0}'),
        const SizedBox(width: 12),
        _statCard(context, Icons.trending_up, 'Toplam XP', '${profile.experiencePoints ?? 0}'),
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

class _LevelGoalData {
  final String? levelLabel;
  final int? currentXP;
  final double xpProgress;
  final int? streakDays;
  final int? currentLevel;
  final int? longestStreak;

  _LevelGoalData({
    required this.levelLabel,
    required this.currentXP,
    required this.xpProgress,
    required this.streakDays,
    required this.currentLevel,
    this.longestStreak,
  });
}

class _ProgressData {
  final double reading;
  final double listening;
  final double speaking;
  const _ProgressData({required this.reading, required this.listening, required this.speaking});
}

class _BadgeItem {
  final String name;
  final String? imageUrl;
  final bool isEarned;
  _BadgeItem({required this.name, required this.imageUrl, required this.isEarned});
}

class _StatsStrip extends StatelessWidget {
  final String levelLabel;
  final String xp;
  final String books;
  final String streak;
  final double streakProgress;
  final int? streakDays;
  final int? longestStreak;

  const _StatsStrip({
    required this.levelLabel,
    required this.xp,
    required this.books,
    required this.streak,
    required this.streakProgress,
    required this.streakDays,
    required this.longestStreak,
  });

  String _getStreakMotivation(int? streakDays) {
    if (streakDays == null || streakDays == 0) return 'İlk adımı at!';
    if (streakDays == 1) return 'Harika başlangıç!';
    if (streakDays < 7) return 'Devam et!';
    if (streakDays < 14) return '1 hafta tamamlandı!';
    if (streakDays < 30) return '2 hafta tamamlandı!';
    if (streakDays < 100) return '1 ay tamamlandı!';
    return 'Efsanevi streak!';
  }

  static double calculateProgress(int? streakDays, int? longestStreak) {
    if (streakDays == null || streakDays == 0) return 0.0;
    if (longestStreak == null || longestStreak == 0) return 1.0; // Streak yoksa tamamlandı

    final double currentStreakProgress = (streakDays / longestStreak).clamp(0.0, 1.0);
    return currentStreakProgress;
  }

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
        children: [
          Row(
            children: [
              _stat(context, Icons.stairs, levelLabel, 'Level'),
              const SizedBox(width: 12),
              _stat(context, Icons.star, xp, 'XP'),
              const SizedBox(width: 12),
              _stat(context, Icons.menu_book, books, 'Books'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.local_fire_department, color: Theme.of(context).colorScheme.primary, size: 24),
                    const SizedBox(height: 6),
                    Text(
                      streak, 
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 22,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    const Text('Streak', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    if (streakDays != null && streakDays! > 0 && longestStreak != null && longestStreak! > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'En uzun: ${longestStreak} gün',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (streakProgress > 0) ...[
            const SizedBox(height: 8),
            Text(
              _getStreakMotivation(streakDays),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: streakProgress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${(streakProgress * 100).round()}% tamamlandı',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label, {bool isLarge = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: isLarge ? 24 : 20),
          const SizedBox(height: 6),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: isLarge ? 22 : 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: isLarge ? 14 : 12)),
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



