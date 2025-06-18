import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontType {
  systemRegular,
  systemBold,
  serif,
  monospace,
}

extension FontTypeExtension on FontType {
  String get fontName {
    switch (this) {
      case FontType.systemRegular:
        return 'Roboto';
      case FontType.systemBold:
        return 'Roboto';
      case FontType.serif:
        return 'Merriweather';
      case FontType.monospace:
        return 'FiraMono';
    }
  }

  FontWeight get fontWeight {
    switch (this) {
      case FontType.systemBold:
        return FontWeight.bold;
      default:
        return FontWeight.normal;
    }
  }

  String get displayName {
    switch (this) {
      case FontType.systemRegular:
        return 'System Regular';
      case FontType.systemBold:
        return 'System Bold';
      case FontType.serif:
        return 'Serif';
      case FontType.monospace:
        return 'Monospace';
    }
  }

  String get rawValue => toString().split('.').last;

  static FontType? fromRawValue(String raw) {
    return FontType.values.firstWhere(
      (e) => e.rawValue == raw,
      orElse: () => FontType.systemRegular,
    );
  }
}

class FontManager extends ChangeNotifier {
  static const double defaultSystemFontSize = 17;
  static const double minimumFontSize = 12;
  static const double maximumFontSize = 48;

  double _currentFontSize = defaultSystemFontSize;
  FontType _currentFontType = FontType.systemRegular;
  double _lineSpacing = 1.2;

  double get currentFontSize => _currentFontSize;
  FontType get currentFontType => _currentFontType;
  double get lineSpacing => _lineSpacing;

  static const _fontSizeKey = 'reader_font_size';
  static const _fontTypeKey = 'reader_font_type';
  static const _lineSpacingKey = 'reader_line_spacing';

  FontManager() {
    _loadPreferences();
  }

  void increaseFontSize() {
    _currentFontSize =
        (_currentFontSize + 2).clamp(minimumFontSize, maximumFontSize);
    notifyListeners();
    _savePreferences();
  }

  void decreaseFontSize() {
    _currentFontSize =
        (_currentFontSize - 2).clamp(minimumFontSize, maximumFontSize);
    notifyListeners();
    _savePreferences();
  }

  void resetFontSize() {
    _currentFontSize = defaultSystemFontSize;
    notifyListeners();
    _savePreferences();
  }

  set currentFontSize(double value) {
    _currentFontSize = value.clamp(minimumFontSize, maximumFontSize);
    notifyListeners();
    _savePreferences();
  }

  set currentFontType(FontType value) {
    _currentFontType = value;
    notifyListeners();
    _savePreferences();
  }

  set lineSpacing(double value) {
    _lineSpacing = value;
    notifyListeners();
    _savePreferences();
  }

  TextStyle get textStyle => TextStyle(
        fontSize: _currentFontSize,
        fontFamily: _currentFontType.fontName,
        fontWeight: _currentFontType.fontWeight,
        height: _lineSpacing,
      );

  void _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble(_fontSizeKey, _currentFontSize);
    prefs.setString(_fontTypeKey, _currentFontType.rawValue);
    prefs.setDouble(_lineSpacingKey, _lineSpacing);
  }

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _currentFontSize = prefs.getDouble(_fontSizeKey) ?? defaultSystemFontSize;
    _currentFontType =
        FontTypeExtension.fromRawValue(prefs.getString(_fontTypeKey) ?? '') ??
            FontType.systemRegular;
    _lineSpacing = prefs.getDouble(_lineSpacingKey) ?? 1.2;
    notifyListeners();
  }
}
