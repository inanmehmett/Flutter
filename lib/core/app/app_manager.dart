import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  // Add your settings fields here
  AppSettings();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // TODO: implement fromJson
    return AppSettings();
  }
  Map<String, dynamic> toJson() => {};
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
