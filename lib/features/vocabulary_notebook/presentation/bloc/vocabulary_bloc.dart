import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import 'vocabulary_event.dart';
import 'vocabulary_state.dart';

class VocabularyBloc extends Bloc<VocabularyEvent, VocabularyState> {
  final VocabularyRepository repository;

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
      final stats = await repository.getUserStats();
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
      final stats = await repository.getUserStats();
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
      add(RefreshVocabulary());
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onUpdateWord(
    UpdateWord event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(WordUpdating(word: event.word));
    try {
      final updatedWord = await repository.updateWord(event.word);
      emit(WordUpdated(word: updatedWord));
      add(RefreshVocabulary());
    } catch (e) {
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
