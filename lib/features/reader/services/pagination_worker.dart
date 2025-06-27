import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:isolate';
import 'dart:async';
import 'attributed_string_data.dart';

// MARK: - Background Pagination Worker
class PaginationWorker {
  // MARK: - Properties
  static const int _maxCacheSize = 10;
  static const int _targetWordsPerPage = 250;
  static const int _batchSize = 5;
  
  // MARK: - Enhanced Page Creation
  static Future<AttributedStringData> makePage({
    required String fullText,
    required Range range,
    required TextStyle style,
    required Size size,
  }) async {
    final startTime = DateTime.now();
    
    // Extract text for this page
    final substring = fullText.substring(range.start, range.end);
    
    // Create optimized attributes
    final attributes = _createOptimizedAttributes(style);
    
    // Log performance
    final processingTime = DateTime.now().difference(startTime);
    print("📖[PaginationWorker] Page processed in ${processingTime.inMilliseconds}ms");
    
    return AttributedStringData(
      string: substring,
      style: style,
      attributes: attributes,
    );
  }
  
  // MARK: - Batch Page Creation
  static Future<Map<int, AttributedStringData>> makePagesInBatch({
    required String fullText,
    required List<Range> ranges,
    required TextStyle style,
    required Size size,
  }) async {
    final startTime = DateTime.now();
    final results = <int, AttributedStringData>{};
    
    print("📖[PaginationWorker] Starting batch processing of ${ranges.length} pages");
    
    // Process in chunks to avoid overwhelming the system
    final chunks = _chunked(ranges, _batchSize);
    
    for (int chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
      final chunk = chunks[chunkIndex];
      
      // Process chunk in parallel
      final chunkResults = await Future.wait(
        chunk.asMap().entries.map((entry) async {
          final index = entry.key;
          final range = entry.value;
          final actualIndex = chunkIndex * _batchSize + index;
          
          final pageData = await makePage(
            fullText: fullText,
            range: range,
            style: style,
            size: size,
          );
          
          return MapEntry(actualIndex, pageData);
        }),
      );
      
      results.addEntries(chunkResults);
      
      // Add small delay between chunks to prevent overwhelming
      if (chunkIndex < chunks.length - 1) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    
    final totalTime = DateTime.now().difference(startTime);
    print("📖[PaginationWorker] Batch completed: ${ranges.length} pages in ${totalTime.inMilliseconds}ms");
    
    return results;
  }
  
  // MARK: - Smart Range Computation
  static Future<List<Range>> computeOptimizedPageRanges({
    required String fullText,
    required TextStyle style,
    required Size pageSize,
    int targetWordsPerPage = _targetWordsPerPage,
  }) async {
    final startTime = DateTime.now();
    print("📖[PaginationWorker] Computing optimized page ranges...");
    
    final textLength = fullText.length;
    
    if (pageSize.width <= 0 || pageSize.height <= 0) {
      print("❌[PaginationWorker] Invalid page size: $pageSize");
      return [];
    }
    
    // Extract sentences for better breaking
    final sentences = await _extractSentences(fullText);
    final ranges = <Range>[];
    int currentPosition = 0;
    
    // Estimate characters per page based on font and size
    final estimatedCharsPerPage = _estimateCharactersPerPage(style, pageSize);
    
    while (currentPosition < textLength) {
      final targetEndPosition = (currentPosition + estimatedCharsPerPage).clamp(0, textLength);
      
      // Find the best sentence break near the target position
      final actualEndPosition = _findOptimalBreakPoint(
        sentences: sentences,
        currentPosition: currentPosition,
        targetPosition: targetEndPosition,
        maxPosition: textLength,
      );
      
      if (actualEndPosition > currentPosition) {
        ranges.add(Range(currentPosition, actualEndPosition));
        currentPosition = actualEndPosition;
        
        // Skip whitespace at the beginning of next page
        while (currentPosition < textLength && 
               _isWhitespace(fullText[currentPosition])) {
          currentPosition++;
        }
      } else {
        // Fallback: use fixed chunk size
        final remainingLength = textLength - currentPosition;
        final chunkSize = (estimatedCharsPerPage).clamp(0, remainingLength);
        if (chunkSize > 0) {
          ranges.add(Range(currentPosition, currentPosition + chunkSize));
          currentPosition += chunkSize;
        } else {
          break;
        }
      }
    }
    
    final processingTime = DateTime.now().difference(startTime);
    print("📖[PaginationWorker] Generated ${ranges.length} optimized ranges in ${processingTime.inMilliseconds}ms");
    
    return ranges;
  }
  
  // MARK: - Private Helper Methods
  static Map<String, dynamic> _createOptimizedAttributes(TextStyle style) {
    return {
      'fontSize': style.fontSize ?? 16.0,
      'fontWeight': style.fontWeight?.index ?? FontWeight.normal.index,
      'fontFamily': style.fontFamily,
      'height': style.height ?? 1.6,
      'letterSpacing': style.letterSpacing ?? 0.1,
      'lineSpacing': 6.0,
      'alignment': TextAlign.justify.index,
      'lineBreakMode': TextOverflow.visible.index,
      'paragraphSpacing': 8.0,
    };
  }
  
  static Future<List<Range>> _extractSentences(String text) async {
    // Simple sentence extraction using punctuation
    final sentences = <Range>[];
    int start = 0;
    
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      if (char == '.' || char == '!' || char == '?' || char == '\n') {
        if (i > start) {
          sentences.add(Range(start, i + 1));
        }
        start = i + 1;
      }
    }
    
    // Add remaining text as last sentence
    if (start < text.length) {
      sentences.add(Range(start, text.length));
    }
    
    return sentences;
  }
  
  static int _estimateCharactersPerPage(TextStyle style, Size pageSize) {
    // Rough estimation based on font size and page dimensions
    final averageCharWidth = (style.fontSize ?? 16.0) * 0.6;
    final averageLineHeight = (style.fontSize ?? 16.0) * 1.2;
    
    final charsPerLine = (pageSize.width / averageCharWidth).floor();
    final linesPerPage = (pageSize.height / averageLineHeight).floor();
    
    final estimatedChars = charsPerLine * linesPerPage;
    
    // Add some safety margin (reduce by 20%)
    return (estimatedChars * 0.8).floor();
  }
  
  static int _findOptimalBreakPoint({
    required List<Range> sentences,
    required int currentPosition,
    required int targetPosition,
    required int maxPosition,
  }) {
    // Find the best sentence that ends near our target position
    int bestBreakPoint = targetPosition;
    int minDistance = double.maxFinite.toInt();
    
    for (final sentence in sentences) {
      final sentenceEnd = sentence.end;
      
      // Only consider sentences that end after current position
      if (sentenceEnd <= currentPosition) continue;
      
      // Prefer sentences that end close to target but don't go too far
      final distance = (sentenceEnd - targetPosition).abs();
      final overshoot = (sentenceEnd - targetPosition).clamp(0, double.maxFinite.toInt());
      
      // Penalize overshooting more than undershooting
      final penalty = overshoot > 200 ? overshoot * 2 : distance;
      
      if (penalty < minDistance && sentenceEnd <= maxPosition) {
        minDistance = penalty;
        bestBreakPoint = sentenceEnd;
      }
    }
    
    return bestBreakPoint;
  }
  
  static bool _isWhitespace(String char) {
    return char == ' ' || char == '\n' || char == '\t' || char == '\r';
  }
  
  static List<List<T>> _chunked<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return chunks;
  }
} 