import 'package:flutter/material.dart';

class BadgeIcon extends StatelessWidget {
  final String? name;
  final String? category;
  final String? rarity;
  final String? rarityColorHex;
  final bool earned;
  final double size;
  final String? imageUrl;

  const BadgeIcon({
    super.key,
    this.name,
    this.category,
    this.rarity,
    this.rarityColorHex,
    required this.earned,
    this.size = 44,
    this.imageUrl,
  });

  // Static mapping for specific badge names -> fixed icons
  static const Map<String, IconData> _nameIconOverrides = {
    // keys must be normalized (lowercase, Turkish chars simplified)
    'hiz ustasi': Icons.speed_rounded,
    'hiz ustası': Icons.speed_rounded,
    'hiz sampiyonu': Icons.speed_rounded,
    'dogruluk ustasi': Icons.track_changes_rounded,
    'dogruluk ustası': Icons.track_changes_rounded,
    'dogruluk sampiyonu': Icons.track_changes_rounded,
    // Early bird / night owl / careful reader
    'erken kus': Icons.wb_sunny_rounded,
    'erken kuş': Icons.wb_sunny_rounded,
    'gece kusu': Icons.nights_stay_rounded,
    'gece kuşu': Icons.nights_stay_rounded,
    'dikkatli okuyucu': Icons.fact_check_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final Color ringColor = _ringColor(context);
    final IconData emblem = _iconForCategory();
    final Color emblemColor = earned ? Theme.of(context).colorScheme.primary : Colors.grey.shade500;
    final double borderWidth = size * 0.08;
    final Color ring = earned ? ringColor : ringColor.withOpacity(0.35);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: ring, width: borderWidth),
              boxShadow: [
                BoxShadow(color: ring.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
          ),
          if (imageUrl != null && imageUrl!.isNotEmpty)
            ClipOval(
              child: Image.network(
                imageUrl!,
                width: size * 0.64,
                height: size * 0.64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  emblem,
                  color: emblemColor.withOpacity(earned ? 1.0 : 0.5),
                  size: size * 0.52,
                ),
              ),
            )
          else
            Icon(
              emblem,
              color: emblemColor.withOpacity(earned ? 1.0 : 0.5),
              size: size * 0.52,
            ),
        ],
      ),
    );
  }

  IconData _iconForCategory() {
    // First, try explicit name overrides
    final normalizedName = _normalizeText(name ?? '');
    if (_nameIconOverrides.containsKey(normalizedName)) {
      return _nameIconOverrides[normalizedName]!;
    }

    final key = _inferCategory().toLowerCase();
    // Turkish keyword alignments for better visual semantics
    if (key.contains('hız') || key.contains('hiz') || key.contains('speed') || key.contains('fast')) return Icons.speed_rounded;
    if (key.contains('doğruluk') || key.contains('dogruluk') || key.contains('accuracy') || key.contains('doğrul') || key.contains('dogrul')) return Icons.track_changes_rounded;
    if (key.contains('read')) return Icons.menu_book_rounded;
    if (key.contains('quiz') || key.contains('test')) return Icons.quiz_rounded;
    if (key.contains('streak') || key.contains('fire')) return Icons.local_fire_department_rounded;
    if (key.contains('daily') || key.contains('goal')) return Icons.event_available_rounded;
    if (key.contains('secret')) return Icons.lock_rounded;
    if (key.contains('special')) return Icons.auto_awesome_rounded;
    if (key.contains('time')) return Icons.av_timer_rounded;
    if (key.contains('speed')) return Icons.speed_rounded;
    if (key.contains('listen')) return Icons.hearing_rounded;
    if (key.contains('vocab') || key.contains('word')) return Icons.spellcheck_rounded;
    if (key.contains('level')) return Icons.stairs_rounded;
    if (key.contains('leader')) return Icons.emoji_events_rounded;
    return Icons.emoji_events_rounded;
  }

  Color _ringColor(BuildContext context) {
    // Try explicit color from server
    final fromServer = _parseHexColor(rarityColorHex);
    if (fromServer != null) return fromServer;
    // Try infer rarity from provided rarity or name keywords
    final inferred = (rarity ?? _rarityFromName()).toLowerCase();
    switch (inferred) {
      case 'legendary':
        return Colors.amber.shade600;
      case 'epic':
        return Colors.purple.shade400;
      case 'rare':
        return Colors.blue.shade400;
      case 'uncommon':
        return Colors.teal.shade400;
      case 'common':
      default:
        return Colors.grey.shade400;
    }
  }

  String _rarityFromName() {
    final text = (name ?? '').toLowerCase();
    if (text.contains('immortal') || text.contains('efsanevi') || text.contains('legendary')) return 'legendary';
    if (text.contains('legend')) return 'legendary';
    if (text.contains('master') || text.contains('usta') || text.contains('şampiyon')) return 'epic';
    if (text.contains('epic')) return 'epic';
    if (text.contains('expert') || text.contains('doğruluk') || text.contains('hız')) return 'rare';
    if (text.contains('tutkunu') || text.contains('collector') || text.contains('koleksiyoncusu')) return 'uncommon';
    // Level badges: scale by CEFR
    if (text.startsWith('c')) return 'epic';
    if (text.startsWith('b')) return 'rare';
    return 'common';
  }

  String _inferCategory() {
    if (category != null && category!.isNotEmpty) return category!;
    final text = (name ?? '').toLowerCase();
    if (text.contains('quiz')) return 'quiz';
    if (text.contains('okuma') || text.contains('reading')) return 'reading';
    if (text.contains('kelime') || text.contains('vocab') || text.contains('word')) return 'vocabulary';
    if (text.contains('gün') || text.contains('streak') || text.contains('seri')) return 'streak';
    if (text.contains('erken kuş') || text.contains('sabah')) return 'daily';
    if (text.contains('gece kuşu') || text.contains('gece')) return 'daily';
    if (text.contains('hafta sonu') || text.contains('tatil')) return 'special';
    if (text.contains('lider') || text.contains('top') || text.contains('#1')) return 'leaderboard';
    if (text.contains('gizli') || text.contains('secret')) return 'secret';
    if (RegExp(r'^[abc][12]\.[123]').hasMatch(text)) return 'level';
    return 'special';
  }

  String _normalizeText(String input) {
    final lower = input.toLowerCase();
    return lower
        .replaceAll('ı', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return null;
  }
}


