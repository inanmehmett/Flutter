import 'package:hive/hive.dart';
import '../models/user_word.dart';

class UserWordLocalDataSource {
  static const String boxName = 'user_words';
  final Box<UserWordModel> box;
  UserWordLocalDataSource(this.box);

  Future<void> add(UserWordModel model) async {
    await box.put(model.id, model);
  }

  Future<List<UserWordModel>> list({String? query, String? cefr, int? progress}) async {
    final values = box.values.toList();
    return values.where((m) {
      final okQuery = (query == null || query.isEmpty) || m.word.toLowerCase().contains(query.toLowerCase()) || m.meaningTr.toLowerCase().contains(query.toLowerCase());
      final okCefr = cefr == null || cefr.isEmpty || (m.cefr ?? '').toLowerCase() == cefr.toLowerCase();
      final okProg = progress == null || m.progress == progress;
      return okQuery && okCefr && okProg;
    }).toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  Future<void> updateProgress(String id, int progress) async {
    final existing = box.get(id);
    if (existing != null) {
      existing.progress = progress;
      await existing.save();
    }
  }

  Future<void> updateDetails(
    String id, {
    String? description,
    String? example,
    String? partOfSpeech,
    String? cefr,
    String? audioUrl,
    String? imageUrl,
    String? category,
    List<String>? synonyms,
    List<String>? antonyms,
  }) async {
    final existing = box.get(id);
    if (existing == null) return;
    if (description != null) existing.description = description;
    if (example != null) existing.example = example;
    if (partOfSpeech != null) existing.partOfSpeech = partOfSpeech;
    if (cefr != null) existing.cefr = cefr;
    if (audioUrl != null) existing.audioUrl = audioUrl;
    if (imageUrl != null) existing.imageUrl = imageUrl;
    if (category != null) existing.category = category;
    if (synonyms != null) existing.synonyms = List<String>.from(synonyms);
    if (antonyms != null) existing.antonyms = List<String>.from(antonyms);
    await existing.save();
  }

  Future<void> remove(String id) async {
    await box.delete(id);
  }
}
