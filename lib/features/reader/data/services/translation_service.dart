import 'package:injectable/injectable.dart';
import '../../../../core/network/network_manager.dart';

@lazySingleton
class TranslationService {
  final NetworkManager _network;

  TranslationService(this._network);

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

