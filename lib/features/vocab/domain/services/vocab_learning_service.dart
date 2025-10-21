import 'package:uuid/uuid.dart';
import '../entities/user_word_entity.dart';
import '../../data/models/user_word.dart';
import '../../data/datasources/user_word_local_data_source.dart';

abstract class VocabLearningServiceProtocol {
  Future<void> addWord({required String word, required String meaningTr, String? example, String? partOfSpeech, String? cefr, String? sourceBookId, String? sourceChapter, List<String> tags});
  Future<List<UserWordEntity>> listWords({String? query, String? cefr, int? progress});
  Future<void> updateProgress(String id, int progress);
  Future<void> removeWord(String id);
}

class VocabLearningService implements VocabLearningServiceProtocol {
  final UserWordLocalDataSource local;
  VocabLearningService(this.local);

  @override
  Future<void> addWord({required String word, required String meaningTr, String? example, String? partOfSpeech, String? cefr, String? sourceBookId, String? sourceChapter, List<String> tags = const []}) async {
    final now = DateTime.now();
    final id = const Uuid().v4();
    final model = UserWordModel(
      id: id,
      word: word,
      meaningTr: meaningTr,
      example: example,
      partOfSpeech: partOfSpeech,
      cefr: cefr,
      progress: 0,
      addedAt: now,
      sourceBookId: sourceBookId,
      sourceChapter: sourceChapter,
      tags: tags,
    );
    await local.add(model);
  }

  @override
  Future<List<UserWordEntity>> listWords({String? query, String? cefr, int? progress}) async {
    final list = await local.list(query: query, cefr: cefr, progress: progress);
    return list.map((m) => UserWordEntity(
      id: m.id,
      word: m.word,
      meaningTr: m.meaningTr,
      example: m.example,
      partOfSpeech: m.partOfSpeech,
      cefr: m.cefr,
      progress: m.progress,
      addedAt: m.addedAt,
      sourceBookId: m.sourceBookId,
      sourceChapter: m.sourceChapter,
      tags: m.tags,
      description: m.description,
      audioUrl: m.audioUrl,
      imageUrl: m.imageUrl,
      category: m.category,
      synonyms: m.synonyms,
      antonyms: m.antonyms,
    )).toList();
  }

  @override
  Future<void> updateProgress(String id, int progress) => local.updateProgress(id, progress);

  @override
  Future<void> removeWord(String id) => local.remove(id);

  Future<void> updateDetails(String id, {String? description, String? example, String? partOfSpeech, String? cefr, String? audioUrl, String? imageUrl, String? category, List<String>? synonyms, List<String>? antonyms}) async {
    await local.updateDetails(id, description: description, example: example, partOfSpeech: partOfSpeech, cefr: cefr, audioUrl: audioUrl, imageUrl: imageUrl, category: category, synonyms: synonyms, antonyms: antonyms);
  }
}
