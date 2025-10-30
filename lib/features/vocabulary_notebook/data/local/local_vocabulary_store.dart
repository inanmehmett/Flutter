import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/learning_activity.dart';

class LocalVocabularyStore {
  static final LocalVocabularyStore _instance = LocalVocabularyStore._internal();
  factory LocalVocabularyStore() => _instance;
  LocalVocabularyStore._internal();

  // In-memory store: wordId -> persisted fields
  final Map<int, VocabularyWord> _wordStateById = <int, VocabularyWord>{};

  VocabularyWord mergeWithPersisted(VocabularyWord incoming) {
    final existing = _wordStateById[incoming.id];
    if (existing == null) {
      // Initialize nextReviewAt if missing using status-based interval
      final initialized = incoming.nextReviewAt == null
          ? incoming.copyWith(nextReviewAt: DateTime.now().add(incoming.nextReviewInterval))
          : incoming;
      _wordStateById[incoming.id] = initialized;
      return initialized;
    }
    // Preserve SRS-specific fields from persisted version when incoming lacks them
    return _wordStateById[incoming.id] = incoming.copyWith(
      lastReviewedAt: existing.lastReviewedAt ?? incoming.lastReviewedAt,
      reviewCount: existing.reviewCount != 0 ? existing.reviewCount : incoming.reviewCount,
      correctCount: existing.correctCount != 0 ? existing.correctCount : incoming.correctCount,
      consecutiveCorrectCount: existing.consecutiveCorrectCount != 0
          ? existing.consecutiveCorrectCount
          : incoming.consecutiveCorrectCount,
      nextReviewAt: existing.nextReviewAt ?? incoming.nextReviewAt,
      difficultyLevel: existing.difficultyLevel != 0.5 ? existing.difficultyLevel : incoming.difficultyLevel,
      recentActivities: existing.recentActivities.isNotEmpty ? existing.recentActivities : incoming.recentActivities,
      status: existing.status, // status updates will flow through updates as well
    );
  }

  void upsertWord(VocabularyWord word) {
    _wordStateById[word.id] = word;
  }

  VocabularyWord? getById(int id) => _wordStateById[id];

  void appendActivity(int wordId, LearningActivity activity, {int keep = 10}) {
    final current = _wordStateById[wordId];
    if (current == null) return;
    final updated = [activity, ...current.recentActivities].take(keep).toList();
    _wordStateById[wordId] = current.copyWith(recentActivities: updated);
  }

  List<VocabularyWord> allWords() => _wordStateById.values.toList();
}


