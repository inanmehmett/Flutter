import 'package:injectable/injectable.dart';
import '../../../../core/network/network_manager.dart';

@lazySingleton
class TranslationService {
  final NetworkManager _network;

  TranslationService(this._network);

  Future<List<Map<String, dynamic>>> getAudioManifest(int readingTextId, {String voiceId = 'default', String sourceLang = 'EN', String targetLang = 'TR'}) async {
    final resp = await _network.get('/api/ApiReadingTexts/$readingTextId/manifest', queryParameters: {
      'voiceId': voiceId,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
    });
    if (resp.statusCode == 200 && resp.data is Map<String, dynamic>) {
      final map = resp.data as Map<String, dynamic>;
      final data = map['data'];
      if (data is List) {
        return List<Map<String, dynamic>>.from(data);
      }
    }
    return const [];
  }

  Future<String> translateSentence(
    String sentence, {
    String sourceLang = 'EN',
    String targetLang = 'TR',
  }) async {
    final resp = await _network.post(
      '/api/ApiReadingTexts/translate-sentence',
      data: {
        'sentence': sentence,
        'sourceLang': sourceLang,
        'targetLang': targetLang,
      },
    );

    if (resp.statusCode == 200 && resp.data != null) {
      final data = resp.data as Map<String, dynamic>;
      final success = data['success'] == true;
      if (success) {
        return (data['translation'] as String?) ?? '';
      }
    }
    return '';
  }

  Future<String> translateWord(String word) async {
    try {
      print('🌐 [TranslationService] Translating word: "$word"');
      final resp = await _network.get(
        '/api/ApiReadingTexts/TranslateWord',
        queryParameters: {
          'vocabulary': word.toLowerCase(),
        },
      );

      print('🌐 [TranslationService] Response status: ${resp.statusCode}');
      print('🌐 [TranslationService] Response data: ${resp.data}');

      if (resp.statusCode == 200 && resp.data != null) {
        final data = resp.data as Map<String, dynamic>;
        final success = data['success'] == true;
        if (success) {
          // Backend response format: { success: true, data: { original: "...", translated: "..." } }
          final responseData = data['data'] as Map<String, dynamic>?;
          final translation = responseData?['translated'] as String? ?? '';
          print('🌐 [TranslationService] Translation result: "$translation"');
          return translation;
        } else {
          print('🌐 [TranslationService] API returned success=false');
        }
      }
    } catch (e) {
      print('❌ [TranslationService] Word translation error: $e');
    }
    return '';
  }
}

