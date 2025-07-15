import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  // Add your settings fields here
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;
  final double fontSize;
  final bool autoPlayAudio;
  
  AppSettings({
    this.isDarkMode = false,
    this.language = 'tr',
    this.notificationsEnabled = true,
    this.fontSize = 16.0,
    this.autoPlayAudio = false,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      isDarkMode: json['isDarkMode'] as bool? ?? false,
      language: json['language'] as String? ?? 'tr',
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
      autoPlayAudio: json['autoPlayAudio'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'isDarkMode': isDarkMode,
    'language': language,
    'notificationsEnabled': notificationsEnabled,
    'fontSize': fontSize,
    'autoPlayAudio': autoPlayAudio,
  };
}

class UserPreferences {
  // Add your preferences fields here
  Map<int, double> readingProgress;
  UserPreferences({this.readingProgress = const {}});

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      readingProgress: (json['readingProgress'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
          ) ??
          {},
    );
  }
  Map<String, dynamic> toJson() => {
        'readingProgress':
            readingProgress.map((k, v) => MapEntry(k.toString(), v)),
      };
}

class AppManager extends ChangeNotifier {
  static final AppManager _instance = AppManager._internal();
  factory AppManager() => _instance;

  static const _settingsKey = 'appSettings';
  static const _preferencesKey = 'userPreferences';

  late AppSettings settings;
  late UserPreferences userPreferences;

  AppManager._internal() {
    settings = AppSettings();
    userPreferences = UserPreferences();
    _loadSettings();
    _loadPreferences();
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_preferencesKey, jsonEncode(userPreferences.toJson()));
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_settingsKey);
    if (data != null) {
      settings = AppSettings.fromJson(jsonDecode(data));
      notifyListeners();
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_preferencesKey);
    if (data != null) {
      userPreferences = UserPreferences.fromJson(jsonDecode(data));
      notifyListeners();
    }
  }
}
