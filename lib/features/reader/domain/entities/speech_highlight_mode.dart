enum SpeechHighlightMode {
  sentence,
  word,
}

extension SpeechHighlightModeExtension on SpeechHighlightMode {
  String get displayName {
    switch (this) {
      case SpeechHighlightMode.sentence:
        return 'Cümle Bazlı';
      case SpeechHighlightMode.word:
        return 'Kelime Bazlı';
    }
  }
}
