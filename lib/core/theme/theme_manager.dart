import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'font_type.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;

  late SharedPreferences _prefs;
  late AppTheme _currentTheme;
  late double _fontSize;
  late FontType _fontType;

  AppTheme get currentTheme => _currentTheme;
  double get fontSize => _fontSize;
  FontType get fontType => _fontType;

  ThemeManager._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentTheme = AppTheme.values[_prefs.getInt('currentTheme') ?? 0];
    _fontSize = _prefs.getDouble('fontSize') ?? 17.0;
    _fontType = FontType.values[_prefs.getInt('fontType') ?? 0];
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _prefs.setInt('currentTheme', theme.index);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await _prefs.setDouble('fontSize', size);
    notifyListeners();
  }

  Future<void> setFontType(FontType type) async {
    _fontType = type;
    await _prefs.setInt('fontType', type.index);
    notifyListeners();
  }

  void toggleTheme() {
    switch (_currentTheme) {
      case AppTheme.light:
        setTheme(AppTheme.sepia);
        break;
      case AppTheme.sepia:
        setTheme(AppTheme.dark);
        break;
      case AppTheme.dark:
        setTheme(AppTheme.light);
        break;
    }
  }

  TextStyle getTextStyle() {
    return TextStyle(
      fontFamily: _fontType.fontName,
      fontSize: _fontSize,
      fontWeight: _fontType.fontWeight,
    );
  }
}
