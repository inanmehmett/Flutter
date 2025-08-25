import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/di/injection.dart';
import '../../game/services/game_service.dart';

class BadgesPreview extends StatefulWidget {
  const BadgesPreview({super.key});

  @override
  State<BadgesPreview> createState() => _BadgesPreviewState();
}

class _BadgesPreviewState extends State<BadgesPreview> {
  late final GameService _gameService;
  late final Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _gameService = getIt<GameService>();
    _future = _gameService.getBadges();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _BadgesSkeleton();
        }
        if (snapshot.hasError) {
          return _errorCard('Rozetler yüklenemedi');
        }
        final badges = snapshot.data ?? const [];
        final earned = badges.where((b) {
          final map = b as Map<String, dynamic>;
          return (map['isEarned'] == true) || (map['earnedAt'] != null && map['earnedAt'].toString().isNotEmpty);
        }).length;
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: Colors.amber.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events, color: Colors.amber),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rozetler', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('$earned / ${badges.length} kazanıldı', style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/badges'),
                  child: const Text('Görüntüle'),
                ),
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

class _BadgesSkeleton extends StatelessWidget {
  const _BadgesSkeleton();
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 14, width: 120, color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  Container(height: 8, width: 160, color: Colors.grey.shade200),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


