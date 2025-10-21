import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../domain/entities/vocabulary_stats.dart';
import 'vocabulary_event.dart';
import 'vocabulary_state.dart';

class VocabularyBloc extends Bloc<VocabularyEvent, VocabularyState> {
  final VocabularyRepository repository;
  // Cache last known stats to avoid redundant fetches on local-only changes
  VocabularyStats? _lastStats;

  VocabularyBloc({required this.repository}) : super(VocabularyInitial()) {
    on<LoadVocabulary>(_onLoadVocabulary);
    on<RefreshVocabulary>(_onRefreshVocabulary);
    on<SearchWords>(_onSearchWords);
    on<FilterByStatus>(_onFilterByStatus);
    on<AddWord>(_onAddWord);
    on<UpdateWord>(_onUpdateWord);
    on<DeleteWord>(_onDeleteWord);
    on<MarkWordReviewed>(_onMarkWordReviewed);
    on<AddWordsFromText>(_onAddWordsFromText);
    on<SyncWords>(_onSyncWords);
    on<LoadWordsForReview>(_onLoadWordsForReview);
  }

  Future<void> _onLoadVocabulary(
    LoadVocabulary event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(VocabularyLoading());
    try {
      final words = await repository.getUserWords();
      final stats = await repository.getUserStats();
      _lastStats = stats;
      emit(VocabularyLoaded(words: words, stats: stats));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onRefreshVocabulary(
    RefreshVocabulary event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final words = await repository.getUserWords();
      final stats = await repository.getUserStats();
      _lastStats = stats;
      emit(VocabularyLoaded(words: words, stats: stats));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onSearchWords(
    SearchWords event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final words = await repository.searchWords(event.query);
      final stats = _lastStats ?? await repository.getUserStats();
      _lastStats = stats;
      emit(VocabularyLoaded(
        words: words,
        stats: stats,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onFilterByStatus(
    FilterByStatus event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final words = await repository.getUserWords(status: event.status);
      final stats = _lastStats ?? await repository.getUserStats();
      _lastStats = stats;
      emit(VocabularyLoaded(
        words: words,
        stats: stats,
        selectedStatus: event.status,
      ));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onAddWord(
    AddWord event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(WordAdding(word: event.word));
    try {
      final addedWord = await repository.addWord(event.word);
      emit(WordAdded(word: addedWord));
      // After mutation, force refresh of stats
      _lastStats = null;
      add(RefreshVocabulary());
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onUpdateWord(
    UpdateWord event,
    Emitter<VocabularyState> emit,
  ) async {
    // Optimistic update: if we are in loaded state, update local list immediately
    final currentState = state;
    if (currentState is VocabularyLoaded) {
      final updated = event.word;
      final newList = currentState.words.map((w) => w.id == updated.id ? updated : w).toList();
      emit(currentState.copyWith(words: newList));
    } else {
      emit(WordUpdating(word: event.word));
    }
    try {
      final updatedWord = await repository.updateWord(event.word);
      emit(WordUpdated(word: updatedWord));
      _lastStats = null;
      add(RefreshVocabulary());
    } catch (e) {
      // Rollback not implemented (local only), push error to UI
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onDeleteWord(
    DeleteWord event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(WordDeleting(wordId: event.wordId));
    try {
      await repository.deleteWord(event.wordId);
      emit(WordDeleted(wordId: event.wordId));
      _lastStats = null;
      add(RefreshVocabulary());
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onMarkWordReviewed(
    MarkWordReviewed event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      await repository.markWordReviewed(event.wordId, event.isCorrect);
      _lastStats = null;
      add(RefreshVocabulary());
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onAddWordsFromText(
    AddWordsFromText event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      await repository.addWordsFromText(event.text, event.readingTextId);
      _lastStats = null;
      add(RefreshVocabulary());
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onSyncWords(
    SyncWords event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      await repository.syncWords();
      _lastStats = null;
      add(RefreshVocabulary());
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onLoadWordsForReview(
    LoadWordsForReview event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final words = await repository.getWordsForReview(event.limit);
      final stats = await repository.getUserStats();
      emit(VocabularyLoaded(words: words, stats: stats));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }
}
