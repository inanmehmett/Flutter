import 'package:equatable/equatable.dart';

/// Badge domain entity with progress tracking
class Badge extends Equatable {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final String category;
  final int requiredXP;
  final bool isEarned;
  final DateTime? earnedAt;
  final String rarity; // Common, Bronze, Silver, Gold, Diamond, Legendary, Epic, Rare
  final String? rarityColorHex;
  final String? difficulty; // Easy, Medium, Hard, Secret
  final bool isHidden;
  final BadgeProgress? progress;
  final String? motivationMessage;
  final String? unlockMessage;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.category,
    required this.requiredXP,
    required this.isEarned,
    this.earnedAt,
    this.rarity = 'Common',
    this.rarityColorHex,
    this.difficulty,
    this.isHidden = false,
    this.progress,
    this.motivationMessage,
    this.unlockMessage,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    final progressJson = json['progress'] as Map<String, dynamic>?;
    return Badge(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '').toString(),
      imageUrl: json['imageUrl'] ?? json['ImageUrl'],
      category: (json['category'] ?? json['Category'] ?? '').toString(),
      requiredXP: (json['requiredXP'] ?? json['RequiredXP'] as num?)?.toInt() ?? 0,
      isEarned: (json['isEarned'] ?? json['IsEarned'] as bool?) ?? false,
      earnedAt: json['earnedAt'] != null || json['EarnedAt'] != null
          ? DateTime.tryParse((json['earnedAt'] ?? json['EarnedAt']).toString())
          : null,
      rarity: (json['rarity'] ?? json['Rarity'] ?? 'Common').toString(),
      rarityColorHex: json['rarityColor'] ?? json['RarityColor'],
      difficulty: json['difficulty'] ?? json['Difficulty'],
      isHidden: (json['isHidden'] ?? json['IsHidden'] as bool?) ?? false,
      progress: progressJson != null
          ? BadgeProgress.fromJson(progressJson)
          : null,
      motivationMessage: json['motivationMessage'] ?? json['MotivationMessage'],
      unlockMessage: json['unlockMessage'] ?? json['UnlockMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      'requiredXP': requiredXP,
      'isEarned': isEarned,
      'earnedAt': earnedAt?.toIso8601String(),
      'rarity': rarity,
      'rarityColor': rarityColorHex,
      'difficulty': difficulty,
      'isHidden': isHidden,
      'progress': progress?.toJson(),
      'motivationMessage': motivationMessage,
      'unlockMessage': unlockMessage,
    };
  }

  Badge copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    String? category,
    int? requiredXP,
    bool? isEarned,
    DateTime? earnedAt,
    String? rarity,
    String? rarityColorHex,
    String? difficulty,
    bool? isHidden,
    BadgeProgress? progress,
    String? motivationMessage,
    String? unlockMessage,
  }) {
    return Badge(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      requiredXP: requiredXP ?? this.requiredXP,
      isEarned: isEarned ?? this.isEarned,
      earnedAt: earnedAt ?? this.earnedAt,
      rarity: rarity ?? this.rarity,
      rarityColorHex: rarityColorHex ?? this.rarityColorHex,
      difficulty: difficulty ?? this.difficulty,
      isHidden: isHidden ?? this.isHidden,
      progress: progress ?? this.progress,
      motivationMessage: motivationMessage ?? this.motivationMessage,
      unlockMessage: unlockMessage ?? this.unlockMessage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        category,
        requiredXP,
        isEarned,
        earnedAt,
        rarity,
        rarityColorHex,
        difficulty,
        isHidden,
        progress,
        motivationMessage,
        unlockMessage,
      ];
}

/// Badge progress tracking
class BadgeProgress extends Equatable {
  final int current;
  final int required;
  final double percentage;
  final String displayText;

  const BadgeProgress({
    required this.current,
    required this.required,
    required this.percentage,
    required this.displayText,
  });

  factory BadgeProgress.fromJson(Map<String, dynamic> json) {
    final current = (json['current'] ?? json['Current'] as num?)?.toInt() ?? 0;
    final required = (json['required'] ?? json['Required'] as num?)?.toInt() ?? 1;
    final percentage = (json['percentage'] ?? json['Percentage'] as num?)?.toDouble() ?? 0.0;
    return BadgeProgress(
      current: current,
      required: required,
      percentage: percentage.clamp(0.0, 1.0),
      displayText: json['displayText'] ?? json['DisplayText'] ?? '$current/$required',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current': current,
      'required': required,
      'percentage': percentage,
      'displayText': displayText,
    };
  }

  @override
  List<Object?> get props => [current, required, percentage, displayText];
}

/// Badge collection statistics
class BadgeCollectionStats extends Equatable {
  final int totalBadges;
  final int earnedBadges;
  final int rareBadges;
  final double completionRate;

  const BadgeCollectionStats({
    required this.totalBadges,
    required this.earnedBadges,
    required this.rareBadges,
    required this.completionRate,
  });

  factory BadgeCollectionStats.fromJson(Map<String, dynamic> json) {
    final total = (json['totalBadges'] ?? json['TotalBadges'] as num?)?.toInt() ?? 0;
    final earned = (json['earnedBadges'] ?? json['EarnedBadges'] as num?)?.toInt() ?? 0;
    final rare = (json['rareBadges'] ?? json['RareBadges'] as num?)?.toInt() ?? 0;
    final rate = total > 0 ? (earned / total) : 0.0;
    
    return BadgeCollectionStats(
      totalBadges: total,
      earnedBadges: earned,
      rareBadges: rare,
      completionRate: rate,
    );
  }

  @override
  List<Object?> get props => [totalBadges, earnedBadges, rareBadges, completionRate];
}

