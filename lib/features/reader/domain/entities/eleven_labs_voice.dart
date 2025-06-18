class ElevenLabsVoice {
  final String voiceId;
  final String name;
  final String? previewUrl;
  final String? category;

  ElevenLabsVoice({
    required this.voiceId,
    required this.name,
    this.previewUrl,
    this.category,
  });

  factory ElevenLabsVoice.fromJson(Map<String, dynamic> json) {
    return ElevenLabsVoice(
      voiceId: json['voice_id'] as String,
      name: json['name'] as String,
      previewUrl: json['preview_url'] as String?,
      category: json['category'] as String?,
    );
  }
}

class ElevenLabsVoicesResponse {
  final List<ElevenLabsVoice> voices;
  ElevenLabsVoicesResponse({required this.voices});

  factory ElevenLabsVoicesResponse.fromJson(Map<String, dynamic> json) {
    return ElevenLabsVoicesResponse(
      voices: (json['voices'] as List<dynamic>?)
              ?.map((v) => ElevenLabsVoice.fromJson(v))
              .toList() ??
          [],
    );
  }
}
