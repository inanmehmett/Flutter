import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../game/services/game_service.dart';

class LeaderboardPreview extends StatefulWidget {
  const LeaderboardPreview({super.key});

  @override
  State<LeaderboardPreview> createState() => _LeaderboardPreviewState();
}

class _LeaderboardPreviewState extends State<LeaderboardPreview> {
  late final GameService _gameService;
  late final Future<LeaderboardPageResponse> _future;

  @override
  void initState() {
    super.initState();
    _gameService = getIt<GameService>();
    _future = _gameService.getLeaderboardPage(limit: 6, surrounding: 0);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LeaderboardPageResponse>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LeaderboardSkeleton();
        }
        if (snapshot.hasError) {
          return _errorCard('Liderlik tablosu yüklenemedi');
        }
        final page = snapshot.data;
        final entries = page?.items.take(3).toList() ?? const <LeaderboardApiEntry>[];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Liderlik', style: TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
                      child: const Text('Tümü'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...entries.map((entry) {
                  final medal = entry.rank == 1
                      ? '🥇'
                      : entry.rank == 2
                          ? '🥈'
                          : '🥉';
                  final xpText = entry.totalXP >= 1000
                      ? '${(entry.totalXP / 1000).toStringAsFixed(1)}k XP'
                      : '${entry.totalXP} XP';
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blue.shade50,
                      child: Text(medal, style: const TextStyle(fontSize: 18)),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.userName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (entry.isCurrentUser)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Sen',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.deepOrange),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(entry.levelLabel ?? '-', style: TextStyle(color: Colors.grey.shade600)),
                    trailing: Text(xpText, style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w600)),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _errorCard(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardSkeleton extends StatelessWidget {
  const _LeaderboardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 100, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Container(height: 12, color: Colors.grey.shade200)),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}


