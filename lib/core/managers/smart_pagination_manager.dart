import 'package:flutter/material.dart';
import '../../features/reader/domain/entities/book.dart';

class SmartPaginationManager extends ChangeNotifier {
  final Book book;
  final double pageWidth;
  final double pageHeight;
  final TextStyle textStyle;
  final double lineHeight;
  final double paragraphSpacing;
  final double margin;

  final List<String> _pages = [];
  int _currentPage = 0;

  SmartPaginationManager({
    required this.book,
    required this.pageWidth,
    required this.pageHeight,
    required this.textStyle,
    this.lineHeight = 1.5,
    this.paragraphSpacing = 16.0,
    this.margin = 16.0,
  }) {
    _paginate();
  }

  List<String> get pages => _pages;
  int get currentPage => _currentPage;
  int get totalPages => _pages.length;

  void _paginate() {
    final text = book.content;
    final words = text.split(' ');
    final List<String> currentPageWords = [];
    String currentPage = '';

    for (final word in words) {
      final testPage = currentPage.isEmpty ? word : '$currentPage $word';
      final textSpan = TextSpan(
        text: testPage,
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: null,
      );

      textPainter.layout(
        maxWidth: pageWidth - (2 * margin),
      );

      if (textPainter.height <= pageHeight - (2 * margin)) {
        currentPage = testPage;
      } else {
        _pages.add(currentPage);
        currentPage = word;
      }
    }

    if (currentPage.isNotEmpty) {
      _pages.add(currentPage);
    }
  }

  void nextPage() {
    if (_currentPage < _pages.length - 1) {
      _currentPage++;
      notifyListeners();
    }
  }

  void previousPage() {
    if (_currentPage > 0) {
      _currentPage--;
      notifyListeners();
    }
  }

  void goToPage(int page) {
    if (page >= 0 && page < _pages.length) {
      _currentPage = page;
      notifyListeners();
    }
  }

  String getCurrentPageContent() {
    return _pages[_currentPage];
  }
}
