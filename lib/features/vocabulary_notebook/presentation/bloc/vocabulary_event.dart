import 'package:equatable/equatable.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/learning_activity.dart';
import '../../domain/services/review_session.dart';

abstract class VocabularyEvent extends Equatable {
  const VocabularyEvent();

  @override
  List<Object?> get props => [];
}

class LoadVocabulary extends VocabularyEvent {}

class RefreshVocabulary extends VocabularyEvent {}

class SearchWords extends VocabularyEvent {
  final String query;

  const SearchWords({required this.query});

  @override
  List<Object?> get props => [query];
}

class FilterByStatus extends VocabularyEvent {
  final VocabularyStatus? status;

  const FilterByStatus({this.status});

  @override
  List<Object?> get props => [status];
}

class AddWord extends VocabularyEvent {
  final VocabularyWord word;

  const AddWord({required this.word});

  @override
  List<Object?> get props => [word];
}

class UpdateWord extends VocabularyEvent {
  final VocabularyWord word;

  const UpdateWord({required this.word});

  @override
  List<Object?> get props => [word];
}

class DeleteWord extends VocabularyEvent {
  final int wordId;

  const DeleteWord({required this.wordId});

  @override
  List<Object?> get props => [wordId];
}

class MarkWordReviewed extends VocabularyEvent {
  final int wordId;
  final bool isCorrect;

  const MarkWordReviewed({
    required this.wordId,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [wordId, isCorrect];
}

class AddWordsFromText extends VocabularyEvent {
  final String text;
  final int readingTextId;

  const AddWordsFromText({
    required this.text,
    required this.readingTextId,
  });

  @override
  List<Object?> get props => [text, readingTextId];
}

class SyncWords extends VocabularyEvent {}

class LoadWordsForReview extends VocabularyEvent {
  final int limit;

  const LoadWordsForReview({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class LoadMoreVocabulary extends VocabularyEvent {}

// Yeni öğrenme sistemi event'leri
class RecordLearningActivity extends VocabularyEvent {
  final LearningActivity activity;

  const RecordLearningActivity({required this.activity});

  @override
  List<Object?> get props => [activity];
}

class LoadWordsNeedingReview extends VocabularyEvent {
  final int limit;

  const LoadWordsNeedingReview({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}

class LoadOverdueWords extends VocabularyEvent {
  final int limit;

  const LoadOverdueWords({this.limit = 10});

  @override
  List<Object?> get props => [limit];
}

class LoadLearningAnalytics extends VocabularyEvent {}

// Aralıklı tekrar sistemi event'leri
class LoadDailyReviewWords extends VocabularyEvent {}

class LoadReviewStats extends VocabularyEvent {}

class StartReviewSession extends VocabularyEvent {}

class CompleteReviewSession extends VocabularyEvent {
  final ReviewSession session;

  const CompleteReviewSession({required this.session});

  @override
  List<Object?> get props => [session];
}

class LoadNextReviewTime extends VocabularyEvent {}

class LoadReviewStreak extends VocabularyEvent {}
