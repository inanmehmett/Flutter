/// JSON parsing utilities with case-insensitive support
/// 
/// This helps handle backend responses that might use different casing
/// (camelCase, PascalCase, snake_case) and provides safe fallbacks.

extension SafeMapAccess on Map<String, dynamic> {
  /// Get value with case-insensitive key matching
  /// 
  /// Tries exact match first, then case-insensitive search
  /// 
  /// Example:
  /// ```dart
  /// final map = {'ReviewCount': 5, 'userName': 'John'};
  /// map.getIgnoreCase<int>('reviewCount'); // Returns 5
  /// map.getIgnoreCase<String>('username'); // Returns 'John'
  /// ```
  T? getIgnoreCase<T>(String key) {
    // Try exact match first (fastest path)
    if (containsKey(key)) {
      final value = this[key];
      if (value == null) return null;
      if (value is T) return value;
      // Try to cast
      try {
        return value as T;
      } catch (_) {
        return null;
      }
    }
    
    // Try case-insensitive match
    final lowerKey = key.toLowerCase();
    for (var entry in entries) {
      if (entry.key.toLowerCase() == lowerKey) {
        final value = entry.value;
        if (value == null) return null;
        if (value is T) return value;
        // Try to cast
        try {
          return value as T;
        } catch (_) {
          return null;
        }
      }
    }
    
    return null;
  }
  
  /// Get int value with case-insensitive key matching
  /// Returns defaultValue if not found or cannot be converted
  int getInt(String key, {int defaultValue = 0}) {
    final value = getIgnoreCase<num>(key);
    return value?.toInt() ?? defaultValue;
  }
  
  /// Get double value with case-insensitive key matching
  /// Returns defaultValue if not found or cannot be converted
  double getDouble(String key, {double defaultValue = 0.0}) {
    final value = getIgnoreCase<num>(key);
    return value?.toDouble() ?? defaultValue;
  }
  
  /// Get string value with case-insensitive key matching
  /// Returns defaultValue if not found
  String getString(String key, {String defaultValue = ''}) {
    return getIgnoreCase<String>(key) ?? defaultValue;
  }
  
  /// Get bool value with case-insensitive key matching
  /// Returns defaultValue if not found
  bool getBool(String key, {bool defaultValue = false}) {
    return getIgnoreCase<bool>(key) ?? defaultValue;
  }
  
  /// Get DateTime from string with case-insensitive key matching
  /// Returns null if not found or cannot be parsed
  DateTime? getDateTime(String key) {
    final value = getIgnoreCase<String>(key);
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
  
  /// Get list with case-insensitive key matching
  /// Returns empty list if not found
  List<T> getList<T>(String key) {
    final value = getIgnoreCase<List>(key);
    if (value == null) return [];
    try {
      return value.cast<T>();
    } catch (_) {
      return [];
    }
  }
}

