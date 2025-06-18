
abstract class TranslationRepository {
  Future<String> translateWord(String word);
  Future<List<String>> translateBatch(List<String> words);
}
