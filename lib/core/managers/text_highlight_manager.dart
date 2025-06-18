import 'package:flutter/foundation.dart';

class TextHighlightManager extends ChangeNotifier {
  final String text;
  final List<String> _highlightedWords = [];
  final Map<String, String> _translations = {};

  TextHighlightManager({required this.text});

  List<String> get highlightedWords => _highlightedWords;
  Map<String, String> get translations => _translations;

  void highlightWord(String word) {
    if (!_highlightedWords.contains(word)) {
      _highlightedWords.add(word);
      notifyListeners();
    }
  }

  void removeHighlight(String word) {
    _highlightedWords.remove(word);
    _translations.remove(word);
    notifyListeners();
  }

  void addTranslation(String word, String translation) {
    _translations[word] = translation;
    notifyListeners();
  }

  void clearHighlights() {
    _highlightedWords.clear();
    _translations.clear();
    notifyListeners();
  }

  bool isHighlighted(String word) {
    return _highlightedWords.contains(word);
  }

  String? getTranslation(String word) {
    return _translations[word];
  }
}
