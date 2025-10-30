import 'package:equatable/equatable.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/vocabulary_stats.dart';
import '../../domain/services/review_session.dart';

abstract class VocabularyState extends Equatable {
  const VocabularyState();

  @override
  List<Object?> get props => [];
}

class VocabularyInitial extends VocabularyState {}

class VocabularyLoading extends VocabularyState {}

class VocabularyLoaded extends VocabularyState {
  final List<VocabularyWord> words;
  final VocabularyStats stats;
  final String? searchQuery;
  final VocabularyStatus? selectedStatus;
  final bool hasMore;

  const VocabularyLoaded({
    required this.words,
    required this.stats,
    this.searchQuery,
    this.selectedStatus,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [words, stats, searchQuery, selectedStatus, hasMore];

  VocabularyLoaded copyWith({
    List<VocabularyWord>? words,
    VocabularyStats? stats,
    String? searchQuery,
    VocabularyStatus? selectedStatus,
    bool? hasMore,
  }) {
    return VocabularyLoaded(
      words: words ?? this.words,
      stats: stats ?? this.stats,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class VocabularyError extends VocabularyState {
  final String message;

  const VocabularyError({required this.message});

  @override
  List<Object?> get props => [message];
}

class ReviewSessionLoaded extends VocabularyState {
  final ReviewSession session;

  const ReviewSessionLoaded({required this.session});

  @override
  List<Object?> get props => [session];
}

class WordAdding extends VocabularyState {
  final VocabularyWord word;

  const WordAdding({required this.word});

  @override
  List<Object?> get props => [word];
}

class WordAdded extends VocabularyState {
  final VocabularyWord word;

  const WordAdded({required this.word});

  @override
  List<Object?> get props => [word];
}

class WordExists extends VocabularyState {
  final VocabularyWord word;

  const WordExists({required this.word});

  @override
  List<Object?> get props => [word];
}

class WordUpdating extends VocabularyState {
  final VocabularyWord word;

  const WordUpdating({required this.word});

  @override
  List<Object?> get props => [word];
}

class WordUpdated extends VocabularyState {
  final VocabularyWord word;

  const WordUpdated({required this.word});

  @override
  List<Object?> get props => [word];
}

class WordDeleting extends VocabularyState {
  final int wordId;

  const WordDeleting({required this.wordId});

  @override
  List<Object?> get props => [wordId];
}

class WordDeleted extends VocabularyState {
  final int wordId;

  const WordDeleted({required this.wordId});

  @override
  List<Object?> get props => [wordId];
}
