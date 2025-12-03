import 'dart:async';
import 'package:flutter/material.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/xp_state_service.dart';
import '../../../../core/network/network_manager.dart';
import '../../../../core/utils/xp_utils.dart';
import 'level_chip.dart';
import 'xp_progress_ring.dart';

/// Home page header showing user profile, level, and XP progress.
/// 
/// Features:
/// - Profile picture with level badge
/// - Personalized greeting
/// - XP progress ring
/// - Streak indicator
/// - Responsive layout
/// 
/// Example:
/// ```dart
/// HomeHeader(
///   profile: userProfile,
///   greeting: 'Günaydın, Mehmet!',
///   streakDays: 7,
/// )
/// ```
class HomeHeader extends StatefulWidget {
  final UserProfile profile;
  final String greeting;
  final int? streakDays;
  final VoidCallback? onTap;

  const HomeHeader({
    super.key,
    required this.profile,
    required this.greeting,
    this.streakDays,
    this.onTap,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  Map<String, dynamic>? _levelData;
  bool _isLoadingLevel = false;
  int? _cachedTotalXP;
  
  late XPStateService _xpStateService;
  StreamSubscription<int>? _totalXPSubscription;

  @override
  void initState() {
    super.initState();
    _xpStateService = getIt<XPStateService>();
    
    // Load cached XP immediately for fast UI
    _loadCachedXP();
    
    // Listen to XP updates from SignalR
    _totalXPSubscription = _xpStateService.totalXPStream.listen((totalXP) {
      if (mounted) {
        setState(() {
          _cachedTotalXP = totalXP;
        });
      }
    });
    
    // Load level data in background (for progress calculation)
    _loadLevelData();
  }
  
  Future<void> _loadCachedXP() async {
    final cachedXP = await _xpStateService.getTotalXP();
    if (mounted && cachedXP > 0) {
      setState(() {
        _cachedTotalXP = cachedXP;
      });
    }
  }

  Future<void> _loadLevelData() async {
    if (_isLoadingLevel) return;
    setState(() => _isLoadingLevel = true);
    
    try {
      final client = getIt<NetworkManager>();
      final levelResp = await client.get('/api/ApiGamification/level');
      final lroot = levelResp.data is Map<String, dynamic> ? levelResp.data as Map<String, dynamic> : {};
      final ldat = lroot['data'] is Map<String, dynamic> ? lroot['data'] as Map<String, dynamic> : {};
      
      // Update local cache if we got total XP from API
      if (ldat.isNotEmpty) {
        final apiTotalXP = ldat['currentXP'] ?? ldat['CurrentXP'] ?? ldat['totalXP'] ?? ldat['TotalXP'];
        if (apiTotalXP != null) {
          final totalXP = (apiTotalXP as num).toInt();
          await _xpStateService.updateTotalXP(totalXP);
        }
      }
      
      if (mounted) {
        setState(() {
          _levelData = ldat.isNotEmpty ? Map<String, dynamic>.from(ldat) : null;
          _isLoadingLevel = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLevel = false);
      }
    }
  }
  
  @override
  void dispose() {
    _totalXPSubscription?.cancel();
    super.dispose();
  }

  num _asNum(dynamic value, [num fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value;
    if (value is String) {
      final p = num.tryParse(value);
      if (p != null) return p;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 400;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile picture + level badge
            _buildProfileSection(isCompact),
            SizedBox(width: isCompact ? 12 : 16),
            // Greeting + stats
            Expanded(
              child: _buildInfoSection(isCompact),
            ),
            // XP ring
            _buildXPSection(isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isCompact) {
    final size = isCompact ? 66.0 : 74.0;
    final level = widget.profile.levelDisplay ?? widget.profile.levelName ?? 'A1';
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Profile picture (Hero removed due to IndexedStack - both pages exist simultaneously)
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.2), AppColors.primaryLight.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: ClipOval(
            child: _buildProfileImage(),
          ),
        ),
        // Level badge
        Positioned(
          bottom: -4,
          right: -4,
          child: LevelChip(
            level: level,
            height: isCompact ? 24 : 28,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    final imageUrl = _resolveImageUrl(widget.profile.profileImageUrl);
    
    if (imageUrl.isEmpty) {
      return Icon(
        Icons.person,
        size: 32,
        color: AppColors.primary,
      );
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.person,
          size: 32,
          color: AppColors.primary,
        );
      },
    );
  }

  Widget _buildInfoSection(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Greeting
        Text(
          widget.greeting,
          style: TextStyle(
            fontSize: isCompact ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Stats row
        Row(
          children: [
            if (widget.streakDays != null && widget.streakDays! > 0) ...[
              Icon(
                Icons.local_fire_department,
                size: isCompact ? 14 : 16,
                color: const Color(0xFFFF6D00),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.streakDays}',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Icon(
              Icons.star_rounded,
              size: isCompact ? 14 : 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${_cachedTotalXP ?? widget.profile.experiencePoints ?? 0} XP',
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildXPSection(bool isCompact) {
    // Use cached XP if available (fast), otherwise fallback to profile XP
    final currentXP = _cachedTotalXP ?? widget.profile.experiencePoints ?? 0;
    
    // Use API level data if available (same calculation as profile page)
    if (_levelData != null) {
      final dynamic currentXPRaw = _levelData!['currentXP'] ?? _levelData!['CurrentXP'] ?? _levelData!['totalXP'] ?? _levelData!['TotalXP'];
      // Prefer cached XP over API XP for immediate updates
      final currentXPd = (_cachedTotalXP ?? _asNum(currentXPRaw, currentXP)).toDouble();
      final dynamic xpForNextRaw = _levelData!['xpForNextLevel'] ?? _levelData!['XPForNextLevel'];
      
      // Treat API value as remaining XP to next level; derive target XP
      // If API value is missing, calculate remaining XP using fallback
      final double xpRemaining;
      if (xpForNextRaw != null) {
        xpRemaining = _asNum(xpForNextRaw).toDouble();
      } else {
        // Calculate remaining XP using fallback (consistent with profile page)
        final absoluteTarget = XPUtils.calculateNextLevelXP(currentXPd.toInt()).toDouble();
        xpRemaining = (absoluteTarget - currentXPd).clamp(0, double.infinity);
      }
      
      // Compute target XP (same as profile page)
      final double xpTargetD = (currentXPd + xpRemaining).clamp(1, double.infinity);
      
      return XPProgressRing(
        currentXP: currentXPd.toInt(),
        totalXP: xpTargetD.toInt(),
        size: isCompact ? 52 : 60,
        strokeWidth: 4,
      );
    }
    
    // Fallback: use simple calculation if API data not available
    // Calculate absolute target XP (same as profile page fallback)
    final nextLevelXP = XPUtils.calculateNextLevelXP(currentXP);
    return XPProgressRing(
      currentXP: currentXP,
      totalXP: nextLevelXP,
      size: isCompact ? 52 : 60,
      strokeWidth: 4,
    );
  }

  String _resolveImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    
    // localhost içeren URL'leri AppConfig.apiBaseUrl ile değiştir
    if (imageUrl.contains('localhost') || imageUrl.contains('127.0.0.1')) {
      final uri = Uri.parse(imageUrl);
      final path = uri.path;
      return '${AppConfig.apiBaseUrl}$path${uri.query.isNotEmpty ? '?${uri.query}' : ''}';
    }
    
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    if (imageUrl.startsWith('/')) {
      return '${AppConfig.apiBaseUrl}$imageUrl';
    }
    return '${AppConfig.apiBaseUrl}/$imageUrl';
  }
}

