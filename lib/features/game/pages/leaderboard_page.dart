import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/di/injection.dart';
import '../../../core/config/app_config.dart';
import '../services/game_service.dart';

enum LeaderboardSort { allTime, weekly }

/// Modern podium card widget with glassmorphism effects
class PodiumCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final bool isFirst;
  final int xpValue;

  const PodiumCard({
    super.key,
    required this.entry,
    required this.rank,
    required this.isFirst,
    required this.xpValue,
  });

ddaki  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(rank);
    
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Picture with Crown/Medal
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isFirst ? 80 : 70,
                height: isFirst ? 80 : 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(isFirst ? 40 : 35),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    // Glassmorphism effect
                    BoxShadow(
                      color: CupertinoColors.white.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isFirst ? 40 : 35),
                  child: entry.profileImageUrl != null && entry.profileImageUrl!.isNotEmpty
                    ? Image.network(
                        _buildFullImageUrl(entry.profileImageUrl!),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(isFirst ? 40 : 35),
                            ),
                            child: Center(
                              child: CupertinoActivityIndicator(
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Image load error for ${entry.userName}: $error');
                          return _buildDefaultAvatar(entry, isFirst);
                        },
                      )
                    : _buildDefaultAvatar(entry, isFirst),
                ),
              ),
              // Crown/Medal icon
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: rankColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: rankColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    rank == 1 ? CupertinoIcons.star_fill : 
                    rank == 2 ? CupertinoIcons.star_circle_fill : 
                    CupertinoIcons.star_circle,
                    size: 16,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Rank Badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: CupertinoColors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          
          // User Name
          SizedBox(
            width: 70,
            child: Text(
              entry.userName,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 3),
          
          // XP Value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatXP(xpValue),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.systemBlue,
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return CupertinoColors.systemBlue;
    }
  }

  String _formatXP(int xp) {
    if (xp >= 1000000) {
      final millions = xp / 1000000;
      if (millions == millions.toInt().toDouble()) {
        return '${millions.toInt()}M';
      } else {
        return '${millions.toStringAsFixed(1)}M';
      }
    } else if (xp >= 1000) {
      final thousands = xp / 1000;
      if (thousands == thousands.toInt().toDouble()) {
        return '${thousands.toInt()}k';
      } else {
        return '${thousands.toStringAsFixed(1)}k';
      }
    } else {
      return _formatNumber(xp);
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    return number.toString();
  }

  String _buildFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    
    final baseUrl = AppConfig.apiBaseUrl;
    if (imageUrl.startsWith('/')) {
      return '$baseUrl$imageUrl';
    } else {
      return '$baseUrl/$imageUrl';
    }
  }

  Widget _buildDefaultAvatar(LeaderboardEntry entry, bool isFirst) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemBlue,
            CupertinoColors.systemPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: isFirst ? 24 : 20,
            fontWeight: FontWeight.w900,
            color: CupertinoColors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

/// Modern leaderboard item card with glassmorphism effects
class LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final int xpValue;
  final VoidCallback? onTap;

  const LeaderboardCard({
    super.key,
    required this.entry,
    required this.xpValue,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
          // Glassmorphism effect
          BoxShadow(
            color: CupertinoColors.white.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank number
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    entry.rank.toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.black,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Profile Picture
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: entry.profileImageUrl != null && entry.profileImageUrl!.isNotEmpty
                    ? Image.network(
                        _buildFullImageUrl(entry.profileImageUrl!),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: CupertinoActivityIndicator(
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('❌ Image load error for ${entry.userName}: $error');
                          return _buildDefaultAvatar(entry);
                        },
                      )
                    : _buildDefaultAvatar(entry),
                ),
              ),
              const SizedBox(width: 16),
              
              // User Name
              Expanded(
                child: Text(
                  entry.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // XP Value
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatXP(xpValue),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.systemBlue,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatXP(int xp) {
    if (xp >= 1000000) {
      final millions = xp / 1000000;
      if (millions == millions.toInt().toDouble()) {
        return '${millions.toInt()}M';
      } else {
        return '${millions.toStringAsFixed(1)}M';
      }
    } else if (xp >= 1000) {
      final thousands = xp / 1000;
      if (thousands == thousands.toInt().toDouble()) {
        return '${thousands.toInt()}k';
      } else {
        return '${thousands.toStringAsFixed(1)}k';
      }
    } else {
      return _formatNumber(xp);
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    return number.toString();
  }

  String _buildFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    
    final baseUrl = AppConfig.apiBaseUrl;
    if (imageUrl.startsWith('/')) {
      return '$baseUrl$imageUrl';
    } else {
      return '$baseUrl/$imageUrl';
    }
  }

  Widget _buildDefaultAvatar(LeaderboardEntry entry) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemBlue,
            CupertinoColors.systemPurple,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: CupertinoColors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String userName;
  final int totalXP;
  final int weeklyXP;
  final String levelLabel;
  final String? profileImageUrl;

  const LeaderboardEntry({
    required this.rank,
    required this.userName,
    required this.totalXP,
    required this.weeklyXP,
    required this.levelLabel,
    this.profileImageUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> m, int indexFallback) {
    // Extract level information
    String levelLabel = '-';
    if (m['currentLevel'] != null) {
      final level = m['currentLevel'] as Map<String, dynamic>;
      levelLabel = level['fullDisplayName'] ?? level['displayName'] ?? level['turkishName'] ?? '-';
    }
    
    // Try different possible profile image fields from API
    String? profileImageUrl = m['profileImageUrl'] as String? ?? 
                             m['profilePicture'] as String? ?? 
                             m['avatar'] as String? ?? 
                             m['imageUrl'] as String?;
    
    return LeaderboardEntry(
      rank: (m['rank'] ?? indexFallback) as int,
      userName: (m['userName'] ?? 'Kullanıcı').toString(),
      totalXP: ((m['totalXP'] ?? 0) as num).toInt(),
      weeklyXP: ((m['weeklyXP'] ?? 0) as num).toInt(),
      levelLabel: levelLabel,
      profileImageUrl: profileImageUrl,
    );
  }

  /// Creates a copy of this entry with the given fields replaced with new values
  LeaderboardEntry copyWith({
    int? rank,
    String? userName,
    int? totalXP,
    int? weeklyXP,
    String? levelLabel,
    String? profileImageUrl,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      userName: userName ?? this.userName,
      totalXP: totalXP ?? this.totalXP,
      weeklyXP: weeklyXP ?? this.weeklyXP,
      levelLabel: levelLabel ?? this.levelLabel,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry &&
        other.rank == rank &&
        other.userName == userName &&
        other.totalXP == totalXP &&
        other.weeklyXP == weeklyXP &&
        other.levelLabel == levelLabel &&
        other.profileImageUrl == profileImageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      rank,
      userName,
      totalXP,
      weeklyXP,
      levelLabel,
      profileImageUrl,
    );
  }

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, userName: $userName, totalXP: $totalXP, weeklyXP: $weeklyXP, levelLabel: $levelLabel, profileImageUrl: $profileImageUrl)';
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late final GameService _gameService;
  late Future<List<LeaderboardEntry>> _future;
  LeaderboardSort _sort = LeaderboardSort.allTime;

  @override
  void initState() {
    super.initState();
    _gameService = getIt<GameService>();
    _future = _load();
  }

  Future<List<LeaderboardEntry>> _load() async {
    final raw = await _gameService.getLeaderboard();
    final list = <LeaderboardEntry>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is Map<String, dynamic>) {
        // Debug: Print the raw API response to see available fields
        print('🔍 Leaderboard item $i: $item');
        list.add(LeaderboardEntry.fromJson(item, i + 1));
      }
    }
    return _applySort(list);
  }

  List<LeaderboardEntry> _applySort(List<LeaderboardEntry> list) {
    final entries = List<LeaderboardEntry>.from(list);
    if (_sort == LeaderboardSort.weekly) {
      entries.sort((a, b) => b.weeklyXP.compareTo(a.weeklyXP));
    } else {
      entries.sort((a, b) => b.totalXP.compareTo(a.totalXP));
    }
    
    // Re-rank after sort using copyWith for cleaner code
    return entries.asMap().entries.map((entry) {
      return entry.value.copyWith(rank: entry.key + 1);
    }).toList();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFFFF8E1), // Light yellow background like the example
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Popular Live Ranking',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.label,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: const Color(0xFFFFF8E1),
        border: null,
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8E1), // Light yellow
              Color(0xFFFFFBF0), // Slightly lighter yellow
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: FutureBuilder<List<LeaderboardEntry>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _LeaderboardSkeleton();
            }
            if (snapshot.hasError) {
              return _errorState(context, 'Liderlik tablosu yüklenemedi');
            }
            final entries = snapshot.data ?? const <LeaderboardEntry>[];
            if (entries.isEmpty) {
              return _emptyState(context);
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              color: CupertinoColors.systemBlue,
              backgroundColor: CupertinoColors.white,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSortSegmented(),
                          const SizedBox(height: 24),
                          _buildPodium(entries),
                          const SizedBox(height: 20),
                          _buildSectionHeader(),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final e = entries[index];
                        final xpValue = _sort == LeaderboardSort.allTime ? e.totalXP : e.weeklyXP;
                        return LeaderboardCard(
                          entry: e,
                          xpValue: xpValue,
                          onTap: () {
                            // TODO: Navigate to user profile
                          },
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> entries) {
    final top = entries.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          // Glassmorphism effect
          BoxShadow(
            color: CupertinoColors.white.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              top.length,
              (index) {
                final entry = top[index];
                final rank = index + 1;
                final xpValue = _sort == LeaderboardSort.allTime ? entry.totalXP : entry.weeklyXP;
                
                return PodiumCard(
                  entry: entry,
                  rank: rank,
                  isFirst: rank == 1,
                  xpValue: xpValue,
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Diğer Sıralamalar',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          Text(
            '${_sort == LeaderboardSort.allTime ? 'Tüm Zamanlar' : 'Haftalık'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.secondaryLabel,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildSortSegmented() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoSlidingSegmentedControl<LeaderboardSort>(
        groupValue: _sort,
        backgroundColor: CupertinoColors.systemBackground,
        thumbColor: CupertinoColors.systemBlue,
        padding: const EdgeInsets.all(2),
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _sort = value;
              _future = _load();
            });
          }
        },
        children: {
          LeaderboardSort.allTime: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.star_fill,
                  size: 12,
                  color: _sort == LeaderboardSort.allTime 
                    ? CupertinoColors.white 
                    : CupertinoColors.systemBlue,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child:                 Text(
                  'Tüm Zamanlar',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _sort == LeaderboardSort.allTime 
                      ? CupertinoColors.white 
                      : CupertinoColors.systemBlue,
                    letterSpacing: -0.2,
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                ),
              ],
            ),
          ),
          LeaderboardSort.weekly: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.calendar,
                  size: 12,
                  color: _sort == LeaderboardSort.weekly 
                    ? CupertinoColors.white 
                    : CupertinoColors.systemBlue,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child:                 Text(
                  'Haftalık',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _sort == LeaderboardSort.weekly 
                      ? CupertinoColors.white 
                      : CupertinoColors.systemBlue,
                    letterSpacing: -0.2,
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }


  Widget _emptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CupertinoColors.systemBlue, CupertinoColors.systemPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemBlue.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.star_fill,
                size: 40,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz liderlik verisi yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.label,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk sıralamayı sen oluştur!',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.secondaryLabel,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState(BuildContext context, String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [CupertinoColors.systemRed, CupertinoColors.systemOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemRed.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle,
                color: CupertinoColors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.label,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: _refresh,
              child: const Text(
                'Tekrar Dene',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern shimmer skeleton loading with glassmorphism effects
class _LeaderboardSkeleton extends StatefulWidget {
  const _LeaderboardSkeleton();
  
  @override
  State<_LeaderboardSkeleton> createState() => _LeaderboardSkeletonState();
}

class _LeaderboardSkeletonState extends State<_LeaderboardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              children: [
                // Sort segmented skeleton
                _buildShimmerContainer(
                  height: 44,
                  borderRadius: 22,
                ),
                const SizedBox(height: 24),
                // Podium skeleton
                _buildShimmerContainer(
                  height: 200,
                  borderRadius: 20,
                ),
                const SizedBox(height: 20),
                // Section header skeleton
                _buildShimmerContainer(
                  height: 44,
                  borderRadius: 16,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.separated(
            itemCount: 8,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildShimmerCard();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerContainer({
    required double height,
    required double borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                CupertinoColors.systemGrey5.withOpacity(0.3),
                CupertinoColors.systemGrey5.withOpacity(0.7),
                CupertinoColors.systemGrey5.withOpacity(0.3),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerCard() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: 82,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                CupertinoColors.systemGrey5.withOpacity(0.3),
                CupertinoColors.systemGrey5.withOpacity(0.7),
                CupertinoColors.systemGrey5.withOpacity(0.3),
              ],
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Rank skeleton
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 16),
                // Profile picture skeleton
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(width: 16),
                // Content skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 16,
                        width: 120,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey4.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey4.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // XP skeleton
                Container(
                  height: 16,
                  width: 60,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}




