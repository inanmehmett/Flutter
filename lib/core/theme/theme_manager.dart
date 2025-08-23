import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'font_type.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;

  SharedPreferences? _prefs;
  AppTheme _currentTheme = AppTheme.light; // Default value
  double _fontSize = 17.0; // Default value
  FontType _fontType = FontType.systemRegular; // Default value
  bool _isInitialized = false;

  AppTheme get currentTheme => _currentTheme;
  double get fontSize => _fontSize;
  FontType get fontType => _fontType;
  bool get isInitialized => _isInitialized;

  ThemeManager._internal();

  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _currentTheme = AppTheme.values[_prefs?.getInt('currentTheme') ?? 0];
      _fontSize = _prefs?.getDouble('fontSize') ?? 17.0;
      _fontType = FontType.values[_prefs?.getInt('fontType') ?? 0];
      _isInitialized = true;
    } catch (e) {
      // If initialization fails, keep default values
      _currentTheme = AppTheme.light;
      _fontSize = 17.0;
      _fontType = FontType.systemRegular;
      _isInitialized = true;
    }
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    await _prefs?.setInt('currentTheme', theme.index);
    notifyListeners();
  }

  Future<void> setFontSize(double size) async {
    _fontSize = size;
    await _prefs?.setDouble('fontSize', size);
    notifyListeners();
  }

  Future<void> setFontType(FontType type) async {
    _fontType = type;
    await _prefs?.setInt('fontType', type.index);
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
