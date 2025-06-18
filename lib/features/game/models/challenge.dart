enum ChallengeType {
  wordsLearned,
  booksRead,
  readingTime,
  streak,
}

class Challenge {
  final String id;
  final ChallengeType type;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participants;
  final Map<String, int> progress;
  final int target;
  final bool isCompleted;
  final String? winnerId;

  const Challenge({
    required this.id,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.participants,
    required this.progress,
    required this.target,
    this.isCompleted = false,
    this.winnerId,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      type: ChallengeType.values[json['type'] as int],
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      participants: List<String>.from(json['participants'] as List),
      progress: Map<String, int>.from(json['progress'] as Map),
      target: json['target'] as int,
      isCompleted: json['isCompleted'] as bool,
      winnerId: json['winnerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'participants': participants,
      'progress': progress,
      'target': target,
      'isCompleted': isCompleted,
      'winnerId': winnerId,
    };
  }

  Challenge copyWith({
    String? id,
    ChallengeType? type,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? participants,
    Map<String, int>? progress,
    int? target,
    bool? isCompleted,
    String? winnerId,
  }) {
    return Challenge(
      id: id ?? this.id,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      participants: participants ?? this.participants,
      progress: progress ?? this.progress,
      target: target ?? this.target,
      isCompleted: isCompleted ?? this.isCompleted,
      winnerId: winnerId ?? this.winnerId,
    );
  }
}
