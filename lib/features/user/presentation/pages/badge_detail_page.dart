import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../game/domain/entities/badge.dart' as badge_entity;
import '../../../../core/widgets/badge_icon.dart';
import '../../../../core/widgets/badge_celebration.dart';

class BadgeDetailPage extends StatelessWidget {
  final badge_entity.Badge badge;

  const BadgeDetailPage({
    super.key,
    required this.badge,
  });

  Color _getRarityColor() {
    if (badge.rarityColorHex != null) {
      final color = _parseHexColor(badge.rarityColorHex!);
      if (color != null) return color;
    }
    
    switch (badge.rarity.toLowerCase()) {
      case 'legendary':
      case 'diamond':
        return Colors.cyan.shade400;
      case 'epic':
      case 'gold':
        return Colors.amber.shade600;
      case 'rare':
      case 'silver':
        return Colors.blue.shade400;
      case 'uncommon':
      case 'bronze':
        return Colors.orange.shade400;
      default:
        return Colors.grey.shade400;
    }
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

  String _getRarityLabel() {
    switch (badge.rarity.toLowerCase()) {
      case 'legendary':
      case 'diamond':
        return 'Efsanevi';
      case 'epic':
      case 'gold':
        return 'Epik';
      case 'rare':
      case 'silver':
        return 'Nadir';
      case 'uncommon':
      case 'bronze':
        return 'Yaygın';
      default:
        return 'Ortak';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _getRarityColor();
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Rozet Detayı'),
        elevation: 0,
        actions: [
          if (badge.isEarned)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => Share.share(
                '${badge.name} rozetini kazandım! 🏆\n${badge.description}',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Badge Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    rarityColor.withOpacity(0.1),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Badge Icon with Glow
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: badge.isEarned
                          ? RadialGradient(
                              colors: [
                                rarityColor.withOpacity(0.3),
                                rarityColor.withOpacity(0.1),
                                Colors.transparent,
                              ],
                            )
                          : null,
                      boxShadow: badge.isEarned
                          ? [
                              BoxShadow(
                                color: rarityColor.withOpacity(0.4),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ]
                          : null,
                    ),
                    child: BadgeIcon(
                      name: badge.name,
                      category: badge.category,
                      rarity: badge.rarity,
                      rarityColorHex: badge.rarityColorHex,
                      imageUrl: badge.imageUrl,
                      earned: badge.isEarned,
                      size: 140,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Badge Name
                  Text(
                    badge.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: badge.isEarned ? theme.colorScheme.onSurface : Colors.grey.shade700,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Rarity Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: rarityColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: rarityColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: rarityColor, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          _getRarityLabel(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: rarityColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Content Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description Card
                  _buildInfoCard(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'Açıklama',
                    content: badge.description,
                  ),
                  const SizedBox(height: 16),
                  
                  // Status Card
                  if (badge.isEarned)
                    _buildInfoCard(
                      context,
                      icon: Icons.celebration_rounded,
                      title: 'Kazanıldı',
                      content: badge.earnedAt != null
                          ? '${badge.earnedAt!.day}.${badge.earnedAt!.month}.${badge.earnedAt!.year} tarihinde kazanıldı'
                          : 'Kazanıldı',
                      color: Colors.green,
                    )
                  else if (badge.progress != null)
                    _buildProgressCard(context, badge.progress!, rarityColor)
                  else
                    _buildInfoCard(
                      context,
                      icon: Icons.lock_outline_rounded,
                      title: 'Kilitli',
                      content: badge.unlockMessage ?? 'Bu rozeti kazanmak için daha fazla çalışmanız gerekiyor.',
                      color: Colors.grey,
                    ),
                  
                  if (badge.motivationMessage != null && badge.motivationMessage!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      icon: Icons.favorite_rounded,
                      title: 'Motivasyon',
                      content: badge.motivationMessage!,
                      color: Colors.pink,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Category & Requirements
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          icon: Icons.category_rounded,
                          title: 'Kategori',
                          content: badge.category,
                          color: Colors.blue,
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          context,
                          icon: Icons.star_rounded,
                          title: 'Gerekli XP',
                          content: '${badge.requiredXP} XP',
                          color: Colors.orange,
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Action Buttons
                  if (badge.isEarned)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          BadgeCelebration.show(
                            context,
                            name: badge.name,
                            subtitle: badge.description,
                            imageUrl: badge.imageUrl,
                            rarity: badge.rarity,
                            rarityColorHex: badge.rarityColorHex,
                            earned: true,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rarityColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 8,
                        ),
                        icon: const Icon(Icons.celebration_rounded),
                        label: const Text(
                          'Kutlamayı Tekrar Göster',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    Color? color,
    bool compact = false,
  }) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: cardColor, size: compact ? 20 : 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, badge_entity.BadgeProgress progress, Color rarityColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            rarityColor.withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rarityColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: rarityColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, color: rarityColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'İlerleme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.displayText,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: rarityColor,
                ),
              ),
              Text(
                '${(progress.percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: progress.percentage),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bu rozeti kazanmak için ${progress.required - progress.current} adım daha!',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

