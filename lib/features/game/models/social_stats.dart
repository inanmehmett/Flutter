import 'challenge.dart';

class SocialStats {
  final List<String> friends;
  final Map<String, Challenge> challenges;
  final int challengesWon;
  final int challengesCompleted;

  const SocialStats({
    this.friends = const [],
    this.challenges = const {},
    this.challengesWon = 0,
    this.challengesCompleted = 0,
  });

  factory SocialStats.fromJson(Map<String, dynamic> json) {
    return SocialStats(
      friends: List<String>.from(json['friends'] as List),
      challenges: (json['challenges'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(key, Challenge.fromJson(value as Map<String, dynamic>)),
      ),
      challengesWon: json['challengesWon'] as int,
      challengesCompleted: json['challengesCompleted'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friends': friends,
      'challenges':
          challenges.map((key, value) => MapEntry(key, value.toJson())),
      'challengesWon': challengesWon,
      'challengesCompleted': challengesCompleted,
    };
  }

  SocialStats copyWith({
    List<String>? friends,
    Map<String, Challenge>? challenges,
    int? challengesWon,
    int? challengesCompleted,
  }) {
    return SocialStats(
      friends: friends ?? this.friends,
      challenges: challenges ?? this.challenges,
      challengesWon: challengesWon ?? this.challengesWon,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
    );
  }
}
