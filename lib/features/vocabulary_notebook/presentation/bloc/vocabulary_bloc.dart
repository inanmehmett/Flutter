import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../domain/entities/vocabulary_stats.dart';
import 'vocabulary_event.dart';
import 'vocabulary_state.dart';

class VocabularyBloc extends Bloc<VocabularyEvent, VocabularyState> {
  final VocabularyRepository repository;
  // Cache last known stats to avoid redundant fetches on local-only changes
  VocabularyStats? _lastStats;
  bool _isLoadingMore = false;

  VocabularyBloc({required this.repository}) : super(VocabularyInitial()) {
    on<LoadVocabulary>(_onLoadVocabulary);
    on<RefreshVocabulary>(_onRefreshVocabulary);
    on<SearchWords>(_onSearchWords);
    on<FilterByStatus>(_onFilterByStatus);
    on<FilterByLevel>(_onFilterByLevel);
    on<LoadMoreVocabulary>(_onLoadMore);
    on<AddWord>(_onAddWord);
    on<UpdateWord>(_onUpdateWord);
    on<DeleteWord>(_onDeleteWord);
    on<MarkWordReviewed>(_onMarkWordReviewed);
    on<StartReviewSession>(_onStartReviewSession);
    on<CompleteReviewSession>(_onCompleteReviewSession);
  }

  Future<void> _onLoadVocabulary(
    LoadVocabulary event,
    Emitter<VocabularyState> emit,
  ) async {
    emit(VocabularyLoading());
    try {
      final words = await repository.getUserWords(limit: 50, offset: 0);
      final stats = await repository.getUserStats();
      _lastStats = stats;
      final hasMore = words.length == 50;
      emit(VocabularyLoaded(words: words, stats: stats, hasMore: hasMore));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onRefreshVocabulary(
    RefreshVocabulary event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final words = await repository.getUserWords(limit: 50, offset: 0);
      final stats = await repository.getUserStats();
      _lastStats = stats;
      emit(VocabularyLoaded(words: words, stats: stats, hasMore: words.length == 50));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onSearchWords(
    SearchWords event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      // Get current filter status from state
      final currentState = state;
      final currentFilter = currentState is VocabularyLoaded ? currentState.selectedStatus : null;
      
      // Use getUserWords with search query and current filter
      final words = await repository.getUserWords(
        searchQuery: event.query,
        status: currentFilter,
        limit: 50,
        offset: 0,
      );
      final stats = _lastStats ?? await repository.getUserStats();
      _lastStats = stats;
      emit(VocabularyLoaded(
        words: words,
        stats: stats, 
        searchQuery: event.query,
        selectedStatus: currentFilter,
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
      // Status filtresi backend üzerinden uygulanıyor
      final words = await repository.getUserWords(status: event.status, limit: 50, offset: 0);
      final stats = _lastStats ?? await repository.getUserStats();
      _lastStats = stats;
      emit(VocabularyLoaded(
        words: words,
        stats: stats,
        selectedStatus: event.status,
        selectedLevel: null, // status değişince seviye filtresini sıfırla
        hasMore: words.length == 50,
      ));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onFilterByLevel(
    FilterByLevel event,
    Emitter<VocabularyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! VocabularyLoaded) return;

    final level = event.level?.toUpperCase().trim();

    // Seviye filtresi tamamen client-side uygulanıyor (backend'e extra parametre yok)
    final filtered = level == null || level.isEmpty
        ? currentState.words
        : currentState.words.where((w) => w.wordLevel?.toUpperCase().trim() == level).toList();

    emit(currentState.copyWith(
      words: filtered,
      selectedLevel: level,
      hasMore: false, // seviye filtreliyken sayfalama kapalı
    ));
  }

  Future<void> _onAddWord(
    AddWord event,
    Emitter<VocabularyState> emit,
  ) async {
    // Optimistic update: add word to local list immediately
    final currentState = state;
    VocabularyLoaded? previousState;
    if (currentState is VocabularyLoaded) {
      // Pre-check duplicate locally
      final exists = currentState.words.any((w) => w.word.toLowerCase().trim() == event.word.word.toLowerCase().trim());
      if (exists) {
        emit(WordExists(word: event.word));
        return;
      }
      // Save previous state for rollback
      previousState = currentState;
      // Optimistically add word
      final optimisticWord = event.word.copyWith(id: -1); // Temporary ID
      emit(currentState.copyWith(words: [...currentState.words, optimisticWord]));
    } else {
      emit(WordAdding(word: event.word));
    }
    
    try {
      final addedWord = await repository.addWord(event.word);
      // Update stats only (no full refresh needed)
      _lastStats = null;
      final stats = await repository.getUserStats();
      
      // Update state with real word from backend
      if (previousState != null) {
        final updatedList = previousState.words
            .where((w) => w.id != -1) // Remove optimistic word
            .toList();
        updatedList.add(addedWord);
        emit(previousState.copyWith(words: updatedList, stats: stats));
      } else {
        emit(WordAdded(word: addedWord));
      }
    } catch (e) {
      // Rollback on error
      if (previousState != null) {
        emit(previousState);
      }
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onUpdateWord(
    UpdateWord event,
    Emitter<VocabularyState> emit,
  ) async {
    // Optimistic update: if we are in loaded state, update local list immediately
    final currentState = state;
    VocabularyLoaded? previousState;
    if (currentState is VocabularyLoaded) {
      previousState = currentState;
      final updated = event.word;
      final newList = currentState.words.map((w) => w.id == updated.id ? updated : w).toList();
      emit(currentState.copyWith(words: newList));
    } else {
      emit(WordUpdating(word: event.word));
    }
    try {
      final updatedWord = await repository.updateWord(event.word);
      // Update state with backend response
      if (previousState != null) {
        final newList = previousState.words.map((w) => w.id == updatedWord.id ? updatedWord : w).toList();
        emit(previousState.copyWith(words: newList));
      } else {
        emit(WordUpdated(word: updatedWord));
      }
    } catch (e) {
      // Rollback on error
      if (previousState != null) {
        emit(previousState);
      }
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onDeleteWord(
    DeleteWord event,
    Emitter<VocabularyState> emit,
  ) async {
    // Optimistic update: eğer VocabularyLoaded ise kelimeyi hemen listeden çıkar
    final beforeDelete = state;
    if (beforeDelete is VocabularyLoaded) {
      final newList =
          beforeDelete.words.where((w) => w.id != event.wordId).toList();
      emit(beforeDelete.copyWith(words: newList));
    } else {
      emit(WordDeleting(wordId: event.wordId));
    }

    try {
      await repository.deleteWord(event.wordId);
      // Backend'den güncel istatistikleri çek
      _lastStats = null;
      final stats = await repository.getUserStats();

      // Mevcut state VocabularyLoaded ise, sadece stats'i güncelle
      final current = state;
      if (current is VocabularyLoaded) {
        emit(current.copyWith(stats: stats));
      } else {
        emit(WordDeleted(wordId: event.wordId));
      }
    } catch (e) {
      // Hata olursa, eski state'e rollback
      if (beforeDelete is VocabularyLoaded) {
        emit(beforeDelete);
      }
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onMarkWordReviewed(
    MarkWordReviewed event,
    Emitter<VocabularyState> emit,
  ) async {
    // Optimistic update: update word locally immediately
    final currentState = state;
    VocabularyLoaded? previousState;
    if (currentState is VocabularyLoaded) {
      previousState = currentState;
      // Find word and update optimistically
      final word = currentState.words.firstWhere((w) => w.id == event.wordId, orElse: () => throw StateError('Word not found'));
      // Simple optimistic update (will be replaced by backend response)
      final updatedList = currentState.words.map((w) => w.id == event.wordId ? word : w).toList();
      emit(currentState.copyWith(words: updatedList));
    }
    
    try {
      await repository.markWordReviewed(event.wordId, event.isCorrect);
      // Fetch updated word and stats
      final updatedWord = await repository.getWordById(event.wordId);
      _lastStats = null;
      final stats = await repository.getUserStats();
      
      if (previousState != null && updatedWord != null) {
        final updatedList = previousState.words.map((w) => w.id == event.wordId ? updatedWord : w).toList();
        emit(previousState.copyWith(words: updatedList, stats: stats));
      } else if (previousState != null) {
        emit(previousState.copyWith(stats: stats));
      }
    } catch (e) {
      // Rollback on error
      if (previousState != null) {
        emit(previousState);
      }
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreVocabulary event,
    Emitter<VocabularyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! VocabularyLoaded || !currentState.hasMore || _isLoadingMore) return;
    try {
      _isLoadingMore = true;
      final offset = currentState.words.length;
      final more = await repository.getUserWords(
        status: currentState.selectedStatus,
        limit: 50,
        offset: offset,
      );
      final merged = [...currentState.words, ...more];
      emit(currentState.copyWith(words: merged, hasMore: more.length == 50));
    } catch (_) {} finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _onStartReviewSession(
    StartReviewSession event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final session = await repository.startReviewSession(modeFilter: event.modeFilter);
      emit(ReviewSessionLoaded(session: session));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onCompleteReviewSession(
    CompleteReviewSession event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final updated = await repository.completeReviewSession(event.session);
      final currentState = state;
      if (currentState is VocabularyLoaded && updated.isNotEmpty) {
        // Merge updated words into current state without extra GETs
        final updatedIds = updated.map((w) => w.id).toSet();
        final merged = currentState.words.map((w) {
          final idx = updated.indexWhere((u) => u.id == w.id);
          return idx >= 0 ? updated[idx] : w;
        }).toList();
        emit(currentState.copyWith(words: merged));
      }
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

}
