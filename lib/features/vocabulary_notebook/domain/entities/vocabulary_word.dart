import 'package:equatable/equatable.dart';
import 'learning_activity.dart';

enum VocabularyStatus {
  new_,
  learning,
  known,
  mastered,
}

extension VocabularyStatusExtension on VocabularyStatus {
  String get displayName {
    switch (this) {
      case VocabularyStatus.new_:
        return 'Yeni';
      case VocabularyStatus.learning:
        return 'Öğreniyorum';
      case VocabularyStatus.known:
        return 'Biliyorum';
      case VocabularyStatus.mastered:
        return 'Uzman';
    }
  }

  String get iconName {
    switch (this) {
      case VocabularyStatus.new_:
        return 'fiber_new';
      case VocabularyStatus.learning:
        return 'school';
      case VocabularyStatus.known:
        return 'check_circle';
      case VocabularyStatus.mastered:
        return 'star';
    }
  }
}

class VocabularyWord extends Equatable {
  final int id;
  final String word;
  final String meaning;
  final String? personalNote;
  final String? description; // Tanım/açıklama
  final String? exampleSentence;
  final List<String> synonyms; // Eş anlamlılar
  final List<String> antonyms; // Zıt anlamlılar
  final VocabularyStatus status;
  final int? readingTextId;
  final DateTime addedAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final int correctCount;
  final int consecutiveCorrectCount; // Ardışık doğru cevap sayısı
  final DateTime? nextReviewAt; // Bir sonraki review tarihi
  final double difficultyLevel; // 0.0-1.0 arası zorluk seviyesi
  final List<LearningActivity> recentActivities; // Son 10 aktivite

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.meaning,
    this.personalNote,
    this.description,
    this.exampleSentence,
    this.synonyms = const [],
    this.antonyms = const [],
    required this.status,
    this.readingTextId,
    required this.addedAt,
    this.lastReviewedAt,
    required this.reviewCount,
    required this.correctCount,
    this.consecutiveCorrectCount = 0,
    this.nextReviewAt,
    this.difficultyLevel = 0.5,
    this.recentActivities = const [],
  });

  double get accuracyRate {
    if (reviewCount == 0) return 0.0;
    return correctCount / reviewCount;
  }

  bool get needsReview {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  bool get isOverdue {
    if (nextReviewAt == null) return false;
    return DateTime.now().isAfter(nextReviewAt!.add(const Duration(days: 1)));
  }

  Duration get timeUntilNextReview {
    if (nextReviewAt == null) return Duration.zero;
    final now = DateTime.now();
    if (now.isAfter(nextReviewAt!)) return Duration.zero;
    return nextReviewAt!.difference(now);
  }

  // Spaced repetition interval calculation
  Duration get nextReviewInterval {
    switch (status) {
      case VocabularyStatus.new_:
        return const Duration(hours: 1);
      case VocabularyStatus.learning:
        return Duration(days: consecutiveCorrectCount.clamp(1, 3));
      case VocabularyStatus.known:
        return Duration(days: (consecutiveCorrectCount * 2).clamp(3, 14));
      case VocabularyStatus.mastered:
        return Duration(days: (consecutiveCorrectCount * 7).clamp(14, 90));
    }
  }

  VocabularyWord copyWith({
    int? id,
    String? word,
    String? meaning,
    String? personalNote,
    String? description,
    String? exampleSentence,
    List<String>? synonyms,
    List<String>? antonyms,
    VocabularyStatus? status,
    int? readingTextId,
    DateTime? addedAt,
    DateTime? lastReviewedAt,
    int? reviewCount,
    int? correctCount,
    int? consecutiveCorrectCount,
    DateTime? nextReviewAt,
    double? difficultyLevel,
    List<LearningActivity>? recentActivities,
  }) {
    return VocabularyWord(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      personalNote: personalNote ?? this.personalNote,
      description: description ?? this.description,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
      status: status ?? this.status,
      readingTextId: readingTextId ?? this.readingTextId,
      addedAt: addedAt ?? this.addedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
      consecutiveCorrectCount: consecutiveCorrectCount ?? this.consecutiveCorrectCount,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      difficultyLevel: difficultyLevel ?? this.difficultyLevel,
      recentActivities: recentActivities ?? this.recentActivities,
    );
  }

  @override
  List<Object?> get props => [
        id,
        word,
        meaning,
        personalNote,
        description,
        exampleSentence,
        synonyms,
        antonyms,
        status,
        readingTextId,
        addedAt,
        lastReviewedAt,
        reviewCount,
        correctCount,
        consecutiveCorrectCount,
        nextReviewAt,
        difficultyLevel,
        recentActivities,
      ];
}
