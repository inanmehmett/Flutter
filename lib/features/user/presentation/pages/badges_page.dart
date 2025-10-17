import 'package:flutter/material.dart';
import 'dart:math' as math;
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
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade100, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 18,
                childAspectRatio: 0.72,
                mainAxisExtent: 176,
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
            ),
          );
        },
      ),
    );
  }
}

class _BadgeTile extends StatefulWidget {
  final String name;
  final String? description;
  final String? imageUrl;
  final bool earned;
  final String? category;
  final String? rarity;
  final String? rarityColor;

  const _BadgeTile({required this.name, this.description, required this.imageUrl, required this.earned, this.category, this.rarity, this.rarityColor});

  @override
  State<_BadgeTile> createState() => _BadgeTileState();
}

class _BadgeTileState extends State<_BadgeTile> with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Color _auraBase(ColorScheme scheme) {
    final String key = (widget.category ?? widget.rarity ?? '').toLowerCase();
    if (widget.rarityColor != null && widget.rarityColor!.isNotEmpty) {
      final c = _parseHexColor(widget.rarityColor!);
      if (c != null) return c;
    }
    if (key.contains('quiz')) return Colors.deepPurpleAccent;
    if (key.contains('read')) return Colors.lightBlueAccent;
    if (key.contains('streak') || key.contains('fire')) return Colors.orangeAccent;
    if (key.contains('daily')) return Colors.tealAccent;
    if (key.contains('rare')) return Colors.blueAccent;
    if (key.contains('epic')) return Colors.purpleAccent;
    if (key.contains('legend')) return Colors.amber;
    return scheme.primary;
  }

  Color? _parseHexColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '').trim();
      if (cleaned.length == 6) {
        return Color(int.parse('FF$cleaned', radix: 16));
      }
      if (cleaned.length == 8) {
        return Color(int.parse(cleaned, radix: 16));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool hasDescription = widget.description != null && widget.description!.trim().isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxHeight < 160;
        final double circle = compact ? 50 : 56;
        final double iconSize = compact ? 36 : 40;
        final double nameFont = 12;
        final int nameMaxLines = 2;
        final bool showDescription = hasDescription && !compact;
        final Color aura = _auraBase(scheme);
        final double shakeDx = math.sin(_shakeController.value * math.pi * 6) * 3.0;
        final Widget content = Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: circle,
                  height: circle,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        aura.withValues(alpha: widget.earned ? 0.25 : 0.10),
                        aura.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: aura.withValues(alpha: widget.earned ? 0.25 : 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: BadgeIcon(
                      name: widget.name,
                      category: widget.category,
                      rarity: widget.rarity,
                      rarityColorHex: widget.rarityColor,
                      imageUrl: widget.imageUrl,
                      earned: widget.earned,
                      size: iconSize,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    widget.name,
                    maxLines: nameMaxLines,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: nameFont,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.1,
                      color: widget.earned ? scheme.onSurface : Colors.grey[700],
                      decoration: TextDecoration.none,
                      decorationColor: Colors.transparent,
                    ),
                  ),
                ),
                if (showDescription) ...[
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.15,
                        color: Colors.grey[600],
                        decoration: TextDecoration.none,
                        decorationColor: Colors.transparent,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.earned ? aura.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: widget.earned ? aura.withValues(alpha: 0.24) : Colors.grey.withValues(alpha: 0.16), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.earned ? Icons.verified_rounded : Icons.lock_outline_rounded,
                        size: 14,
                        color: widget.earned ? aura : Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.earned ? 'Kazanıldı' : 'Kilitli',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: widget.earned ? aura : Colors.grey[700],
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        final transformed = Transform.translate(
          offset: Offset(widget.earned ? 0 : shakeDx, 0),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: content,
          ),
        );

        final Widget interactive = InkWell(
          onTap: () {
            if (widget.earned) {
              BadgeCelebration.show(context, name: widget.name, subtitle: widget.description ?? '', earned: true);
            } else {
              _shakeController.forward(from: 0);
            }
          },
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(12),
          child: transformed,
        );

        if (!widget.earned && !_pressed) {
          return ColorFiltered(colorFilter: const ColorFilter.matrix([
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]), child: interactive);
        }
        return interactive;
      },
    );
  }
}

String? _normalizeImageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  if (path.startsWith('/')) return '${AppConfig.apiBaseUrl}$path';
  return '${AppConfig.apiBaseUrl}/$path';
}
