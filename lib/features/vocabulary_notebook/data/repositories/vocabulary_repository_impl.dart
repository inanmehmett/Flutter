import 'package:dio/dio.dart';
import '../../../../core/network/network_manager.dart';
import '../../../../core/utils/json_extensions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/vocabulary_stats.dart';
import '../../domain/entities/learning_activity.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../domain/services/spaced_repetition_service.dart';
import '../../domain/services/review_session.dart';
// Legacy service imports kept for fallback; to be removed after full migration
import '../../../word_exercises/domain/services/vocab_learning_service.dart';
import '../../../word_exercises/domain/entities/user_word_entity.dart' as ue;
import '../../../../core/di/injection.dart';
import '../../../../core/storage/storage_manager.dart';
import '../../../../core/services/xp_state_service.dart';
import '../local/local_vocabulary_store.dart';

class VocabularyRepositoryImpl implements VocabularyRepository {
  static const String _deletedWordsKey = 'vocab_deleted_word_ids';
  
  final VocabLearningService _svc = getIt<VocabLearningService>();
  final LocalVocabularyStore _store = LocalVocabularyStore();
  final NetworkManager _net = getIt<NetworkManager>();
  final StorageManager _storage = getIt<StorageManager>();
  int? _activeSessionId;
  // Track deleted word IDs to prevent them from being re-added from backend cache
  Set<int> _deletedWordIds = <int>{};
  bool _deletedWordIdsLoaded = false;
  
  /// Ensure deleted word IDs are loaded from persistent storage
  Future<void> _ensureDeletedWordIdsLoaded() async {
    if (_deletedWordIdsLoaded) return;
    try {
      final saved = await _storage.fetch<List<dynamic>>(_deletedWordsKey);
      if (saved != null) {
        _deletedWordIds = saved.cast<int>().toSet();
      } else {
        _deletedWordIds = <int>{};
      }
      _deletedWordIdsLoaded = true;
    } catch (e) {
      Logger.warning('Error loading deleted word IDs: $e');
      _deletedWordIds = <int>{};
      _deletedWordIdsLoaded = true;
    }
  }
  
  /// Save deleted word IDs to persistent storage
  Future<void> _saveDeletedWordIds() async {
    try {
      await _storage.save(_deletedWordsKey, _deletedWordIds.toList());
    } catch (e) {
      Logger.warning('Error saving deleted word IDs: $e');
    }
  }
  
  /// Logout sonrası tüm cache'leri ve state'leri temizle
  void clearCache() {
    _activeSessionId = null;
    _store.clearAll();
    _deletedWordIds.clear();
    _deletedWordIdsLoaded = false;
    _storage.delete(_deletedWordsKey);
  }

  Future<T> _retry<T>(Future<T> Function() run, {int attempts = 2}) async {
    int left = attempts;
    DioException? last;
    while (left-- > 0) {
      try {
        return await run();
      } on DioException catch (e) {
        last = e;
        if (left > 0) await Future.delayed(Duration(milliseconds: 300 * (attempts - left)));
      }
    }
    if (last != null) throw last;
    // Should not reach
    return await run();
  }

  int _stableId(String input) {
    // FNV-1a 64-bit (deterministic across runs/platforms)
    BigInt hash = BigInt.parse('1469598103934665603');
    final BigInt prime = BigInt.parse('1099511628211');
    final BigInt mask = BigInt.parse('18446744073709551615'); // 2^64-1
    for (int i = 0; i < input.length; i++) {
      hash = (hash ^ BigInt.from(input.codeUnitAt(i))) & mask;
      hash = (hash * prime) & mask;
    }
    // Keep it positive and within signed 63-bit range for Flutter widgets
    final BigInt signedMask = BigInt.parse('9223372036854775807'); // 2^63-1
    return (hash & signedMask).toInt();
  }

  VocabularyStatus _mapProgress(int p) {
    if (p <= 0) return VocabularyStatus.new_;
    if (p == 1) return VocabularyStatus.learning;
    return VocabularyStatus.known;
  }

  VocabularyWord _mapEntity(ue.UserWordEntity e) {
    final mapped = VocabularyWord(
      id: _stableId(e.id),
      word: e.word,
      meaning: e.meaningTr,
      personalNote: null,
      description: e.description,
      exampleSentence: e.example,
      synonyms: e.synonyms,
      antonyms: e.antonyms,
      status: _mapProgress(e.progress),
      readingTextId: null,
      addedAt: e.addedAt,
      lastReviewedAt: null,
      reviewCount: 0,
      correctCount: 0,
      consecutiveCorrectCount: 0,
      nextReviewAt: null,
      difficultyLevel: 0.5,
      recentActivities: const [],
    );
    return _store.mergeWithPersisted(mapped);
  }

  VocabularyStatus _statusFromString(String s) {
    switch (s) {
      case 'learning':
        return VocabularyStatus.learning;
      case 'known':
        return VocabularyStatus.known;
      case 'mastered':
        return VocabularyStatus.mastered;
      default:
        return VocabularyStatus.new_;
    }
  }

  VocabularyWord _fromServer(Map<String, dynamic> e) {
    // ✅ CRITICAL FIX: Check if word is deleted FIRST, before any parsing
    final id = e.getInt('id', defaultValue: 0);
    if (id == 0) {
      throw Exception('Invalid word ID: 0');
    }
    
    // ✅ CRITICAL FIX: Don't process deleted words - prevent re-adding from backend cache
    // Check deleted words BEFORE parsing to avoid unnecessary work
    if (_deletedWordIds.contains(id)) {
      throw Exception('Word $id was deleted');
    }
    
    // ✅ Use case-insensitive parsing to handle both camelCase and PascalCase
    final status = _statusFromString(e.getString('status', defaultValue: 'new_'));
    
    final word = e.getString('word', defaultValue: '');
    final meaning = e.getString('meaning', defaultValue: '');
    final notes = e.getIgnoreCase<String>('notes');
    final description = e.getIgnoreCase<String>('description');
    final exampleSentence = e.getIgnoreCase<String>('exampleSentence');
    final createdAt = e.getDateTime('createdAt') ?? DateTime.now();
    final lastReviewedAt = e.getDateTime('lastReviewedAt');
    final nextReviewAt = e.getDateTime('nextReviewAt');
    
    // ✅ CRITICAL FIX: Use safe getters for review counts
    final reviewCount = e.getInt('reviewCount', defaultValue: 0);
    final correctCount = e.getInt('correctCount', defaultValue: 0);
    final consecutive = e.getInt('consecutiveCorrectCount', defaultValue: 0);
    final difficulty = e.getDouble('difficulty', defaultValue: 0.5);
    
    // WordLevel (CEFR seviyesi): Backend'den enum olarak geliyor (A1, A2, B1, B2, C1, C2, Unknown)
    // Backend'de LevelTypeId enum: Unknown=0, A1=1, A2=2, B1=3, B2=4, C1=5, C2=6
    String? wordLevelStr;
    final wordLevelValue = e.getIgnoreCase('wordLevel');
    
    if (wordLevelValue != null) {
      // Enum string olarak geliyor (örn: "A1", "B2", "Unknown")
      if (wordLevelValue is String) {
        final levelStr = wordLevelValue.trim();
        wordLevelStr = (levelStr == 'Unknown' || levelStr.isEmpty) ? null : levelStr;
        Logger.debug('WordLevel parsed as String: "$levelStr" -> "$wordLevelStr"');
      } else if (wordLevelValue is int) {
        // Enum integer olarak gelirse
        wordLevelStr = wordLevelValue == 0 ? null : _mapLevelTypeIdToString(wordLevelValue);
        Logger.debug('WordLevel parsed as int: $wordLevelValue -> "$wordLevelStr"');
      } else {
        // Diğer durumlar için toString() dene
        final levelStr = wordLevelValue.toString().trim();
        if (levelStr.isNotEmpty && levelStr != 'Unknown' && levelStr != '0') {
          wordLevelStr = levelStr;
          Logger.debug('WordLevel parsed via toString(): "$levelStr"');
        }
      }
    }
    
    // Parse synonyms and antonyms from backend
    final synonymsList = e.getList<String>('synonyms');
    final antonymsList = e.getList<String>('antonyms');
    
    return _store.mergeWithPersisted(
      VocabularyWord(
        id: id,
        word: word,
        meaning: meaning,
        status: status,
        addedAt: createdAt,
        lastReviewedAt: lastReviewedAt,
        reviewCount: reviewCount,
        correctCount: correctCount,
        consecutiveCorrectCount: consecutive,
        nextReviewAt: nextReviewAt,
        difficultyLevel: difficulty,
        wordLevel: wordLevelStr, // CEFR seviyesi
        personalNote: (notes != null && notes.isNotEmpty) ? notes : null,
        description: (description != null && description.isNotEmpty) ? description : null,
        exampleSentence: (exampleSentence != null && exampleSentence.isNotEmpty) ? exampleSentence : null,
        synonyms: synonymsList,
        antonyms: antonymsList,
        readingTextId: null,
        recentActivities: const [],
      ),
    );
  }

  // LevelTypeId enum değerini string'e çevir (0=Unknown, 1=A1, 2=A2, 3=B1, 4=B2, 5=C1, 6=C2)
  String? _mapLevelTypeIdToString(int value) {
    switch (value) {
      case 1: return 'A1';
      case 2: return 'A2';
      case 3: return 'B1';
      case 4: return 'B2';
      case 5: return 'C1';
      case 6: return 'C2';
      default: return null;
    }
  }

  @override
  Future<List<VocabularyWord>> getUserWords({
    String? searchQuery,
    VocabularyStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    // Ensure deleted word IDs are loaded before processing
    await _ensureDeletedWordIdsLoaded();
    
    try {
      final resp = await _retry(() => _net.get('/api/ApiUserVocabulary', queryParameters: {
        if (searchQuery != null && searchQuery.trim().isNotEmpty) 'search': searchQuery.trim(),
        if (status != null)
          'status': switch (status) {
            VocabularyStatus.new_ => 'new_',
            VocabularyStatus.learning => 'learning',
            VocabularyStatus.known => 'known',
            VocabularyStatus.mastered => 'mastered',
          },
        'offset': offset,
        'limit': limit,
      }));
      final data = (resp.data['data'] ?? {});
      final items = (data['items'] as List? ?? const []).cast<dynamic>();
      // Filter out deleted words from backend response (prevents re-adding from cache)
      final serverList = <VocabularyWord>[];
      for (final item in items) {
        try {
          final word = _fromServer(item as Map<String, dynamic>);
          // _fromServer already filters deleted words, so we can add directly
          serverList.add(word);
        } catch (e) {
          // Skip deleted words or parsing errors silently
          // Deleted words are expected and don't need logging
          if (!e.toString().contains('was deleted') && !e.toString().contains('Invalid word ID')) {
            // Only log unexpected parsing errors
            Logger.warning('Error parsing word: $e');
          }
        }
      }
      // Union with local optimistic words not yet on the server
      // Apply status filter to local words as well
      final localOnly = _store
          .allWords()
          .where((w) => 
            !serverList.any((s) => s.id == w.id) && 
            !_deletedWordIds.contains(w.id) &&
            (status == null || w.status == status)
          )
          .toList();
      return [...localOnly, ...serverList];
    } on DioException catch (e) {
      // Handle 401 Unauthorized specifically
      if (e.response?.statusCode == 401) {
        Logger.warning('Unauthorized access - user may need to login');
        // Return empty list for 401 - user is not authenticated
        return <VocabularyWord>[];
      }
      
      // Handle other errors
      Logger.error('Backend error in getUserWords', e);
      
      // Return empty list for network errors (don't show stale data)
      // Fallback legacy service removed for security reasons
      return <VocabularyWord>[];
    }
  }

  @override
  Future<VocabularyWord?> getWordById(int id) async {
    // Ensure deleted word IDs are loaded before processing
    await _ensureDeletedWordIdsLoaded();
    
    try {
      final resp = await _retry(() => _net.get('/api/ApiUserVocabulary/$id'));
      // Backend returns: { success: true, message: "...", data: UserVocabularyDto }
      final responseData = resp.data as Map<String, dynamic>?;
      if (responseData == null) {
        // Try local fallback
        final localWord = _store.getById(id);
        if (localWord != null) return localWord;
        throw Exception('Backend response is null');
      }
      
      if ((responseData['success'] as bool?) != true) {
        final errorMsg = responseData['message'] as String?;
        // Try local fallback
        final localWord = _store.getById(id);
        if (localWord != null) return localWord;
        throw Exception(errorMsg ?? 'Backend returned error');
      }
      
      final data = responseData['data'] as Map<String, dynamic>?;
      if (data == null) {
        // Try local fallback
        final localWord = _store.getById(id);
        if (localWord != null) return localWord;
        throw Exception('Backend response data is null');
      }
      
      try {
        final word = _fromServer(data);
        // Update local store with fresh data
        _store.upsertWord(word);
        return word;
      } catch (parseError) {
        // Try local fallback if parsing fails
        final localWord = _store.getById(id);
        if (localWord != null) return localWord;
        throw Exception('Failed to parse word data: ${parseError.toString()}');
      }
    } on DioException catch (dio) {
      // 404: not found on server (e.g., local-only word) -> return local silently
      if (dio.response?.statusCode == 404) {
        final localWord = _store.getById(id);
        if (localWord != null) return localWord;
        return null;
      }
      // Other network errors: fall through to generic fallback
      // no-op, proceed to generic catch
      final localWord = _store.getById(id);
      if (localWord != null) return localWord;
      
      // Then try legacy service
      try {
        final list = await _svc.listWords();
        for (final entity in list) {
          if (_stableId(entity.id) == id) {
            final word = _mapEntity(entity);
            _store.upsertWord(word);
            return word;
          }
        }
      } catch (_) {}
      throw Exception('Kelime yüklenemedi (ID: $id): ${dio.message}');
    } catch (e) {
      // Fallback: try local store first
      try {
        final localWord = _store.getById(id);
        if (localWord != null) return localWord;
      } catch (_) {
        // Ignore local store errors
      }
      
      // Then try legacy service
      try {
        final list = await _svc.listWords();
        // Legacy service uses string IDs, try to find by matching hash
        for (final entity in list) {
          if (_stableId(entity.id) == id) {
            final word = _mapEntity(entity);
            _store.upsertWord(word);
            return word;
          }
        }
      } catch (_) {
        // Ignore legacy service errors
      }
      
      // If all fallbacks fail, rethrow with better error message
      throw Exception('Kelime yüklenemedi (ID: $id): ${e.toString()}');
    }
  }

  @override
  Future<VocabularyWord> addWord(VocabularyWord word) async {
    // Ensure deleted word IDs are loaded before processing
    await _ensureDeletedWordIdsLoaded();
    
    try {
      final resp = await _retry(() => _net.post('/api/ApiUserVocabulary', data: {
        // 'stableId' intentionally omitted to let backend generate a GUID
        'word': word.word.trim(),
        'meaning': word.meaning.trim(),
        'notes': word.personalNote,
        'status': switch (word.status) {
          VocabularyStatus.new_ => 'new_',
          VocabularyStatus.learning => 'learning',
          VocabularyStatus.known => 'known',
          VocabularyStatus.mastered => 'mastered',
        },
        if (word.readingTextId != null) 'readingTextId': word.readingTextId,
      }));
      final dto = resp.data['data'] as Map<String, dynamic>;
      final mapped = _fromServer(dto);
      _store.upsertWord(mapped);
      return mapped;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // duplicate: fetch list and return first match
        final list = await getUserWords(searchQuery: word.word, limit: 1);
        if (list.isNotEmpty) return list.first;
      }
      // fallback legacy
      final existing = await _svc.listWords(query: word.word);
      if (existing.any((x) => x.word.toLowerCase().trim() == word.word.toLowerCase().trim())) {
        return _mapEntity(existing.first);
      }
      await _svc.addWord(word: word.word, meaningTr: word.meaning);
      final list = await _svc.listWords(query: word.word);
      final mapped = list.isNotEmpty ? _mapEntity(list.first) : word.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      _store.upsertWord(mapped);
      return mapped;
    }
  }

  @override
  Future<VocabularyWord> updateWord(VocabularyWord word) async {
    try {
      await _retry(() => _net.put('/api/ApiUserVocabulary/${word.id}', data: {
        'stableId': '',
        'word': word.word.trim(),
        'meaning': word.meaning.trim(),
        'notes': word.personalNote,
        'status': switch (word.status) {
          VocabularyStatus.new_ => 'new_',
          VocabularyStatus.learning => 'learning',
          VocabularyStatus.known => 'known',
          VocabularyStatus.mastered => 'mastered',
        },
      }));
      _store.upsertWord(word);
      return word;
    } on DioException {
      // Fallback legacy
      final p = switch (word.status) { VocabularyStatus.new_ => 0, VocabularyStatus.learning => 1, _ => 2 };
      final list = await _svc.listWords(query: word.word);
      if (list.isNotEmpty) {
        await _svc.updateProgress(list.first.id, p);
      }
      _store.upsertWord(word);
      return word;
    }
  }

  @override
  Future<void> deleteWord(int id) async {
    // Ensure deleted word IDs are loaded before deleting
    await _ensureDeletedWordIdsLoaded();
    
    try {
      await _retry(() => _net.delete('/api/ApiUserVocabulary/$id'));
    } catch (_) {
      final list = await _svc.listWords();
      final idx = list.indexWhere((x) => _stableId(x.id) == id);
      if (idx != -1) {
        await _svc.removeWord(list[idx].id);
      }
    }
    _store.removeWord(id);
    // Track deleted word ID to prevent it from being re-added from backend cache
    _deletedWordIds.add(id);
    await _saveDeletedWordIds();
  }

  @override
  Future<VocabularyStats> getUserStats() async {
    try {
      final resp = await _retry(() => _net.get('/api/ApiUserVocabulary/stats'));
      final d = resp.data['data'] as Map<String, dynamic>;
      final total = (d['total'] ?? 0) as int;
      int by(String key) {
        final list = (d['byStatus'] as List? ?? const []);
        final found = list.cast<Map>().firstWhere((x) => x['status'] == key, orElse: () => const {});
        return (found['count'] ?? 0) as int;
      }
      return VocabularyStats(
        totalWords: total,
        newWords: by('new_'),
        learningWords: by('learning'),
        knownWords: by('known'),
        masteredWords: by('mastered'),
        wordsNeedingReview: 0,
        averageAccuracy: 0,
        wordsAddedToday: (d['todayAdded'] ?? 0) as int,
        wordsReviewedToday: (d['todayReviewed'] ?? 0) as int,
        streakDays: 0,
      );
    } catch (_) {
      final list = await _svc.listWords();
      final words = list.map(_mapEntity).toList();
      final totalWords = words.length;
      final newWords = words.where((w) => w.status == VocabularyStatus.new_).length;
      final learningWords = words.where((w) => w.status == VocabularyStatus.learning).length;
      final knownWords = words.where((w) => w.status == VocabularyStatus.known).length;
      final masteredWords = words.where((w) => w.status == VocabularyStatus.mastered).length;
      final wordsNeedingReview = words.where((w) => w.needsReview).length;
      final totalAccuracy = words.fold<double>(0.0, (sum, w) => sum + w.accuracyRate);
      final averageAccuracy = totalWords > 0 ? totalAccuracy / totalWords : 0.0;
      final today = DateTime.now();
      final wordsAddedToday = words.where((w) => w.addedAt.year == today.year && w.addedAt.month == today.month && w.addedAt.day == today.day).length;
      final wordsReviewedToday = words.where((w) => w.lastReviewedAt != null && w.lastReviewedAt!.year == today.year && w.lastReviewedAt!.month == today.month && w.lastReviewedAt!.day == today.day).length;
      return VocabularyStats(
        totalWords: totalWords,
        newWords: newWords,
        learningWords: learningWords,
        knownWords: knownWords,
        masteredWords: masteredWords,
        wordsNeedingReview: wordsNeedingReview,
        averageAccuracy: averageAccuracy,
        wordsAddedToday: wordsAddedToday,
        wordsReviewedToday: wordsReviewedToday,
        streakDays: SpacedRepetitionService.calculateReviewStreak(words),
      );
    }
  }

  @override
  Future<void> markWordReviewed(int wordId, bool isCorrect) async {
    try {
      Logger.debug('Marking word $wordId as ${isCorrect ? "CORRECT" : "WRONG"}');
      
      final resp = await _retry(() => _net.post('/api/ApiUserVocabulary/$wordId/review', data: { 'isCorrect': isCorrect }));
      
      // Backend response contains updated word data; fetch and update local store
      final updated = await getWordById(wordId);
      if (updated != null) {
        Logger.debug('Updated stats - ReviewCount: ${updated.reviewCount}, '
              'CorrectCount: ${updated.correctCount}, Status: ${updated.status.name}');
        _store.upsertWord(updated);
      } else {
        Logger.warning('Failed to fetch updated word $wordId');
      }
      
      // Eğer aktif session varsa item ekleyelim
      if (_activeSessionId != null) {
        await _retry(() => _net.post('/api/ApiUserVocabulary/session/${_activeSessionId}/item', data: {
          'vocabularyId': wordId,
          'isCorrect': isCorrect,
          'timeMs': 3000,
        }));
      }
      return; // Success: backend handled it
    } catch (e) {
      Logger.error('Error marking word reviewed', e);
      
      // Fallback: optimistic local update
      final current = _store.getById(wordId);
      if (current == null) {
        Logger.warning('Word $wordId not found in local store');
        return;
      }
      Logger.debug('Using fallback local update for word $wordId');
      final updated = SpacedRepetitionService.processReviewResult(
        word: current,
        isCorrect: isCorrect,
        responseTimeMs: 3000,
      );
      await updateWord(updated);
    }
  }

  @override
  Future<List<VocabularyWord>> getDailyReviewWords() async {
    // Ensure deleted word IDs are loaded before processing
    await _ensureDeletedWordIdsLoaded();
    
    // Prefer server-side due list with a reasonable cap
    try {
      final resp = await _retry(() => _net.get('/api/ApiUserVocabulary', queryParameters: {
        'due': true,
        'offset': 0,
        'limit': 200,
      }));
      final data = (resp.data['data'] ?? {});
      final items = (data['items'] as List? ?? const []).cast<dynamic>();
      final words = items
          .map((e) => _fromServer(e as Map<String, dynamic>))
          .where((w) => !_deletedWordIds.contains(w.id))
          .toList();
      return SpacedRepetitionService.getDailyReviewWords(words);
    } catch (_) {
      final list = await _svc.listWords();
      final words = list.map(_mapEntity).toList();
      return SpacedRepetitionService.getDailyReviewWords(words);
    }
  }

  @override
  Future<ReviewStats> getReviewStats() async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    return SpacedRepetitionService.calculateReviewStats(words);
  }

  @override
  Future<ReviewSession> startReviewSession({String? modeFilter}) async {
    try {
      final resp = await _retry(() => _net.post('/api/ApiUserVocabulary/session/start', data: {}));
      final data = resp.data['data'] as Map<String, dynamic>?;
      _activeSessionId = (data?['sessionId'] as num?)?.toInt();
    } catch (_) {
      _activeSessionId = null;
    }
    
    // Get words based on mode filter
    List<VocabularyWord> reviewWords;
    switch (modeFilter) {
      case 'due':
        // Review mode: sadece "due" kelimeler
        // Due kelime yoksa boş liste döndür - kullanıcı kitap okumaya yönlendirilecek
        reviewWords = await getDailyReviewWords();
        break;
      case 'all':
        // Quiz mode: tüm kelimelerden rastgele oturum
        reviewWords = await getUserWords(limit: 100);
        reviewWords.shuffle();
        break;
      case 'difficult':
        // Practice mode: Difficult words (high difficulty or low consecutive correct)
        final allWords = await getUserWords(limit: 100);
        reviewWords = allWords.where((w) =>
          w.difficultyLevel > 0.6 || w.consecutiveCorrectCount < 2
        ).toList();
        if (reviewWords.isEmpty) {
          // Fallback: review gereken kelimeleri kullan
          reviewWords = await getDailyReviewWords();
        }
        break;
      default:
        // Flashcard mode: Random batch
        reviewWords = await getUserWords(limit: 20);
        reviewWords.shuffle();
    }

    // Boş liste durumunda da session döndür - UI'da uygun mesaj gösterilecek
    return SpacedRepetitionService.startReviewSession(reviewWords);
  }

  @override
  Future<List<VocabularyWord>> completeReviewSession(ReviewSession session) async {
    // Send full results to backend; backend will batch-apply updates
    try {
      if (_activeSessionId != null) {
        final correct = session.results.where((r) => r.isCorrect).length;
        final secs = session.duration.inSeconds > 0
            ? session.duration.inSeconds
            : DateTime.now().difference(session.startedAt).inSeconds;
        final resp = await _retry(() => _net.post('/api/ApiUserVocabulary/session/${_activeSessionId}/complete', data: {
          'itemsCount': session.results.length,
          'correctCount': correct,
          'durationSeconds': secs.clamp(0, 36000),
          'results': session.results.map((r) => {
            'vocabularyId': int.tryParse(r.wordId) ?? 0,
            'isCorrect': r.isCorrect,
            'timeMs': r.responseTimeMs,
          }).toList(),
        }));

        // Parse patches and update local store
        final data = (resp.data as Map<String, dynamic>?)?['data'] as Map<String, dynamic>?;
        final patches = (data?['patches'] as List<dynamic>?) ?? const [];
        final xpEarned = (data?['xpEarned'] as num?)?.toInt() ?? 0;
        
        // Update XP state immediately (optimistic update)
        if (xpEarned > 0) {
          try {
            final xpStateService = getIt<XPStateService>();
            await xpStateService.incrementDailyXP(xpEarned);
            await xpStateService.incrementTotalXP(xpEarned);
            Logger.info('✅ Updated XP state: +$xpEarned XP');
          } catch (e) {
            Logger.error('Failed to update XP state', e);
          }
        }
        
        final updatedWords = <VocabularyWord>[];
        for (final p in patches) {
          final m = (p as Map).cast<String, dynamic>();
          final id = (m['id'] as num).toInt();
          final current = _store.getById(id);
          if (current == null) continue;
          final patched = current.copyWith(
            reviewCount: (m['reviewCount'] as num?)?.toInt() ?? current.reviewCount,
            correctCount: (m['correctCount'] as num?)?.toInt() ?? current.correctCount,
            consecutiveCorrectCount: (m['consecutiveCorrectCount'] as num?)?.toInt() ?? current.consecutiveCorrectCount,
            status: _statusFromString((m['status'] ?? current.status.name).toString()),
            lastReviewedAt: m['lastReviewedAt'] != null ? DateTime.tryParse(m['lastReviewedAt'].toString()) ?? current.lastReviewedAt : current.lastReviewedAt,
            nextReviewAt: m['nextReviewAt'] != null ? DateTime.tryParse(m['nextReviewAt'].toString()) ?? current.nextReviewAt : current.nextReviewAt,
          );
          _store.upsertWord(patched);
          updatedWords.add(patched);
        }
        return updatedWords;
      }
    } catch (_) {
      // Session completion is optional - individual reviews are already saved
      return const <VocabularyWord>[];
    } finally {
      _activeSessionId = null;
    }
    return const <VocabularyWord>[];
  }

  @override
  Future<DateTime> getNextReviewTime() async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    return SpacedRepetitionService.calculateOptimalReviewTime(words);
  }

  @override
  Future<int> getReviewStreak() async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    return SpacedRepetitionService.calculateReviewStreak(words);
  }
}
