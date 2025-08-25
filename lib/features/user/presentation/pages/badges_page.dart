import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/config/app_config.dart';
import '../../../game/services/game_service.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  late final GameService _gameService;
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _gameService = getIt<GameService>();
    _future = _gameService.getBadges();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tüm Rozetler')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (items.isEmpty) {
            return const Center(child: Text('Henüz rozet bulunamadı'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final m = items[index] as Map<String, dynamic>;
              final String name = (m['name'] ?? m['Name'] ?? '').toString();
              final String? imageUrl = _normalizeImageUrl((m['imageUrl'] ?? m['ImageUrl']) as String?);
              final bool isEarned = ((m['isEarned'] ?? m['IsEarned']) as bool?) ?? false;
              return _BadgeTile(name: name, imageUrl: imageUrl, earned: isEarned);
            },
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final bool earned;

  const _BadgeTile({required this.name, required this.imageUrl, required this.earned});

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imageUrl != null && imageUrl!.isNotEmpty)
            SizedBox(
              width: 44,
              height: 44,
              child: Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.emoji_events,
                  size: 44,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else
            Icon(Icons.emoji_events, size: 44, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            earned ? 'Kazanıldı' : 'Kazanılmadı',
            style: TextStyle(
              fontSize: 10,
              color: earned ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

String? _normalizeImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  if (path.startsWith('/')) return '${AppConfig.apiBaseUrl}$path';
  return '${AppConfig.apiBaseUrl}/$path';
}
