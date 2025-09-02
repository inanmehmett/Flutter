import 'package:flutter/material.dart';
import '../../../core/di/injection.dart';
import '../services/game_service.dart';

enum LeaderboardSort { allTime, weekly }

class LeaderboardEntry {
  final int rank;
  final String userName;
  final int totalXP;
  final int weeklyXP;
  final String levelLabel;

  const LeaderboardEntry({
    required this.rank,
    required this.userName,
    required this.totalXP,
    required this.weeklyXP,
    required this.levelLabel,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> m, int indexFallback) {
    return LeaderboardEntry(
      rank: (m['rank'] ?? m['Rank'] ?? indexFallback) as int,
      userName: (m['userName'] ?? m['UserName'] ?? 'Kullanıcı').toString(),
      totalXP: ((m['totalXP'] ?? m['TotalXP'] ?? 0) as num).toInt(),
      weeklyXP: ((m['weeklyXP'] ?? m['WeeklyXP'] ?? 0) as num).toInt(),
      levelLabel: (m['currentLevel'] ?? m['CurrentLevel'] ?? '-').toString(),
    );
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
    for (var i = 0; i < entries.length; i++) {
      // re-rank after sort
      final e = entries[i];
      entries[i] = LeaderboardEntry(
        rank: i + 1,
        userName: e.userName,
        totalXP: e.totalXP,
        weeklyXP: e.weeklyXP,
        levelLabel: e.levelLabel,
      );
    }
    return entries;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liderlik Tablosu'),
      ),
      body: FutureBuilder<List<LeaderboardEntry>>(
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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSortSegmented(),
                        const SizedBox(height: 12),
                        _buildPodium(entries),
                        const SizedBox(height: 8),
                        Text(
                          _sort == LeaderboardSort.allTime ? 'Tüm Zamanlar' : 'Haftalık Sıralama',
                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList.separated(
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return ListTile(
                      leading: _buildRankAvatar(e.rank),
                      title: Text(e.userName, overflow: TextOverflow.ellipsis),
                      subtitle: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _chip(text: e.levelLabel, color: Colors.indigo),
                          _chip(text: '${e.weeklyXP} XP/hafta', color: Colors.teal),
                        ],
                      ),
                      trailing: Text(
                        '${e.totalXP} XP',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _chip({required String text, required Color color}) {
    final Color textColor = (color is MaterialColor) ? (color as MaterialColor).shade700 : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildRankAvatar(int rank) {
    Color bg;
    IconData icon = Icons.emoji_events;
    switch (rank) {
      case 1:
        bg = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        bg = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        bg = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        bg = Colors.grey.shade300;
        icon = Icons.tag;
    }
    return CircleAvatar(
      backgroundColor: bg.withOpacity(0.8),
      child: rank <= 3 ? Icon(icon, color: Colors.white) : Text(rank.toString()),
    );
  }

  Widget _buildSortSegmented() {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<LeaderboardSort>(
            segments: const <ButtonSegment<LeaderboardSort>>[
              ButtonSegment(value: LeaderboardSort.allTime, label: Text('Tüm Zamanlar'), icon: Icon(Icons.all_inclusive)),
              ButtonSegment(value: LeaderboardSort.weekly, label: Text('Haftalık'), icon: Icon(Icons.calendar_view_week)),
            ],
            selected: <LeaderboardSort>{_sort},
            onSelectionChanged: (set) {
              final value = set.first;
              setState(() {
                _sort = value;
                _future = _load();
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> entries) {
    final top = entries.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.blue.shade100.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < top.length; i++) _podiumTile(top[i], i),
        ],
      ),
    );
  }

  Widget _podiumTile(LeaderboardEntry e, int index) {
    final isFirst = e.rank == 1;
    final color = isFirst ? const Color(0xFFFFD700) : (e.rank == 2 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));
    return Column(
      children: [
        CircleAvatar(radius: 24, backgroundColor: color.withOpacity(0.85), child: const Icon(Icons.emoji_events, color: Colors.white)),
        const SizedBox(height: 8),
        SizedBox(
          width: 100,
          child: Text(e.userName, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 4),
        Text('${_sort == LeaderboardSort.allTime ? e.totalXP : e.weeklyXP} XP', style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.leaderboard_outlined, size: 48, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          const Text('Henüz liderlik verisi yok'),
        ],
      ),
    );
  }

  Widget _errorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _refresh,
            child: const Text('Tekrar dene'),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 8,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        return ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
          ),
          title: Container(height: 14, color: Colors.grey.shade200),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Container(height: 12, color: Colors.grey.shade200),
          ),
          trailing: Container(width: 56, height: 14, color: Colors.grey.shade200),
        );
      },
    );
  }
}


