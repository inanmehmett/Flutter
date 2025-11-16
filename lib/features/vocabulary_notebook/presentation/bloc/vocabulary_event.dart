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

/// CEFR seviye filtresi (A1, A2, B1, B2, C1, C2)
class FilterByLevel extends VocabularyEvent {
  final String? level;

  const FilterByLevel({this.level});

  @override
  List<Object?> get props => [level];
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

class LoadMoreVocabulary extends VocabularyEvent {}

// Yeni öğrenme sistemi event'leri
// (Gelişmiş öğrenme/stats event'leri şimdilik kaldırıldı; çekirdek fonksiyonlara odaklanıyoruz)

class StartReviewSession extends VocabularyEvent {
  final String? modeFilter; // 'due', 'all', 'difficult'

  const StartReviewSession({this.modeFilter});

  @override
  List<Object?> get props => [modeFilter];
}

class CompleteReviewSession extends VocabularyEvent {
  final ReviewSession session;

  const CompleteReviewSession({required this.session});

  @override
  List<Object?> get props => [session];
}
