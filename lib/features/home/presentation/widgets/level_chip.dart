import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Compact level badge displaying user's CEFR level.
/// 
/// Features:
/// - CEFR level display (A1, A2, B1, B2, C1, C2)
/// - Gradient background based on level
/// - Responsive sizing
/// - Duolingo-style design
/// 
/// Example:
/// ```dart
/// LevelChip(level: 'B1')
/// ```
class LevelChip extends StatelessWidget {
  final String level;
  final double height;

  const LevelChip({
    super.key,
    required this.level,
    this.height = 28,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getLevelColors(level);
    
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: height * 0.6,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            level.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: height * 0.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns gradient colors based on CEFR level
  /// 
  /// Color scheme (Duolingo-inspired):
  /// - A1: Light Green (Beginner)
  /// - A2: Green (Elementary)
  /// - B1: Orange (Intermediate)
  /// - B2: Deep Orange (Upper Intermediate)
  /// - C1: Purple (Advanced)
  /// - C2: Deep Purple (Proficiency)
  List<Color> _getLevelColors(String level) {
    final levelUpper = level.toUpperCase();
    
    switch (levelUpper) {
      case 'A1':
        return [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]; // Light Green
      case 'A2':
        return [const Color(0xFF2E7D32), const Color(0xFF388E3C)]; // Green
      case 'B1':
        return [AppColors.primary, AppColors.primaryLight]; // Orange
      case 'B2':
        return [const Color(0xFFE64A19), const Color(0xFFFF5722)]; // Deep Orange
      case 'C1':
        return [const Color(0xFF7B1FA2), const Color(0xFF9C27B0)]; // Purple
      case 'C2':
        return [const Color(0xFF4A148C), const Color(0xFF6A1B9A)]; // Deep Purple
      default:
        return [Colors.grey.shade600, Colors.grey.shade400]; // Default
    }
  }
}

