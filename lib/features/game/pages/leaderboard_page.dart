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

  @override
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
                width: isFirst ? 102 : 94,
                height: isFirst ? 102 : 94,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [CupertinoColors.systemIndigo, CupertinoColors.systemBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.systemGrey5,
                  ),
                  child: ClipOval(
                    child: entry.profileImageUrl != null && entry.profileImageUrl!.isNotEmpty
                      ? Image.network(
                          _buildFullImageUrl(entry.profileImageUrl!),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) =>
                            loadingProgress == null ? child : Center(child: CupertinoActivityIndicator(color: CupertinoColors.systemOrange)),
                          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(entry, isFirst),
                        )
                      : _buildDefaultAvatar(entry, isFirst),
                  ),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.white,
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Rank pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3C4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: CupertinoColors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          
          // User Name
          SizedBox(
            width: 90,
            child: Text(
              entry.userName,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
          
          // XP Value
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatXP(xpValue),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: CupertinoColors.systemOrange,
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (entry.isCurrentUser) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: CupertinoColors.systemOrange.withOpacity(0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Sen',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.systemOrange,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemIndigo,
            CupertinoColors.systemBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: isFirst ? 40 : 36,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.white,
            letterSpacing: -0.5,
            decoration: TextDecoration.none,
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
  final bool isCurrentUser;

  const LeaderboardCard({
    super.key,
    required this.entry,
    required this.xpValue,
    this.onTap,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isCurrentUser
        ? CupertinoColors.systemOrange.withOpacity(0.18)
        : CupertinoColors.white.withOpacity(0.9);
    final border = isCurrentUser
        ? Border.all(color: CupertinoColors.systemOrange.withOpacity(0.6), width: 1.2)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: border,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCurrentUser 
                      ? CupertinoColors.systemOrange 
                      : CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    entry.rank.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isCurrentUser 
                          ? CupertinoColors.white 
                          : CupertinoColors.black,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Profile Picture with gradient ring
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [CupertinoColors.systemIndigo, CupertinoColors.systemBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.systemGrey5,
                  ),
                  child: ClipOval(
                    child: entry.profileImageUrl != null && entry.profileImageUrl!.isNotEmpty
                        ? Image.network(
                            _buildFullImageUrl(entry.profileImageUrl!),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CupertinoActivityIndicator(color: CupertinoColors.systemOrange),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(entry),
                          )
                        : _buildDefaultAvatar(entry),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // User Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      entry.userName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.levelLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.secondaryLabel,
                        decoration: TextDecoration.none,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemOrange.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Sen',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: CupertinoColors.systemOrange,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // XP Value
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatXP(xpValue),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CupertinoColors.systemOrange,
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemIndigo,
            CupertinoColors.systemBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.white,
            letterSpacing: -0.5,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

class _NeighborRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final int xpValue;

  const _NeighborRow({
    required this.entry,
    required this.xpValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#${entry.rank}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.black,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.userName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_formatNeighborXP(xpValue)} XP',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemOrange,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNeighborXP(int xp) {
  if (xp >= 1000000) {
    final millions = xp / 1000000;
    return millions == millions.toInt().toDouble()
        ? '${millions.toInt()}M'
        : '${millions.toStringAsFixed(1)}M';
  }
  if (xp >= 1000) {
    final thousands = xp / 1000;
    return thousands == thousands.toInt().toDouble()
        ? '${thousands.toInt()}k'
        : '${thousands.toStringAsFixed(1)}k';
  }
  return xp.toString();
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String userName;
  final int totalXP;
  final int weeklyXP;
  final int monthlyXP;
  final int currentStreak;
  final String levelLabel;
  final String? profileImageUrl;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.userName,
    required this.totalXP,
    required this.weeklyXP,
    required this.monthlyXP,
    required this.currentStreak,
    required this.levelLabel,
    this.profileImageUrl,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromApi(LeaderboardApiEntry api) {
    return LeaderboardEntry(
      rank: api.rank,
      userId: api.userId,
      userName: api.userName,
      totalXP: api.totalXP,
      weeklyXP: api.weeklyXP,
      monthlyXP: api.monthlyXP,
      currentStreak: api.currentStreak,
      levelLabel: api.levelLabel ?? '-',
      profileImageUrl: api.profilePictureUrl,
      isCurrentUser: api.isCurrentUser,
    );
  }

  LeaderboardEntry copyWith({
    int? rank,
    String? userId,
    String? userName,
    int? totalXP,
    int? weeklyXP,
    int? monthlyXP,
    int? currentStreak,
    String? levelLabel,
    String? profileImageUrl,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      totalXP: totalXP ?? this.totalXP,
      weeklyXP: weeklyXP ?? this.weeklyXP,
      monthlyXP: monthlyXP ?? this.monthlyXP,
      currentStreak: currentStreak ?? this.currentStreak,
      levelLabel: levelLabel ?? this.levelLabel,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LeaderboardEntry &&
        other.rank == rank &&
        other.userId == userId &&
        other.userName == userName &&
        other.totalXP == totalXP &&
        other.weeklyXP == weeklyXP &&
        other.monthlyXP == monthlyXP &&
        other.currentStreak == currentStreak &&
        other.levelLabel == levelLabel &&
        other.profileImageUrl == profileImageUrl &&
        other.isCurrentUser == isCurrentUser;
  }

  @override
  int get hashCode {
    return Object.hash(
      rank,
      userId,
      userName,
      totalXP,
      weeklyXP,
      monthlyXP,
      currentStreak,
      levelLabel,
      profileImageUrl,
      isCurrentUser,
    );
  }

  @override
  String toString() {
    return 'LeaderboardEntry(rank: $rank, userId: $userId, userName: $userName, totalXP: $totalXP, weeklyXP: $weeklyXP, levelLabel: $levelLabel, isCurrentUser: $isCurrentUser)';
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late final GameService _gameService;
  final ScrollController _scrollController = ScrollController();
  LeaderboardSort _sort = LeaderboardSort.allTime;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String? _errorMessage;

  List<LeaderboardEntry> _entries = <LeaderboardEntry>[];
  LeaderboardEntry? _currentUserEntry;
  List<LeaderboardEntry> _surroundingEntries = <LeaderboardEntry>[];
  int? _nextOffset;

  @override
  void initState() {
    super.initState();
    _gameService = getIt<GameService>();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial({bool showSkeleton = true}) async {
    if (showSkeleton) {
      setState(() {
        _isInitialLoading = true;
        _hasError = false;
        _errorMessage = null;
      });
    } else {
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
    }

    try {
      final response = await _gameService.getLeaderboardPage(
        range: _rangeParam,
        offset: 0,
        limit: 20,
        surrounding: 2,
      );

      final entries = response.items.map(LeaderboardEntry.fromApi).toList();
      final currentUser = response.currentUser != null
          ? LeaderboardEntry.fromApi(response.currentUser!)
          : null;
      final surrounding = response.surrounding
          .map(LeaderboardEntry.fromApi)
          .where((entry) => currentUser == null || entry.userId != currentUser.userId)
          .toList()
        ..sort((a, b) => a.rank.compareTo(b.rank));

      setState(() {
        _entries = entries;
        _currentUserEntry = currentUser;
        _surroundingEntries = surrounding;
        _nextOffset = response.nextOffset;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } catch (error, stackTrace) {
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        _hasError = true;
        _errorMessage = 'Liderlik tablosu yüklenemedi';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isInitialLoading || _nextOffset == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _gameService.getLeaderboardPage(
        range: _rangeParam,
        offset: _nextOffset!,
        limit: 50,
        surrounding: 0,
      );

      final incoming = response.items.map(LeaderboardEntry.fromApi).toList();
      final existingKeys = _entries.map((entry) => '${entry.rank}_${entry.userId}').toSet();
      final merged = List<LeaderboardEntry>.from(_entries)
        ..addAll(incoming.where((entry) => !existingKeys.contains('${entry.rank}_${entry.userId}')));

      setState(() {
        _entries = merged;
        _nextOffset = response.nextOffset;
        _isLoadingMore = false;
      });
    } catch (error, stackTrace) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadInitial(showSkeleton: false);
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _nextOffset == null || _isLoadingMore) return;
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 320) {
      _loadMore();
    }
  }

  String get _rangeParam => _sort == LeaderboardSort.allTime ? 'allTime' : 'weekly';

  int _getListItemCount() {
    // Show top 17 (20 minus podium 3) + surrounding if user is outside top 20
    final topCount = _entries.length > 3 ? _entries.length - 3 : 0;
    final userInTop20 = _currentUserEntry != null && _currentUserEntry!.rank <= 20;
    
    if (userInTop20 || _currentUserEntry == null || _surroundingEntries.isEmpty) {
      return topCount;
    }
    
    // User is outside top 20: show top list + surrounding band (gap rendered via separator)
    return topCount + _surroundingEntries.length;
  }

  bool _shouldShowGapBeforeIndex(int index) {
    final topCount = _entries.length > 3 ? _entries.length - 3 : 0;
    final userInTop20 = _currentUserEntry != null && _currentUserEntry!.rank <= 20;
    
    // Show gap right before the surrounding band starts
    return !userInTop20 && 
           _currentUserEntry != null && 
           _surroundingEntries.isNotEmpty && 
           index == topCount;
  }

  LeaderboardEntry? _getEntryAtListIndex(int index) {
    final topCount = _entries.length > 3 ? _entries.length - 3 : 0;
    final userInTop20 = _currentUserEntry != null && _currentUserEntry!.rank <= 20;
    
    if (userInTop20 || _currentUserEntry == null || _surroundingEntries.isEmpty) {
      // Show normal top list (ranks 4-20 or 4-end)
      return index < topCount ? _entries[index + 3] : null;
    }
    
    // User outside top 20: show top 17 (ranks 4-20), then gap, then surrounding band
    if (index < topCount) {
      return _entries[index + 3];
    }
    
    // After topCount, we show surrounding entries
    final surroundingIndex = index - topCount;
    return surroundingIndex < _surroundingEntries.length 
        ? _surroundingEntries[surroundingIndex] 
        : null;
  }

  Widget _buildGapDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  CupertinoColors.systemGrey3.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.withOpacity(0.8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(CupertinoIcons.ellipsis, size: 14, color: CupertinoColors.secondaryLabel),
                SizedBox(width: 6),
                Text(
                  'Senin Sıran',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.secondaryLabel,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  CupertinoColors.systemGrey3.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Leiderlik Tablosu',
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
              Color(0xFFFFF8E1),
              Color(0xFFFFFBF0),
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: _isInitialLoading
            ? const _LeaderboardSkeleton()
            : _hasError
                ? _errorState(context, _errorMessage ?? 'Liderlik tablosu yüklenemedi')
                : _entries.isEmpty
                    ? _emptyState(context)
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: CupertinoColors.systemOrange,
                        backgroundColor: CupertinoColors.white,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
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
                                    _buildPodium(_entries),
                                    if (_currentUserEntry != null) ...[
                                      const SizedBox(height: 20),
                                      _buildMyRankSection(),
                                    ],
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverList.separated(
                                itemCount: _getListItemCount(),
                                separatorBuilder: (context, index) {
                                  // Add gap before user's rank section if it's not in top list
                                  if (_shouldShowGapBeforeIndex(index)) {
                                    return Column(
                                      children: [
                                        const SizedBox(height: 12),
                                        _buildGapDivider(),
                                        const SizedBox(height: 12),
                                      ],
                                    );
                                  }
                                  return const SizedBox(height: 12);
                                },
                                itemBuilder: (context, index) {
                                  final entry = _getEntryAtListIndex(index);
                                  if (entry == null) return const SizedBox.shrink();
                                  
                                  final xpValue = _sort == LeaderboardSort.allTime ? entry.totalXP : entry.weeklyXP;
                                  return LeaderboardCard(
                                    entry: entry,
                                    xpValue: xpValue,
                                    isCurrentUser: entry.isCurrentUser,
                                    onTap: () {
                                      // TODO: Navigate to user profile
                                    },
                                  );
                                },
                              ),
                            ),
                            if (_isLoadingMore)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                  child: _buildLoadingMoreIndicator(),
                                ),
                              ),
                            const SliverToBoxAdapter(
                              child: SizedBox(height: 100),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _buildMyRankSection() {
    final me = _currentUserEntry;
    if (me == null || me.rank <= 20) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.systemOrange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CupertinoColors.systemOrange.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemOrange.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.person_crop_circle_badge_checkmark, size: 20, color: CupertinoColors.systemOrange),
              SizedBox(width: 8),
              Text(
                'Senin Sıran',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.label,
                  letterSpacing: -0.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CupertinoColors.systemOrange.withOpacity(0.4), width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [CupertinoColors.systemOrange, Color(0xFFFF9500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '#${me.rank}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: CupertinoColors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        me.userName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.label,
                          decoration: TextDecoration.none,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        me.levelLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: CupertinoColors.secondaryLabel,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemOrange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_sort == LeaderboardSort.allTime ? me.totalXP : me.weeklyXP} XP',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: CupertinoColors.systemOrange,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Center(
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: CupertinoColors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const CupertinoActivityIndicator(color: CupertinoColors.systemOrange),
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


  Widget _buildSortSegmented() {
    return Center(
      child: Container(
        height: 44,
        constraints: const BoxConstraints(maxWidth: 280),
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
          thumbColor: CupertinoColors.systemOrange,
          padding: const EdgeInsets.all(2),
          onValueChanged: (value) {
            if (value != null && value != _sort) {
              setState(() {
                _sort = value;
              });
              _loadInitial();
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
                    : CupertinoColors.systemOrange,
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
                      : CupertinoColors.systemOrange,
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
                    : CupertinoColors.systemOrange,
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
                      : CupertinoColors.systemOrange,
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




