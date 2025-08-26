import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/config/app_config.dart';
import '../../../game/services/game_service.dart';
import '../../../../core/widgets/badge_icon.dart';
import '../../../../core/widgets/badge_celebration.dart';

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
              final String? category = (m['category'] ?? m['Category'])?.toString();
              final String? rarity = (m['rarity'] ?? m['Rarity'])?.toString();
              final String? rarityColor = (m['rarityColor'] ?? m['RarityColor'])?.toString();
              final String? description = (m['description'] ?? m['Description'])?.toString();
              return _BadgeTile(name: name, description: description, imageUrl: imageUrl, earned: isEarned, category: category, rarity: rarity, rarityColor: rarityColor);
            },
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final String name;
  final String? description;
  final String? imageUrl;
  final bool earned;
  final String? category;
  final String? rarity;
  final String? rarityColor;

  const _BadgeTile({required this.name, this.description, required this.imageUrl, required this.earned, this.category, this.rarity, this.rarityColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (earned) {
          BadgeCelebration.show(context, name: name, subtitle: description ?? '', earned: true);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
          BadgeIcon(name: name, category: category, rarity: rarity, rarityColorHex: rarityColor, earned: earned, size: 44),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: earned ? Theme.of(context).colorScheme.onSurface : Colors.grey[600],
              ),
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
    ));
  }
}

String? _normalizeImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  if (path.startsWith('/')) return '${AppConfig.apiBaseUrl}$path';
  return '${AppConfig.apiBaseUrl}/$path';
}
