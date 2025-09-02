class DailyTaskModel {
  final int id;
  final String name;
  final String description;
  final int requiredCount;
  final int completedCount;
  final int xpReward;
  final bool isCompleted;

  const DailyTaskModel({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredCount,
    required this.completedCount,
    required this.xpReward,
    required this.isCompleted,
  });

  factory DailyTaskModel.fromJson(Map<String, dynamic> json) {
    return DailyTaskModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      requiredCount: ((json['requiredCount'] ?? 0) as num).toInt(),
      completedCount: ((json['completedCount'] ?? 0) as num).toInt(),
      xpReward: ((json['xpReward'] ?? 0) as num).toInt(),
      isCompleted: (json['isCompleted'] as bool?) ?? false,
    );
  }
}


