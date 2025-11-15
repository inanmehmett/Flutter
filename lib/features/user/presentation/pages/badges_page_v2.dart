import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../../core/di/injection.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/network_manager.dart';
import '../../../game/services/game_service.dart';
import '../../../game/domain/entities/badge.dart' as badge_entity;
import '../../../../core/widgets/badge_icon.dart';
import '../../../../core/widgets/badge_celebration.dart';
import '../../../../core/widgets/toasts.dart';
import 'badge_detail_page.dart';

class BadgesPageV2 extends StatefulWidget {
  const BadgesPageV2({super.key});

  @override
  State<BadgesPageV2> createState() => _BadgesPageV2State();
}

class _BadgesPageV2State extends State<BadgesPageV2> with TickerProviderStateMixin {
  late final GameService _gameService;
  late Future<List<badge_entity.Badge>> _badgesFuture;
  late Future<badge_entity.BadgeCollectionStats?> _statsFuture;
  
  String? _selectedCategory;
  String? _selectedRarity;
  String _searchQuery = '';
  bool _showOnlyEarned = false;
  bool _showOnlyLocked = false;
  
  late AnimationController _headerAnimationController;
  late AnimationController _statsAnimationController;
  
  @override
  void initState() {
    super.initState();
    _gameService = getIt<GameService>();
    _refreshData();
    
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _statsAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _headerAnimationController.forward();
    _statsAnimationController.forward();
  }
  
  void _refreshData({bool forceRefresh = false}) {
    setState(() {
      _badgesFuture = _fetchBadges(forceRefresh: forceRefresh);
      _statsFuture = _fetchStats(forceRefresh: forceRefresh);
    });
  }
  
  Future<List<badge_entity.Badge>> _fetchBadges({bool forceRefresh = false}) async {
    try {
      final data = await _gameService.getBadges(forceRefresh: forceRefresh);
      return data.map((e) => badge_entity.Badge.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }
  
  Future<badge_entity.BadgeCollectionStats?> _fetchStats({bool forceRefresh = false}) async {
    try {
      final client = getIt<NetworkManager>();
      final resp = await client.get('/api/ApiGamification/badges/showcase');
      final data = resp.data['data'] as Map<String, dynamic>?;
      if (data != null) {
        return badge_entity.BadgeCollectionStats.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  @override
  void dispose() {
    _headerAnimationController.dispose();
    _statsAnimationController.dispose();
    super.dispose();
  }
  
  List<String> _getCategories(List<badge_entity.Badge> badges) {
    final categories = badges.map((b) => b.category).where((c) => c.isNotEmpty).toSet().toList();
    categories.sort();
    return categories;
  }
  
  List<String> _getRarities(List<badge_entity.Badge> badges) {
    final rarities = badges.map((b) => b.rarity).where((r) => r.isNotEmpty).toSet().toList();
    return ['All', ...rarities];
  }
  
  List<badge_entity.Badge> _filterBadges(List<badge_entity.Badge> badges) {
    var filtered = badges;
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((b) {
        final query = _searchQuery.toLowerCase();
        return b.name.toLowerCase().contains(query) ||
               b.description.toLowerCase().contains(query) ||
               b.category.toLowerCase().contains(query);
      }).toList();
    }
    
    // Category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((b) => b.category == _selectedCategory).toList();
    }
    
    // Rarity filter
    if (_selectedRarity != null && _selectedRarity != 'All') {
      filtered = filtered.where((b) => b.rarity == _selectedRarity).toList();
    }
    
    // Earned/Locked filter
    if (_showOnlyEarned) {
      filtered = filtered.where((b) => b.isEarned).toList();
    } else if (_showOnlyLocked) {
      filtered = filtered.where((b) => !b.isEarned).toList();
    }
    
    return filtered;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Rozetlerim', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(forceRefresh: true),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: FutureBuilder<List<badge_entity.Badge>>(
        future: _badgesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Rozetler yüklenemedi', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _refreshData(forceRefresh: true),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }
          
          final badges = snapshot.data!;
          final filteredBadges = _filterBadges(badges);
          
          return CustomScrollView(
            slivers: [
              // Collection Stats Header
              SliverToBoxAdapter(
                child: _buildCollectionStatsHeader(badges),
              ),
              
              // Filters Section
              SliverToBoxAdapter(
                child: _buildFiltersSection(badges),
              ),
              
              // Badges Grid
              if (filteredBadges.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Filtre kriterlerine uygun rozet bulunamadı',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 18,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final badge = filteredBadges[index];
                        return _BadgeTileV2(
                          badge: badge,
                          onTap: () => _showBadgeDetail(badge),
                        );
                      },
                      childCount: filteredBadges.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildCollectionStatsHeader(List<badge_entity.Badge> badges) {
    return FutureBuilder<badge_entity.BadgeCollectionStats?>(
      future: _statsFuture,
      builder: (context, statsSnapshot) {
        final stats = statsSnapshot.data;
        final earnedCount = badges.where((b) => b.isEarned).length;
        final totalCount = badges.length;
        final completionRate = totalCount > 0 ? (earnedCount / totalCount) : 0.0;
        
        return FadeTransition(
          opacity: _headerAnimationController,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade400,
                  Colors.orange.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: Icons.emoji_events_rounded,
                      label: 'Toplam',
                      value: '$totalCount',
                      color: Colors.white,
                    ),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                    _buildStatItem(
                      icon: Icons.check_circle_rounded,
                      label: 'Kazanılan',
                      value: '$earnedCount',
                      color: Colors.white,
                    ),
                    Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                    _buildStatItem(
                      icon: Icons.stars_rounded,
                      label: 'Tamamlanma',
                      value: '${(completionRate * 100).toStringAsFixed(0)}%',
                      color: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress Bar
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: completionRate),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFiltersSection(List<badge_entity.Badge> badges) {
    final categories = _getCategories(badges);
    final rarities = _getRarities(badges);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Rozet ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 12),
          
          // Quick Filters
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  label: 'Tümü',
                  isSelected: !_showOnlyEarned && !_showOnlyLocked,
                  onTap: () => setState(() {
                    _showOnlyEarned = false;
                    _showOnlyLocked = false;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  label: 'Kazanılan',
                  isSelected: _showOnlyEarned,
                  icon: Icons.check_circle,
                  onTap: () => setState(() {
                    _showOnlyEarned = true;
                    _showOnlyLocked = false;
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  label: 'Kilitli',
                  isSelected: _showOnlyLocked,
                  icon: Icons.lock,
                  onTap: () => setState(() {
                    _showOnlyEarned = false;
                    _showOnlyLocked = true;
                  }),
                ),
              ),
            ],
          ),
          
          if (categories.isNotEmpty || rarities.length > 1) ...[
            const SizedBox(height: 12),
            // Category Filter
            if (categories.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Tüm Kategoriler',
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 8),
                    ...categories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: cat,
                        isSelected: _selectedCategory == cat,
                        onTap: () => setState(() => _selectedCategory = cat),
                      ),
                    )),
                  ],
                ),
              ),
            
            if (rarities.length > 1) ...[
              const SizedBox(height: 8),
              // Rarity Filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: rarities.map((rarity) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildFilterChip(
                      label: rarity,
                      isSelected: _selectedRarity == rarity || (_selectedRarity == null && rarity == 'All'),
                      onTap: () => setState(() => _selectedRarity = rarity == 'All' ? null : rarity),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.amber.shade100,
      checkmarkColor: Colors.amber.shade800,
      labelStyle: TextStyle(
        color: isSelected ? Colors.amber.shade900 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
  
  void _showBadgeDetail(badge_entity.Badge badge) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BadgeDetailPage(badge: badge),
      ),
    );
  }
}

class _BadgeTileV2 extends StatefulWidget {
  final badge_entity.Badge badge;
  final VoidCallback onTap;

  const _BadgeTileV2({
    required this.badge,
    required this.onTap,
  });

  @override
  State<_BadgeTileV2> createState() => _BadgeTileV2State();
}

class _BadgeTileV2State extends State<_BadgeTileV2> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  bool _pressed = false;
  
  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    if (widget.badge.isEarned) {
      _glowController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }
  
  Color _getRarityColor() {
    if (widget.badge.rarityColorHex != null) {
      final color = _parseHexColor(widget.badge.rarityColorHex!);
      if (color != null) return color;
    }
    
    switch (widget.badge.rarity.toLowerCase()) {
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
  
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color rarityColor = _getRarityColor();
    final bool hasProgress = widget.badge.progress != null && !widget.badge.isEarned;
    
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowOpacity = widget.badge.isEarned 
            ? 0.3 + (_glowController.value * 0.2)
            : 0.1;
        
        return InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedScale(
            scale: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.badge.isEarned 
                      ? rarityColor.withOpacity(glowOpacity)
                      : Colors.grey.shade300,
                  width: widget.badge.isEarned ? 2 : 1,
                ),
                boxShadow: [
                  if (widget.badge.isEarned)
                    BoxShadow(
                      color: rarityColor.withOpacity(glowOpacity * 0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Badge Icon with Glow
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: widget.badge.isEarned
                            ? RadialGradient(
                                colors: [
                                  rarityColor.withOpacity(glowOpacity),
                                  rarityColor.withOpacity(0.1),
                                ],
                              )
                            : null,
                        boxShadow: widget.badge.isEarned
                            ? [
                                BoxShadow(
                                  color: rarityColor.withOpacity(glowOpacity * 0.6),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: BadgeIcon(
                        name: widget.badge.name,
                        category: widget.badge.category,
                        rarity: widget.badge.rarity,
                        rarityColorHex: widget.badge.rarityColorHex,
                        imageUrl: widget.badge.imageUrl,
                        earned: widget.badge.isEarned,
                        size: 64,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Badge Name
                    Text(
                      widget.badge.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: widget.badge.isEarned 
                            ? scheme.onSurface 
                            : Colors.grey.shade700,
                        height: 1.2,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Progress Bar or Status
                    if (hasProgress && widget.badge.progress != null)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: widget.badge.progress!.percentage,
                              minHeight: 4,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.badge.progress!.displayText,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.badge.isEarned 
                              ? rarityColor.withOpacity(0.15)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.badge.isEarned 
                                  ? Icons.verified_rounded 
                                  : Icons.lock_outline_rounded,
                              size: 12,
                              color: widget.badge.isEarned 
                                  ? rarityColor 
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.badge.isEarned ? 'Kazanıldı' : 'Kilitli',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: widget.badge.isEarned 
                                    ? rarityColor 
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

