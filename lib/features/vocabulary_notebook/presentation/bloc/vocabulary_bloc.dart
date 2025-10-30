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
    on<LoadMoreVocabulary>(_onLoadMore);
    on<AddWord>(_onAddWord);
    on<UpdateWord>(_onUpdateWord);
    on<DeleteWord>(_onDeleteWord);
    on<MarkWordReviewed>(_onMarkWordReviewed);
    on<AddWordsFromText>(_onAddWordsFromText);
    on<SyncWords>(_onSyncWords);
    on<LoadWordsForReview>(_onLoadWordsForReview);
    on<RecordLearningActivity>(_onRecordLearningActivity);
    on<LoadWordsNeedingReview>(_onLoadWordsNeedingReview);
    on<LoadOverdueWords>(_onLoadOverdueWords);
    on<LoadLearningAnalytics>(_onLoadLearningAnalytics);
    on<LoadDailyReviewWords>(_onLoadDailyReviewWords);
    on<LoadReviewStats>(_onLoadReviewStats);
    on<StartReviewSession>(_onStartReviewSession);
    on<CompleteReviewSession>(_onCompleteReviewSession);
    on<LoadNextReviewTime>(_onLoadNextReviewTime);
    on<LoadReviewStreak>(_onLoadReviewStreak);
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
      final words = await repository.getUserWords(status: event.status, limit: 50, offset: 0);
      final stats = _lastStats ?? await repository.getUserStats();
      _lastStats = stats;
      emit(VocabularyLoaded(
        words: words,
        stats: stats,
        selectedStatus: event.status,
        hasMore: words.length == 50,
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
      // Pre-check duplicate locally if possible
      final currentState = state;
      if (currentState is VocabularyLoaded) {
        final exists = currentState.words.any((w) => w.word.toLowerCase().trim() == event.word.word.toLowerCase().trim());
        if (exists) {
          emit(WordExists(word: event.word));
          return;
        }
      }
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
      emit(VocabularyLoaded(words: words, stats: stats, hasMore: false));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreVocabulary event,
    Emitter<VocabularyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! VocabularyLoaded || !currentState.hasMore) return;
    try {
      final offset = currentState.words.length;
      final more = await repository.getUserWords(
        status: currentState.selectedStatus,
        limit: 50,
        offset: offset,
      );
      final merged = [...currentState.words, ...more];
      emit(currentState.copyWith(words: merged, hasMore: more.length == 50));
    } catch (_) {}
  }

  // Yeni öğrenme sistemi metodları
  Future<void> _onRecordLearningActivity(
    RecordLearningActivity event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      await repository.recordLearningActivity(event.activity);
      // Activity kaydedildikten sonra stats'i güncelle
      _lastStats = null;
      add(RefreshVocabulary());
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onLoadWordsNeedingReview(
    LoadWordsNeedingReview event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final words = await repository.getWordsNeedingReview(limit: event.limit);
      final stats = _lastStats ?? await repository.getUserStats();
      emit(VocabularyLoaded(words: words, stats: stats, hasMore: false));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onLoadOverdueWords(
    LoadOverdueWords event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final words = await repository.getOverdueWords(limit: event.limit);
      final stats = _lastStats ?? await repository.getUserStats();
      emit(VocabularyLoaded(words: words, stats: stats, hasMore: false));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onLoadLearningAnalytics(
    LoadLearningAnalytics event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      await repository.getLearningAnalytics();
      // Analytics'i state'e eklemek için VocabularyLoaded state'ini genişletmek gerekebilir
      // Şimdilik sadece başarılı olduğunu belirtelim
      emit(VocabularyLoaded(words: const [], stats: _lastStats ?? await repository.getUserStats()));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  // Aralıklı tekrar sistemi metodları
  Future<void> _onLoadDailyReviewWords(
    LoadDailyReviewWords event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final words = await repository.getDailyReviewWords();
      final stats = _lastStats ?? await repository.getUserStats();
      emit(VocabularyLoaded(words: words, stats: stats, hasMore: false));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onLoadReviewStats(
    LoadReviewStats event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      await repository.getReviewStats();
      final stats = _lastStats ?? await repository.getUserStats();
      emit(VocabularyLoaded(words: const [], stats: stats, hasMore: false));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onStartReviewSession(
    StartReviewSession event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      final session = await repository.startReviewSession();
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
      await repository.completeReviewSession(event.session);
      _lastStats = null;
      add(RefreshVocabulary());
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onLoadNextReviewTime(
    LoadNextReviewTime event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      await repository.getNextReviewTime();
      final stats = _lastStats ?? await repository.getUserStats();
      emit(VocabularyLoaded(words: const [], stats: stats, hasMore: false));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }

  Future<void> _onLoadReviewStreak(
    LoadReviewStreak event,
    Emitter<VocabularyState> emit,
  ) async {
    try {
      await repository.getReviewStreak();
      final stats = _lastStats ?? await repository.getUserStats();
      emit(VocabularyLoaded(words: const [], stats: stats, hasMore: false));
    } catch (e) {
      emit(VocabularyError(message: e.toString()));
    }
  }
}
