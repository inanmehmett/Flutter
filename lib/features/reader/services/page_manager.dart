import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'pagination_worker.dart';
import 'page_cache.dart';
import 'attributed_string_data.dart';

// MARK: - PageManager
class PageManager extends ChangeNotifier {
  // MARK: - Published Properties
  List<AttributedStringData> _attributedPages = [];
  bool _isLoadingPages = false;
  bool _isInitialized = false;
  int _totalPages = 0;
  int _currentPageIndex = 0;
  
  List<AttributedStringData> get attributedPages => _attributedPages;
  bool get isLoadingPages => _isLoadingPages;
  bool get isInitialized => _isInitialized;
  int get totalPages => _totalPages;
  int get currentPageIndex => _currentPageIndex;
  int? get bookId => _currentBookId;
  
  set currentPageIndex(int value) {
    if (value >= 0 && value < _totalPages && value != _currentPageIndex) {
      _currentPageIndex = value;
      _handlePageChange();
      onPageChanged?.call(_currentPageIndex);
      notifyListeners();
    }
  }
  
  // MARK: - Private Properties
  String _text = "";
  TextStyle _style = const TextStyle(fontSize: 16);
  Size _pageSize = Size.zero;
  List<Range> _pageRanges = [];
  int? _currentBookId;
  Timer? _memoryPressureTimer;
  Timer? _backgroundPaginationTimer;
  
  // MARK: - Enhanced Memory Management
  final SimplePageCache _pageCache = SimplePageCache(capacity: 15, maxMemoryMB: 25);
  final Map<int, Future<void>> _pageLoadTasks = {};
  Future<void>? _backgroundPaginationTask;
  
  // MARK: - Constants - Optimized for Memory
  static const int _preloadDistance = 2;
  static const int _maxConcurrentLoads = 3;
  static const int _pagesToKeepAroundCurrentOnMemoryWarning = 2;
  static const Duration _memoryCheckInterval = Duration(seconds: 30);
  static const int _maxMemoryUsageMB = 50;
  static const int _backgroundBatchSize = 10;
  
  // MARK: - Callbacks
  Function(int)? onPageChanged;
  
  // MARK: - Initialization
  PageManager() {
    _setupMemoryManagement();
  }
  
  @override
  void dispose() {
    _cleanupResources();
    super.dispose();
  }
  
  // MARK: - Setup Methods
  void _setupMemoryManagement() {
    _memoryPressureTimer = Timer.periodic(_memoryCheckInterval, (_) {
      _performMemoryMaintenance();
    });
  }
  
  void _cleanupResources() {
    _memoryPressureTimer?.cancel();
    _backgroundPaginationTimer?.cancel();
    _pageLoadTasks.values.forEach((task) => task);
    _backgroundPaginationTask = null;
    _pageCache.clear();
  }
  
  // MARK: - Enhanced Public Methods
  Future<void> paginateText({
    required String text,
    required TextStyle style,
    required Size size,
  }) async {
    if (size.width <= 0 || size.height <= 0) return;
    
    await _resetState();
    _text = text;
    _style = style;
    _pageSize = size;
    
    // Use enhanced background pagination
    final ranges = await PaginationWorker.computeOptimizedPageRanges(
      fullText: text,
      style: style,
      pageSize: size,
      targetWordsPerPage: 300,
    );
    
    if (ranges.isEmpty) return;
    
    _pageRanges = ranges;
    _totalPages = ranges.length;
    _currentPageIndex = 0;
    _isInitialized = true;
    _attributedPages = [];
    
    // Load first page immediately
    await _loadPage(0);
    
    // Start background pagination for next pages
    await _startBackgroundPagination(0);
    
    _isLoadingPages = false;
    notifyListeners();
    
    _logDebug("Pagination completed: ${ranges.length} pages, background processing started");
  }
  
  // MARK: - Background pagination method
  Future<void> _startBackgroundPagination(int centerIndex) async {
    // Cancel any existing background task
    _backgroundPaginationTask = null;
    
    final start = (centerIndex - _preloadDistance).clamp(0, _totalPages - 1);
    final end = (centerIndex + _backgroundBatchSize).clamp(0, _totalPages - 1);
    
    final rangesToProcess = <int>[];
    for (int i = start; i <= end; i++) {
      if (!_pageCache.containsKey(i) && i != centerIndex) {
        rangesToProcess.add(i);
      }
    }
    
    if (rangesToProcess.isEmpty) return;
    
    _logDebug("Starting background pagination for ${rangesToProcess.length} pages");
    
    _backgroundPaginationTask = Future(() async {
      final ranges = rangesToProcess.map((index) => _pageRanges[index]).toList();
      
      final batchResults = await PaginationWorker.makePagesInBatch(
        fullText: _text,
        ranges: ranges.cast<Range>(),
        style: _style,
        size: _pageSize,
      );
      
      // Cache results
      for (final entry in batchResults.entries) {
        final actualPageIndex = rangesToProcess[entry.key];
        _pageCache.set(actualPageIndex, entry.value);
      }
      
      _logDebug("Background pagination completed: ${batchResults.length} pages cached");
    });
    
    await _backgroundPaginationTask;
  }
  
  // MARK: - Enhanced Page Loading
  Future<void> _loadPage(int index) async {
    if (!_isValidPageIndex(index)) return;
    
    final startTime = DateTime.now();
    
    // Check cache first (this should be very fast)
    final cachedPage = _pageCache.get(index);
    if (cachedPage != null) {
      _updateAttributedPagesArray(pageIndex: index, page: cachedPage);
      final loadTime = DateTime.now().difference(startTime);
      _logDebug("Page $index loaded from cache in ${loadTime.inMilliseconds}ms");
      return;
    }
    
    // Create page if not cached
    final pageContent = await _createPage(index);
    
    // Cache the page
    _pageCache.set(index, pageContent);
    
    _updateAttributedPagesArray(pageIndex: index, page: pageContent);
    
    final loadTime = DateTime.now().difference(startTime);
    _logDebug("Page $index created and loaded in ${loadTime.inMilliseconds}ms");
  }
  
  // MARK: - Memory Management Methods
  void _performEmergencyMemoryCleanup() {
    _logDebug("Emergency memory cleanup triggered");
    
    final essentialPages = {
      _currentPageIndex,
      (_currentPageIndex - 1).clamp(0, _totalPages - 1),
      (_currentPageIndex + 1).clamp(0, _totalPages - 1),
    };
    
    _pageCache.clearNonEssential(essentialPages);
    
    final tasksToCancel = _pageLoadTasks.keys.where((key) => !essentialPages.contains(key)).toList();
    for (final key in tasksToCancel) {
      _pageLoadTasks.remove(key);
    }
    
    _rebuildAttributedPagesFromCache();
    
    _logDebug("Emergency cleanup completed. Cache stats: ${_pageCache.getStats()}");
  }
  
  void _performMemoryMaintenance() {
    final memoryUsage = _pageCache.memoryUsageMB;
    
    if (memoryUsage > _maxMemoryUsageMB) {
      _logDebug("Memory usage high: ${memoryUsage.toStringAsFixed(1)}MB. Performing maintenance.");
      
      final essentialPages = {
        _currentPageIndex,
        (_currentPageIndex - 1).clamp(0, _totalPages - 1),
        (_currentPageIndex + 1).clamp(0, _totalPages - 1),
      };
      
      _pageCache.clearNonEssential(essentialPages);
    }
    
    if (kDebugMode) {
      final stats = _pageCache.getStats();
      print("📚[PageManager] Memory maintenance: $stats");
    }
  }
  
  void _rebuildAttributedPagesFromCache() {
    _attributedPages.clear();
    
    for (int i = 0; i < _totalPages; i++) {
      final cachedPage = _pageCache.get(i);
      if (cachedPage != null) {
        _updateAttributedPagesArray(pageIndex: i, page: cachedPage);
      }
    }
  }
  
  void _updateAttributedPagesArray({required int pageIndex, required AttributedStringData page}) {
    while (_attributedPages.length <= pageIndex) {
      _attributedPages.add(AttributedStringData(string: '', style: _style));
    }
    _attributedPages[pageIndex] = page;
    notifyListeners();
  }
  
  Future<void> _resetState() async {
    _pageLoadTasks.values.forEach((task) => task);
    _pageLoadTasks.clear();
    _backgroundPaginationTask = null;
    _pageCache.clear();
    
    _isLoadingPages = true;
    _isInitialized = false;
    _attributedPages.clear();
    _pageRanges.clear();
    _totalPages = 0;
    _currentPageIndex = 0;
    notifyListeners();
  }
  
  Future<void> _preloadAdjacentPages({required int centerIndex}) async {
    final start = (centerIndex - _preloadDistance).clamp(0, _totalPages - 1);
    final end = (centerIndex + _preloadDistance).clamp(0, _totalPages - 1);
    
    final tasksToRun = <Future<void>>[];
    
    for (int pageIndex = start; pageIndex <= end; pageIndex++) {
      if (!_pageCache.containsKey(pageIndex)) {
        tasksToRun.add(_loadPage(pageIndex));
      }
    }
    
    if (tasksToRun.isNotEmpty) {
      await Future.wait(tasksToRun);
    }
  }
  
  bool _isValidPageIndex(int index) {
    if (!_isInitialized) return false;
    return index >= 0 && index < _totalPages;
  }
  
  Future<AttributedStringData> _createPage(int index) async {
    if (index >= _pageRanges.length) {
      return AttributedStringData(string: '', style: _style);
    }
    
    return await PaginationWorker.makePage(
      fullText: _text,
      range: _pageRanges[index],
      style: _style,
      size: _pageSize,
    );
  }
  
  void _handlePageChange() {
    final startTime = DateTime.now();
    
    if (_currentPageIndex < _attributedPages.length && _attributedPages[_currentPageIndex].string.isEmpty) {
      _logDebug("Current page $_currentPageIndex is empty, force loading.");
      _loadPage(_currentPageIndex);
    } else if (_currentPageIndex >= _attributedPages.length) {
      _logDebug("Current page $_currentPageIndex index out of bounds for attributedPages, force loading.");
      _loadPage(_currentPageIndex);
    }
    
    _preloadAdjacentPages(centerIndex: _currentPageIndex);
    _startBackgroundPagination(_currentPageIndex);
    
    final handleTime = DateTime.now().difference(startTime);
    _logDebug("Page change to $_currentPageIndex handled in ${handleTime.inMilliseconds}ms");
  }
  
  void _logDebug(String message) {
    print("📖[PageManager] $message");
  }
  
  // MARK: - Public Navigation Methods
  Future<void> nextPage() async {
    final newIndex = _currentPageIndex + 1;
    if (newIndex >= _totalPages) return;
    
    if (newIndex >= _attributedPages.length || _attributedPages[newIndex].string.isEmpty) {
      await _loadPage(newIndex);
    }
    
    currentPageIndex = newIndex;
  }
  
  Future<void> previousPage() async {
    final newIndex = _currentPageIndex - 1;
    if (newIndex < 0) return;
    
    if (newIndex >= _attributedPages.length || _attributedPages[newIndex].string.isEmpty) {
      await _loadPage(newIndex);
    }
    
    currentPageIndex = newIndex;
  }
  
  Future<void> goToPage(int pageIndex) async {
    if (!_isValidPageIndex(pageIndex)) return;
    
    if (pageIndex >= _attributedPages.length || _attributedPages[pageIndex].string.isEmpty) {
      await _loadPage(pageIndex);
    }
    
    currentPageIndex = pageIndex;
  }
  
  // MARK: - Enhanced Debug Methods
  Map<String, dynamic> getMemoryStats() {
    final cacheStats = _pageCache.getStats();
    return {
      'cacheStats': cacheStats,
      'backgroundTaskActive': _backgroundPaginationTask != null,
      'totalPages': _totalPages,
      'currentPage': _currentPageIndex,
      'loadedPages': _attributedPages.length,
    };
  }
  
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'memoryUsage': _pageCache.memoryUsageMB,
      'cacheHitRate': 'From cache stats',
      'backgroundProcessingActive': _backgroundPaginationTask != null,
    };
  }
  
  // MARK: - Book Configuration
  void configureBook(int id) {
    _currentBookId = id;
    _logDebug("Configured book $id. Current page: $_currentPageIndex, Total pages: $_totalPages");
  }
  
  // MARK: - Cache Management
  void clearCache() {
    _pageCache.clear();
  }
  
  void clearHighlighting() {
    // Implementation for text highlighting would go here
    notifyListeners();
  }
} 