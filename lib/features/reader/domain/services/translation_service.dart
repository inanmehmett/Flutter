import 'package:daily_english/core/network/network_manager.dart';
import 'package:daily_english/core/cache/cache_manager.dart';

class TranslationService {
  final NetworkManager _networkManager;
  final CacheManager _cacheManager;

  TranslationService({
    required NetworkManager networkManager,
    required CacheManager cacheManager,
  })  : _networkManager = networkManager,
        _cacheManager = cacheManager;

  Future<String> translateText({
    required String text,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final cacheKey = 'translation_${text}_${sourceLanguage}_$targetLanguage';

    try {
      final cachedTranslation = await _cacheManager.getData<String>(cacheKey);
      if (cachedTranslation != null) {
        return cachedTranslation;
      }

      final response = await _networkManager.post(
        '/translate',
        data: {
          'text': text,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
        },
      );

      final translation = response.data['translation'] as String;
      await _cacheManager.setData(cacheKey, translation);
      return translation;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>> translateBatch({
    required List<String> texts,
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final cacheKey =
        'batch_translation_${texts.join()}_${sourceLanguage}_$targetLanguage';

    try {
      final cachedTranslations =
          await _cacheManager.getData<Map<String, String>>(cacheKey);
      if (cachedTranslations != null) {
        return cachedTranslations;
      }

      final response = await _networkManager.post(
        '/translate/batch',
        data: {
          'texts': texts,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
        },
      );

      final translations =
          Map<String, String>.from(response.data['translations']);
      await _cacheManager.setData(cacheKey, translations);
      return translations;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getAvailableLanguages() async {
    const cacheKey = 'available_languages';

    try {
      final cachedLanguages =
          await _cacheManager.getData<List<String>>(cacheKey);
      if (cachedLanguages != null) {
        return cachedLanguages;
      }

      final response = await _networkManager.get('/languages');
      final languages = (response.data['data']['languages'] as List)
          .map((lang) => lang as String)
          .toList();

      await _cacheManager.setData(cacheKey, languages);
      return languages;
    } catch (e) {
      rethrow;
    }
  }
}
