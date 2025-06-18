import 'dart:convert';
import 'package:dio/dio.dart';
import '../domain/entities/eleven_labs_voice.dart';

class ElevenLabsError implements Exception {
  final String message;
  ElevenLabsError(this.message);
  @override
  String toString() => 'ElevenLabsError: $message';
}

class ElevenLabsService {
  final String apiKey;
  final String baseUrl;
  final Dio _dio;

  ElevenLabsService({
    required this.apiKey,
    this.baseUrl = 'https://api.elevenlabs.io/v1',
    Dio? dio,
  }) : _dio = dio ?? Dio();

  Future<List<ElevenLabsVoice>> getVoices() async {
    final url = '$baseUrl/voices';
    try {
      final response = await _dio.get(
        url,
        options: Options(headers: {'xi-api-key': apiKey}),
      );
      if (response.statusCode == 200) {
        final data =
            response.data is String ? jsonDecode(response.data) : response.data;
        return ElevenLabsVoicesResponse.fromJson(data).voices;
      } else {
        throw ElevenLabsError('Invalid response: ${response.statusCode}');
      }
    } catch (e) {
      throw ElevenLabsError(e.toString());
    }
  }

  Future<List<int>> synthesizeSpeech({
    required String text,
    required String voiceId,
    double stability = 0.5,
    double similarityBoost = 0.75,
  }) async {
    final url = '$baseUrl/text-to-speech/$voiceId';
    try {
      final response = await _dio.post(
        url,
        data: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': stability,
            'similarity_boost': similarityBoost,
          },
        }),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'xi-api-key': apiKey,
          },
          responseType: ResponseType.bytes,
        ),
      );
      if (response.statusCode == 200) {
        return response.data as List<int>;
      } else {
        throw ElevenLabsError('Invalid response: ${response.statusCode}');
      }
    } catch (e) {
      throw ElevenLabsError(e.toString());
    }
  }
}
