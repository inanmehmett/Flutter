import 'package:flutter/material.dart';
import 'attributed_string_data.dart';

// MARK: - Enhanced Simple Page Cache
class SimplePageCache {
  final Map<int, AttributedStringData> _cache = <int, AttributedStringData>{};
  final int _maxCapacity;
  final List<int> _accessOrder = [];
  
  // Performance tracking
  int _hitCount = 0;
  int _missCount = 0;
  final Map<int, DateTime> _lastAccessTimes = {};
  
  SimplePageCache({
    int capacity = 15,
    int maxMemoryMB = 25,
  }) : _maxCapacity = capacity;
  
  AttributedStringData? get(int key) {
    if (_cache.containsKey(key)) {
      // Move to end (most recently used)
      _accessOrder.remove(key);
      _accessOrder.add(key);
      _lastAccessTimes[key] = DateTime.now();
      _hitCount++;
      return _cache[key];
    }
    _missCount++;
    return null;
  }
  
  void set(int key, AttributedStringData value) {
    // Remove if exists
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    }
    
    // Add new
    _cache[key] = value;
    _accessOrder.add(key);
    _lastAccessTimes[key] = DateTime.now();
    
    // Evict if over capacity
    while (_accessOrder.length > _maxCapacity) {
      final oldestKey = _accessOrder.removeAt(0);
      _cache.remove(oldestKey);
      _lastAccessTimes.remove(oldestKey);
    }
  }
  
  void remove(int key) {
    _cache.remove(key);
    _accessOrder.remove(key);
    _lastAccessTimes.remove(key);
  }
  
  void clear() {
    _cache.clear();
    _accessOrder.clear();
    _lastAccessTimes.clear();
    _hitCount = 0;
    _missCount = 0;
  }
  
  void clearNonEssential(Set<int> essentialKeys) {
    final keysToRemove = _cache.keys.where((key) => !essentialKeys.contains(key)).toList();
    for (final key in keysToRemove) {
      remove(key);
    }
  }
  
  Map<String, dynamic> getStats() {
    final totalRequests = _hitCount + _missCount;
    final hitRate = totalRequests > 0 ? _hitCount / totalRequests : 0.0;
    
    return {
      'capacity': _maxCapacity,
      'currentSize': _cache.length,
      'hitCount': _hitCount,
      'missCount': _missCount,
      'hitRate': '${(hitRate * 100).toStringAsFixed(1)}%',
      'memoryUsageMB': 0.0,
    };
  }
  
  double get memoryUsageMB => 0.0;
  
  bool containsKey(int key) => _cache.containsKey(key);
  
  int get size => _cache.length;
  
  bool get isEmpty => _cache.isEmpty;
  
  bool get isNotEmpty => _cache.isNotEmpty;
  
  Iterable<int> get keys => _cache.keys;
  
  Iterable<AttributedStringData> get values => _cache.values;
} 