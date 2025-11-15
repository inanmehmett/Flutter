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
    
    // ✅ FIX: ALWAYS prefer incoming (backend) data over cached data
    // Only merge recentActivities from cache since it's not stored in backend
    return _wordStateById[incoming.id] = incoming.copyWith(
      // Preserve local-only activities (not stored in backend)
      recentActivities: existing.recentActivities.isNotEmpty 
          ? existing.recentActivities 
          : incoming.recentActivities,
    );
  }

  void upsertWord(VocabularyWord word) {
    _wordStateById[word.id] = word;
  }

  VocabularyWord? getById(int id) => _wordStateById[id];

  void removeWord(int id) {
    _wordStateById.remove(id);
  }

  void appendActivity(int wordId, LearningActivity activity, {int keep = 10}) {
    final current = _wordStateById[wordId];
    if (current == null) return;
    final updated = [activity, ...current.recentActivities].take(keep).toList();
    _wordStateById[wordId] = current.copyWith(recentActivities: updated);
  }

  List<VocabularyWord> allWords() => _wordStateById.values.toList();

  /// Clear all words from the store (used during logout)
  void clearAll() {
    _wordStateById.clear();
  }
}


