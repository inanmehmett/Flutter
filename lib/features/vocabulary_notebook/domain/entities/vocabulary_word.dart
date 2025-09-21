import 'package:equatable/equatable.dart';

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

  String get emoji {
    switch (this) {
      case VocabularyStatus.new_:
        return '🆕';
      case VocabularyStatus.learning:
        return '📚';
      case VocabularyStatus.known:
        return '✅';
      case VocabularyStatus.mastered:
        return '🏆';
    }
  }
}

class VocabularyWord extends Equatable {
  final int id;
  final String word;
  final String meaning;
  final String? personalNote;
  final String? exampleSentence;
  final VocabularyStatus status;
  final int? readingTextId;
  final DateTime addedAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final int correctCount;

  const VocabularyWord({
    required this.id,
    required this.word,
    required this.meaning,
    this.personalNote,
    this.exampleSentence,
    required this.status,
    this.readingTextId,
    required this.addedAt,
    this.lastReviewedAt,
    required this.reviewCount,
    required this.correctCount,
  });

  double get accuracyRate {
    if (reviewCount == 0) return 0.0;
    return correctCount / reviewCount;
  }

  bool get needsReview {
    if (lastReviewedAt == null) return true;
    final daysSinceReview = DateTime.now().difference(lastReviewedAt!).inDays;
    switch (status) {
      case VocabularyStatus.new_:
        return true;
      case VocabularyStatus.learning:
        return daysSinceReview >= 1;
      case VocabularyStatus.known:
        return daysSinceReview >= 3;
      case VocabularyStatus.mastered:
        return daysSinceReview >= 7;
    }
  }

  VocabularyWord copyWith({
    int? id,
    String? word,
    String? meaning,
    String? personalNote,
    String? exampleSentence,
    VocabularyStatus? status,
    int? readingTextId,
    DateTime? addedAt,
    DateTime? lastReviewedAt,
    int? reviewCount,
    int? correctCount,
  }) {
    return VocabularyWord(
      id: id ?? this.id,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      personalNote: personalNote ?? this.personalNote,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      status: status ?? this.status,
      readingTextId: readingTextId ?? this.readingTextId,
      addedAt: addedAt ?? this.addedAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      correctCount: correctCount ?? this.correctCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        word,
        meaning,
        personalNote,
        exampleSentence,
        status,
        readingTextId,
        addedAt,
        lastReviewedAt,
        reviewCount,
        correctCount,
      ];
}
