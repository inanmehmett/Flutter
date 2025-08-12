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
}

