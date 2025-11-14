import 'package:dio/dio.dart';
import '../../../../core/network/network_manager.dart';
import '../../../../core/utils/json_extensions.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../../domain/entities/vocabulary_stats.dart';
import '../../domain/entities/learning_activity.dart';
import '../../domain/repositories/vocabulary_repository.dart';
import '../../domain/services/spaced_repetition_service.dart';
import '../../domain/services/review_session.dart';
import '../../domain/services/learning_analytics_service.dart';
// Legacy service imports kept for fallback; to be removed after full migration
import '../../../vocab/domain/services/vocab_learning_service.dart';
import '../../../vocab/domain/entities/user_word_entity.dart' as ue;
import '../../../../core/di/injection.dart';
import '../local/local_vocabulary_store.dart';

class VocabularyRepositoryImpl implements VocabularyRepository {
  final VocabLearningService _svc = getIt<VocabLearningService>();
  final LocalVocabularyStore _store = LocalVocabularyStore();
  final NetworkManager _net = getIt<NetworkManager>();
  int? _activeSessionId;

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
    // ✅ Use case-insensitive parsing to handle both camelCase and PascalCase
    final status = _statusFromString(e.getString('status', defaultValue: 'new_'));
    final id = e.getInt('id', defaultValue: 0);
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
    
    // 🔍 DEBUG: Log parsed data to verify backend response
    print('🔄 [VOCAB] Parsing word "$word" (ID: $id) - '
          'ReviewCount: $reviewCount, CorrectCount: $correctCount, '
          'Status: $status, Consecutive: $consecutive');
    
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

  @override
  Future<List<VocabularyWord>> getUserWords({
    String? searchQuery,
    VocabularyStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
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
      final serverList = items.map((e) => _fromServer(e as Map<String, dynamic>)).toList();
      // Union with local optimistic words not yet on the server
      final localOnly = _store
          .allWords()
          .where((w) => !serverList.any((s) => s.id == w.id))
          .toList();
      return [...localOnly, ...serverList];
    } on DioException {
      // Fallback to legacy service if backend not ready
      final list = await _svc.listWords(query: searchQuery);
      var words = list.map(_mapEntity).toList();
      if (status != null) {
        words = words.where((w) => w.status == status).toList();
      }
      final int start = offset.clamp(0, words.length);
      final int end = (offset + limit).clamp(0, words.length);
      if (start >= end) return <VocabularyWord>[];
      return words.sublist(start, end);
    }
  }

  @override
  Future<VocabularyWord?> getWordById(int id) async {
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
  Future<List<VocabularyWord>> searchWords(String query) async {
    final list = await _svc.listWords(query: query);
    return list.map(_mapEntity).toList();
  }

  @override
  Future<List<VocabularyWord>> getWordsForReview(int limit) async {
    // Prefer server-side due selection
    try {
      final resp = await _retry(() => _net.get('/api/ApiUserVocabulary', queryParameters: {
        'due': true,
        'offset': 0,
        'limit': limit,
      }));
      final data = (resp.data['data'] ?? {});
      final items = (data['items'] as List? ?? const []).cast<dynamic>();
      return items.map((e) => _fromServer(e as Map<String, dynamic>)).toList();
    } catch (_) {
      // Fallback local
      final list = await _svc.listWords();
      final all = list.map(_mapEntity).toList();
      final due = all.where((w) => w.needsReview).toList();
      return due.take(limit).toList();
    }
    // Note: Prioritization can be reintroduced using server-enriched analytics if needed
  }

  @override
  Future<void> markWordReviewed(int wordId, bool isCorrect) async {
    try {
      // 🔍 DEBUG: Log review attempt
      print('📝 [VOCAB] Marking word $wordId as ${isCorrect ? "CORRECT" : "WRONG"}');
      
      final resp = await _retry(() => _net.post('/api/ApiUserVocabulary/$wordId/review', data: { 'isCorrect': isCorrect }));
      
      // 🔍 DEBUG: Log backend response
      print('✅ [VOCAB] Backend response: ${resp.data}');
      
      // Backend response contains updated word data; fetch and update local store
      final updated = await getWordById(wordId);
      if (updated != null) {
        // 🔍 DEBUG: Log updated word stats
        print('📊 [VOCAB] Updated stats - ReviewCount: ${updated.reviewCount}, '
              'CorrectCount: ${updated.correctCount}, Status: ${updated.status.name}');
        _store.upsertWord(updated);
      } else {
        print('⚠️ [VOCAB] Failed to fetch updated word $wordId');
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
      // 🔍 DEBUG: Log error
      print('❌ [VOCAB] Error marking word reviewed: $e');
      
      // Fallback: optimistic local update
      final current = _store.getById(wordId);
      if (current == null) {
        print('⚠️ [VOCAB] Word $wordId not found in local store');
        return;
      }
      print('🔄 [VOCAB] Using fallback local update for word $wordId');
      final updated = SpacedRepetitionService.processReviewResult(
        word: current,
        isCorrect: isCorrect,
        responseTimeMs: 3000,
      );
      await updateWord(updated);
    }
  }

  @override
  Future<List<VocabularyWord>> addWordsFromText(String text, int readingTextId) async {
    return [];
  }

  @override
  Future<void> syncWords() async {
    return;
  }

  // Yeni öğrenme sistemi metodları
  @override
  Future<void> recordLearningActivity(LearningActivity activity) async {
    // Şimdilik boş implementasyon - gelecekte local storage'a kaydedilecek
    return;
  }

  @override
  Future<List<LearningActivity>> getWordActivities(int wordId, {int limit = 10}) async {
    // Şimdilik boş liste döndür - gelecekte local storage'dan alınacak
    return [];
  }

  @override
  Future<List<VocabularyWord>> getWordsNeedingReview({int limit = 20}) async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    
    // Review'e ihtiyacı olan kelimeleri filtrele
    final reviewWords = words.where((word) => word.needsReview).toList();
    
    // Limit uygula
    return reviewWords.take(limit).toList();
  }

  @override
  Future<List<VocabularyWord>> getOverdueWords({int limit = 10}) async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    
    // Geciken kelimeleri filtrele
    final overdueWords = words.where((word) => word.isOverdue).toList();
    
    // Limit uygula
    return overdueWords.take(limit).toList();
  }

  @override
  Future<Map<String, dynamic>> getLearningAnalytics() async {
    final list = await _svc.listWords();
    final words = list.map(_mapEntity).toList();
    
    final totalWords = words.length;
    final newWords = words.where((w) => w.status == VocabularyStatus.new_).length;
    final learningWords = words.where((w) => w.status == VocabularyStatus.learning).length;
    final knownWords = words.where((w) => w.status == VocabularyStatus.known).length;
    final masteredWords = words.where((w) => w.status == VocabularyStatus.mastered).length;
    
    final wordsNeedingReview = words.where((w) => w.needsReview).length;
    final overdueWords = words.where((w) => w.isOverdue).length;
    
    // Ortalama doğruluk oranı
    final totalAccuracy = words.fold<double>(0.0, (sum, word) => sum + word.accuracyRate);
    final averageAccuracy = totalWords > 0 ? totalAccuracy / totalWords : 0.0;
    
    // Bugün eklenen kelimeler
    final today = DateTime.now();
    final wordsAddedToday = words.where((w) => 
      w.addedAt.year == today.year && 
      w.addedAt.month == today.month && 
      w.addedAt.day == today.day
    ).length;
    
    final wordsReviewedToday = words.where((w) => w.lastReviewedAt != null && w.lastReviewedAt!.year == today.year && w.lastReviewedAt!.month == today.month && w.lastReviewedAt!.day == today.day).length;
    
    // Streak hesaplama (basit implementasyon)
    final streakDays = SpacedRepetitionService.calculateReviewStreak(words);
    
    return {
      'totalWords': totalWords,
      'newWords': newWords,
      'learningWords': learningWords,
      'knownWords': knownWords,
      'masteredWords': masteredWords,
      'wordsNeedingReview': wordsNeedingReview,
      'overdueWords': overdueWords,
      'averageAccuracy': averageAccuracy,
      'wordsAddedToday': wordsAddedToday,
      'wordsReviewedToday': wordsReviewedToday,
      'streakDays': streakDays,
      'learningProgress': totalWords > 0 ? (knownWords + masteredWords) / totalWords : 0.0,
      'difficultyDistribution': _calculateDifficultyDistribution(words),
    };
  }

  // Removed local added-at streak; use review-based streak from service

  Map<String, int> _calculateDifficultyDistribution(List<VocabularyWord> words) {
    final distribution = <String, int>{
      'easy': 0,
      'medium': 0,
      'hard': 0,
    };
    
    for (final word in words) {
      if (word.difficultyLevel < 0.3) {
        distribution['easy'] = distribution['easy']! + 1;
      } else if (word.difficultyLevel < 0.7) {
        distribution['medium'] = distribution['medium']! + 1;
      } else {
        distribution['hard'] = distribution['hard']! + 1;
      }
    }
    
    return distribution;
  }

  // Aralıklı tekrar sistemi metodları
  @override
  Future<List<VocabularyWord>> getDailyReviewWords() async {
    // Prefer server-side due list with a reasonable cap
    try {
      final resp = await _retry(() => _net.get('/api/ApiUserVocabulary', queryParameters: {
        'due': true,
        'offset': 0,
        'limit': 200,
      }));
      final data = (resp.data['data'] ?? {});
      final items = (data['items'] as List? ?? const []).cast<dynamic>();
      final words = items.map((e) => _fromServer(e as Map<String, dynamic>)).toList();
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
        // Review mode: Only due words (Quiz widget kullanıyor - en az 4 kelime gerekiyor)
        reviewWords = await getDailyReviewWords();
        // Quiz için yeterli kelime yoksa, tüm kelimeleri kullan
        if (reviewWords.length < 4) {
          final allWords = await getUserWords(limit: 100);
          if (allWords.length < 4) {
            throw Exception('Quiz için en az 4 kelime gereklidir. Şu anda ${allWords.length} kelimeniz var. Lütfen Vocabulary Notebook\'a daha fazla kelime ekleyin.');
          }
          // Due kelime yoksa, tüm kelimelerden quiz yap
          reviewWords = allWords;
        }
        break;
      case 'all':
        // Quiz mode: All words, randomized
        // Quiz için en az 4 kelime gerekiyor (1 doğru + 3 yanlış cevap için)
        reviewWords = await getUserWords(limit: 100);
        if (reviewWords.length < 4) {
          throw Exception('Quiz için en az 4 kelime gereklidir. Şu anda ${reviewWords.length} kelimeniz var. Lütfen Vocabulary Notebook\'a daha fazla kelime ekleyin.');
        }
        reviewWords.shuffle();
        break;
      case 'difficult':
        // Practice mode: Difficult words (high difficulty or low consecutive correct)
        final allWords = await getUserWords(limit: 100);
        reviewWords = allWords.where((w) =>
          w.difficultyLevel > 0.6 || w.consecutiveCorrectCount < 2
        ).toList();
        if (reviewWords.isEmpty) {
          // Fallback: use words that need review
          reviewWords = await getDailyReviewWords();
        }
        break;
      default:
        // Flashcard mode: Random batch
        reviewWords = await getUserWords(limit: 20);
        reviewWords.shuffle();
    }
    
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
