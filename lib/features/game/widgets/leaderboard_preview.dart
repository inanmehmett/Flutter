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
  late final Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _gameService = getIt<GameService>();
    _future = _gameService.getLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LeaderboardSkeleton();
        }
        if (snapshot.hasError) {
          return _errorCard('Liderlik tablosu yüklenemedi');
        }
        final entries = (snapshot.data ?? const []).take(3).toList();
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.leaderboard, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text('Liderlik', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    TextButton(onPressed: () => Navigator.pushNamed(context, '/leaderboard'), child: const Text('Tümü')),
                  ],
                ),
                const SizedBox(height: 8),
                ...entries.map((e) {
                  final m = e as Map<String, dynamic>;
                  final rank = m['rank'] ?? m['Rank'] ?? 0;
                  final user = (m['userName'] ?? m['UserName'] ?? 'Kullanıcı').toString();
                  final xp = m['totalXP'] ?? m['TotalXP'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 14, child: Text(rank.toString())),
                        const SizedBox(width: 8),
                        Expanded(child: Text(user, overflow: TextOverflow.ellipsis)),
                        Text('$xp XP', style: TextStyle(color: Colors.grey[700])),
                      ],
                    ),
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


