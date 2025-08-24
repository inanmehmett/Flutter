import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/di/injection.dart';
import '../bloc/advanced_reader_bloc.dart';
import '../bloc/reader_event.dart';
import '../bloc/reader_state.dart';
import '../cubit/reading_quiz_cubit.dart';
import '../../data/models/book_model.dart';
import '../../data/services/reading_quiz_service.dart';
import 'reading_quiz_page.dart';

class AdvancedReaderPage extends StatefulWidget {
  final BookModel book;

  const AdvancedReaderPage({
    super.key,
    required this.book,
  });

  @override
  State<AdvancedReaderPage> createState() => _AdvancedReaderPageState();
}

class _AdvancedReaderPageState extends State<AdvancedReaderPage> {
  late final AdvancedReaderBloc _readerBloc;
  final PageController _pageController = PageController(
    viewportFraction: 1.0,
    keepPage: true,
  );
  Size? _pageSize;
  bool _showSwipeHint = true;
  int? _highlightStart;
  int? _highlightEnd;
  int? _highlightPageIndex;
  Timer? _highlightTimer;
  final Map<int, GlobalKey> _textKeys = {};
  bool _suppressOnPageChanged = false;
  final Map<int, ScrollController> _scrollControllers = {};

  @override
  void initState() {
    super.initState();
    _readerBloc = context.read<AdvancedReaderBloc>();
    _loadBook();
    
    // 3 saniye sonra kaydırma ipucunu gizle
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSwipeHint = false;
        });
      }
    });
  }

  void _loadBook() {
    _readerBloc.add(LoadBook(widget.book.id.toString()));
  }

  // Tema renklerini döndüren yardımcı metodlar
  Color _getThemeBackgroundColor(ThemeManager themeManager) {
    switch (themeManager.currentTheme) {
      case AppTheme.light:
        return Colors.white;
      case AppTheme.dark:
        return const Color(0xFF121212);
      case AppTheme.sepia:
        return const Color(0xFFF5F1E8);
    }
  }

  Color _getThemeTextColor(ThemeManager themeManager) {
    switch (themeManager.currentTheme) {
      case AppTheme.light:
        return Colors.black87;
      case AppTheme.dark:
        return Colors.white;
      case AppTheme.sepia:
        return const Color(0xFF2C1810);
    }
  }

  Color _getThemePrimaryColor(ThemeManager themeManager) {
    switch (themeManager.currentTheme) {
      case AppTheme.light:
        return const Color(0xFFFF9800);
      case AppTheme.dark:
        return const Color(0xFFFF9800);
      case AppTheme.sepia:
        return const Color(0xFFD4B483);
    }
  }

  Color _getThemeSurfaceColor(ThemeManager themeManager) {
    switch (themeManager.currentTheme) {
      case AppTheme.light:
        return Colors.white;
      case AppTheme.dark:
        return const Color(0xFF1E1E1E);
      case AppTheme.sepia:
        return const Color(0xFFF5F1E8);
    }
  }

  Color _getThemeOnSurfaceColor(ThemeManager themeManager) {
    switch (themeManager.currentTheme) {
      case AppTheme.light:
        return Colors.black87;
      case AppTheme.dark:
        return Colors.white;
      case AppTheme.sepia:
        return const Color(0xFF2C1810);
    }
  }

  Color _getThemeOutlineVariantColor(ThemeManager themeManager) {
    switch (themeManager.currentTheme) {
      case AppTheme.light:
        return Colors.grey.shade300;
      case AppTheme.dark:
        return Colors.grey.shade700;
      case AppTheme.sepia:
        return const Color(0xFFD4B483);
    }
  }

  Color _getThemeSurfaceContainerHighestColor(ThemeManager themeManager) {
    switch (themeManager.currentTheme) {
      case AppTheme.light:
        return Colors.grey.shade100;
      case AppTheme.dark:
        return const Color(0xFF2C2C2C);
      case AppTheme.sepia:
        return const Color(0xFFE8E0D0);
    }
  }

  Color _getThemeOnSurfaceVariantColor(ThemeManager themeManager) {
    switch (themeManager.currentTheme) {
      case AppTheme.light:
        return Colors.grey.shade600;
      case AppTheme.dark:
        return Colors.grey.shade400;
      case AppTheme.sepia:
        return const Color(0xFF5D4A3A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Scaffold(
          body: BlocBuilder<AdvancedReaderBloc, ReaderState>(
            builder: (context, state) {
              if (state is ReaderLoading) {
                return _buildLoadingView();
              } else if (state is ReaderError) {
                return _buildErrorView(state.message);
              } else if (state is ReaderLoaded) {
                return _buildReaderView(state);
              } else {
                return _buildInitialView();
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildInitialView() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Kitap yükleniyor...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hata'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Hata: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBook,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderView(ReaderLoaded state) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        // Sync PageView position with bloc-driven page changes (e.g., auto-advance)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_pageController.hasClients) {
            final current = _pageController.page?.round() ?? _pageController.initialPage;
            if (current != state.currentPage) {
              _suppressOnPageChanged = true;
              _animateToPage(state.currentPage);
            }
          }
        });
        // Auto-scroll within the current page to keep the playing sentence visible
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (state is! ReaderLoaded) return;
          if (state.playingSentenceIndex == null) return;
          final pageIndex = state.currentPage;
          final pageContent = _getPageContent(pageIndex);
          if (pageContent.isEmpty) return;
          final range = context.read<AdvancedReaderBloc>()
              .computeLocalRangeForSentence(pageContent, state.playingSentenceIndex!);
          if (range == null) return;
          final start = range[0];
          final textKey = _textKeys[pageIndex];
          final renderBox = textKey?.currentContext?.findRenderObject() as RenderBox?;
          final availableWidth = renderBox?.size.width;
          final controller = _scrollControllers[pageIndex];
          if (availableWidth == null || controller == null || !controller.hasClients) return;

          final style = TextStyle(
            fontSize: state.fontSize,
            height: 1.6,
            letterSpacing: 0.1,
            color: _getThemeTextColor(themeManager),
          );
          final textSpan = TextSpan(text: pageContent, style: style);
          final tp = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
            maxLines: null,
          );
          tp.layout(maxWidth: availableWidth);
          final caretOffset = tp.getOffsetForCaret(TextPosition(offset: start), Rect.zero);
          final target = (caretOffset.dy - 80).clamp(0.0, controller.position.maxScrollExtent);
          controller.animateTo(
            target,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        });
        return Scaffold(
          backgroundColor: _getThemeBackgroundColor(themeManager),
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(state, themeManager),
                _buildProgressBar(state, themeManager),
                Expanded(
                  child: _buildReadingArea(state, themeManager),
                ),
                _buildControls(state, themeManager),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(ReaderLoaded state, ThemeManager themeManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getThemeSurfaceColor(themeManager),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: _getThemeOnSurfaceColor(themeManager),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.book.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getThemeOnSurfaceColor(themeManager),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Sayfa ${state.currentPage + 1} / ${state.totalPages}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getThemeOnSurfaceColor(themeManager).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.tune,
              color: _getThemeOnSurfaceColor(themeManager),
            ),
            onPressed: () => _showSettingsSheet(state, themeManager),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ReaderLoaded state, ThemeManager themeManager) {
    final progress = (state.currentPage + 1) / state.totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: _getThemeSurfaceColor(themeManager),
        valueColor: AlwaysStoppedAnimation<Color>(
          _getThemePrimaryColor(themeManager),
        ),
      ),
    );
  }

  Widget _buildReadingArea(ReaderLoaded state, ThemeManager themeManager) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Update page size for pagination
        final newPageSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (_pageSize != newPageSize) {
          _pageSize = newPageSize;
          // Trigger pagination update with new size
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updatePaginationWithNewSize();
          });
        }

        return Stack(
          children: [
            // Ana sayfa görüntüleme alanı
            PageView.builder(
              controller: _pageController,
              itemCount: state.totalPages,
              // Sayfa geçiş animasyonu
              pageSnapping: true,
              // Kaydırma yönü - sadece yatay
              scrollDirection: Axis.horizontal,
              // Sayfa geçiş animasyon süresi
              padEnds: false,
              // Kaydırma fizikleri
              physics: const BouncingScrollPhysics(parent: PageScrollPhysics()),
              onPageChanged: (index) {
                if (_suppressOnPageChanged) {
                  _suppressOnPageChanged = false;
                  return;
                }
                if (index != state.currentPage) {
                  // Haptic feedback
                  HapticFeedback.lightImpact();
                  _readerBloc.add(GoToPage(index));
                }
              },
              itemBuilder: (context, index) {
                // Get content for this specific page from PageManager
                final pageContent = _getPageContent(index);
                final textKey = _textKeys[index] ??= GlobalKey();
                
                return Hero(
                  tag: 'page_$index',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    color: _getThemeSurfaceColor(themeManager),
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      controller: _scrollControllers.putIfAbsent(index, () => ScrollController()),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sayfa numarası göstergesi
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getThemePrimaryColor(themeManager).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Sayfa ${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getThemePrimaryColor(themeManager),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Sayfa içeriği (dokunulan cümleyi bul)
                           GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapUp: (details) async {
                               HapticFeedback.selectionClick();
                              final textStyle = TextStyle(
                                fontSize: state.fontSize,
                                color: _getThemeTextColor(themeManager),
                                height: 1.6,
                                letterSpacing: 0.1,
                              );
                              // Metin widget'ının gerçek boyutu ve lokal pozisyonu
                              final box = textKey.currentContext?.findRenderObject() as RenderBox?;
                              final maxTextWidth = (box?.size.width ?? (constraints.maxWidth - 40)).clamp(0, double.infinity);
                              final localPos = box != null
                                  ? box.globalToLocal(details.globalPosition)
                                  : details.localPosition;
                               final sentence = _extractSentenceAtOffset(
                                pageContent,
                                textStyle,
                                maxTextWidth.toDouble(),
                                localPos,
                              );

                              if (sentence.isEmpty) return;

                               // Highlight sentence briefly
                               _setTemporaryHighlight(index, pageContent, sentence);

                              // Speak via server audio when available; fallback to local TTS
                              final bloc = context.read<AdvancedReaderBloc>();
                              Logger.debug('Tapped sentence: "$sentence"');
                              final readingTextId = _readerBloc.pageManager.bookId ?? 0;
                              final sentenceIndex = context.read<AdvancedReaderBloc>()
                                  .computeSentenceIndex(sentence, pageContent);
                              String? audioUrl;
                              if (readingTextId > 0) {
                                audioUrl = await bloc.findSentenceAudioUrl(readingTextId, sentenceIndex);
                              }
                              if (audioUrl != null) {
                                Logger.debug('Playing from URL: $audioUrl');
                                await bloc.playSentenceFromUrl(audioUrl);
                              } else {
                                await bloc.speakSentenceWithIndex(sentence, sentenceIndex);
                              }
                              final translation = await bloc.translateSentence(sentence);
                              if (!mounted) return;
                              if (translation.isNotEmpty) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(translation),
                                      duration: const Duration(seconds: 6),
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                              }
                            },
                             child: Container(
                               key: textKey,
                               alignment: Alignment.topLeft,
                               child: _buildRichTextWithHighlight(
                                 pageContent,
                                 TextStyle(
                                   fontSize: state.fontSize,
                                   color: _getThemeTextColor(themeManager),
                                   height: 1.6,
                                   letterSpacing: 0.1,
                                 ),
                                 index,
                                 state,
                               ),
                             ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Kaydırma yönü göstergeleri (sadece ilk ve son sayfalarda)
            if (state.currentPage > 0)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                      child: AnimatedOpacity(
                    opacity: _showSwipeHint ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getThemePrimaryColor(themeManager).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: _getThemeOnSurfaceColor(themeManager),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            
            if (state.currentPage < state.totalPages - 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                      child: AnimatedOpacity(
                    opacity: _showSwipeHint ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getThemePrimaryColor(themeManager).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: _getThemeOnSurfaceColor(themeManager),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Sayfa geçiş ipucu (ilk kullanım için)
            if (_showSwipeHint && state.currentPage == 0)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showSwipeHint ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 500),
                      child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getThemePrimaryColor(themeManager).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Sağa kaydırarak sonraki sayfaya geçin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getPageContent(int pageIndex) {
    // Access the PageManager to get content for the specific page
    final pageManager = _readerBloc.pageManager;
    if (pageIndex < pageManager.attributedPages.length) {
      return pageManager.attributedPages[pageIndex].string;
    }
    return '';
  }

  // Highlight helpers
  void _setTemporaryHighlight(int pageIndex, String fullText, String sentence) {
    final start = fullText.indexOf(sentence);
    if (start < 0) return;
    setState(() {
      _highlightPageIndex = pageIndex;
      _highlightStart = start;
      _highlightEnd = start + sentence.length;
    });
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _highlightPageIndex = null;
        _highlightStart = null;
        _highlightEnd = null;
      });
    });
  }

  Widget _buildRichTextWithHighlight(String text, TextStyle style, int pageIndex, ReaderLoaded state) {
    // If autoplay is running and we have a playing sentence index belonging to this page, compute its local range via bloc
    if (state.playingSentenceIndex != null) {
      final range = context.read<AdvancedReaderBloc>().computeLocalRangeForSentence(text, state.playingSentenceIndex!);
      if (range != null) {
        // If segment-level range is provided by state, prefer it
        final start = state.playingRangeStart ?? range[0];
        final end = state.playingRangeEnd ?? range[1];
        final before = text.substring(0, start);
        final mid = text.substring(start, end);
        final after = text.substring(end);
        return RichText(
          text: TextSpan(
            style: style,
            children: [
              TextSpan(text: before),
              TextSpan(text: mid, style: style.copyWith(backgroundColor: Colors.yellow.withValues(alpha: 0.35))),
              TextSpan(text: after),
            ],
          ),
        );
      }
    }
    if (_highlightPageIndex != pageIndex || _highlightStart == null || _highlightEnd == null) {
      return Text(text, style: style);
    }
    final start = _highlightStart!;
    final end = _highlightEnd!;
    final before = text.substring(0, start);
    final mid = text.substring(start, end);
    final after = text.substring(end);
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          TextSpan(text: before),
          TextSpan(text: mid, style: style.copyWith(backgroundColor: Colors.yellow.withValues(alpha: 0.4))),
          TextSpan(text: after),
        ],
      ),
    );
  }

  void _updatePaginationWithNewSize() {
    // This would trigger pagination update with new page size
    // For now, we'll just log the size change
    if (_pageSize != null) {
      print('📖 [AdvancedReaderPage] Page size updated: $_pageSize');
    }
  }

  Widget _buildControls(ReaderLoaded state, ThemeManager themeManager) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getThemeSurfaceColor(themeManager),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress slider
          Slider(
            value: (state.currentPage + 1) / state.totalPages,
            onChanged: (value) {
              final targetPage = (value * state.totalPages).round() - 1;
              if (targetPage >= 0 && targetPage < state.totalPages) {
                _readerBloc.add(GoToPage(targetPage));
              }
            },
            activeColor: _getThemePrimaryColor(themeManager),
            inactiveColor: _getThemePrimaryColor(themeManager).withValues(alpha: 0.3),
          ),
          
          // Page info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sayfa ${state.currentPage + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getThemeOnSurfaceColor(themeManager),
                  ),
                ),
                Text(
                  '/ ${state.totalPages}',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getThemeOnSurfaceColor(themeManager).withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  '${(((state.currentPage + 1) / state.totalPages) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getThemePrimaryColor(themeManager),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Previous page
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: _goToPreviousPage,
                iconSize: 32,
                color: _getThemeOnSurfaceColor(themeManager),
              ),
              
              // Play/Pause button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getThemePrimaryColor(themeManager),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: IconButton(
                    key: ValueKey(
                      state.isSpeaking ? (state.isPaused ? 'play' : 'pause') : 'play',
                    ),
                    icon: Icon(
                      state.isSpeaking
                          ? (state.isPaused ? Icons.play_arrow : Icons.pause)
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () => _readerBloc.add(TogglePlayPause()),
                    iconSize: 32,
                  ),
                ),
              ),
              
              // Stop button
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () => _readerBloc.add(StopSpeech()),
                iconSize: 32,
                color: _getThemeOnSurfaceColor(themeManager),
              ),
              
              // Next page
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _goToNextPage,
                iconSize: 32,
                color: _getThemeOnSurfaceColor(themeManager),
              ),
            ],
          ),
          
          // Quiz button - Son sayfada görünür
          if (state.currentPage == state.totalPages - 1) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: () => _navigateToQuiz(state),
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Kitap Quiz\'ini Çöz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getThemePrimaryColor(themeManager),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSettingsSheet(ReaderLoaded state, ThemeManager themeManager) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        var currentFont = state.fontSize;
        var currentRate = state.speechRate;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              void setFont(double v) {
                final clamped = v.clamp(12.0, 32.0);
                setSheetState(() => currentFont = clamped);
                _readerBloc.add(UpdateFontSize(clamped));
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _getThemeOutlineVariantColor(themeManager),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const Text(
                    'Konuşma Hızı',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildRateChip(label: 'Yavaş', value: 0.45, current: currentRate, themeManager: themeManager),
                      _buildRateChip(label: 'Normal', value: 0.50, current: currentRate, themeManager: themeManager),
                      _buildRateChip(label: 'Orta-Hızlı', value: 0.65, current: currentRate, themeManager: themeManager),
                      _buildRateChip(label: 'Hızlı', value: 0.80, current: currentRate, themeManager: themeManager),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildThemeSection(themeManager),
                  const SizedBox(height: 16),
                  _buildFontPresetsSection(currentFont, setFont, themeManager),
                  const SizedBox(height: 16),
                  const Text(
                    'Yazı Boyutu',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.text_decrease_rounded),
                        onPressed: () => setFont(currentFont - 1.0),
                        tooltip: 'Azalt',
                      ),
                      Expanded(
                        child: Slider(
                          value: currentFont,
                          min: 12.0,
                          max: 32.0,
                          divisions: 20,
                          onChanged: (v) => setFont(v),
                        ),
                      ),
                      Text('${currentFont.round()}'),
                      IconButton(
                        icon: const Icon(Icons.text_increase_rounded),
                        onPressed: () => setFont(currentFont + 1.0),
                        tooltip: 'Artır',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getThemeSurfaceContainerHighestColor(themeManager),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Önizleme: Reading makes a full man.',
                      style: TextStyle(fontSize: currentFont, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.check),
                      label: const Text('Bitti'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRateChip({
    required String label, 
    required double value, 
    required double current,
    required ThemeManager themeManager,
  }) {
    final bool selected = (current - value).abs() < 0.02;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => _readerBloc.add(UpdateSpeechRate(value)),
      selectedColor: _getThemePrimaryColor(themeManager).withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? _getThemePrimaryColor(themeManager) : _getThemeOnSurfaceColor(themeManager),
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildThemeSection(ThemeManager themeManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tema',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildThemeChip(
                icon: Icons.light_mode,
                label: 'Açık',
                theme: AppTheme.light,
                themeManager: themeManager,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildThemeChip(
                icon: Icons.filter_vintage,
                label: 'Sepia',
                theme: AppTheme.sepia,
                themeManager: themeManager,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildThemeChip(
                icon: Icons.dark_mode,
                label: 'Koyu',
                theme: AppTheme.dark,
                themeManager: themeManager,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeChip({
    required IconData icon,
    required String label,
    required AppTheme theme,
    required ThemeManager themeManager,
  }) {
    final isSelected = themeManager.currentTheme == theme;
    
    return InkWell(
      onTap: () => themeManager.setTheme(theme),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _getThemePrimaryColor(themeManager).withValues(alpha: 0.15)
              : _getThemeSurfaceContainerHighestColor(themeManager),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? _getThemePrimaryColor(themeManager)
                : _getThemeOutlineVariantColor(themeManager),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? _getThemePrimaryColor(themeManager)
                  : _getThemeOnSurfaceColor(themeManager),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? _getThemePrimaryColor(themeManager)
                    : _getThemeOnSurfaceColor(themeManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFontPresetsSection(double currentFont, Function(double) setFont, ThemeManager themeManager) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Yazı Boyutu Önayarları',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildFontPresetChip(
                label: 'Küçük',
                size: 20.0,
                current: currentFont,
                onTap: () => setFont(20.0),
                themeManager: themeManager,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFontPresetChip(
                label: 'Orta',
                size: 24.0,
                current: currentFont,
                onTap: () => setFont(24.0),
                themeManager: themeManager,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFontPresetChip(
                label: 'Büyük',
                size: 28.0,
                current: currentFont,
                onTap: () => setFont(28.0),
                themeManager: themeManager,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFontPresetChip({
    required String label,
    required double size,
    required double current,
    required VoidCallback onTap,
    required ThemeManager themeManager,
  }) {
    final isSelected = (current - size).abs() < 1.0;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _getThemePrimaryColor(themeManager).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getThemePrimaryColor(themeManager),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              'Aa',
              style: TextStyle(
                fontSize: size * 0.6,
                fontWeight: FontWeight.w500,
                color: _getThemeOnSurfaceVariantColor(themeManager),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: _getThemeOnSurfaceVariantColor(themeManager),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sayfa geçiş animasyonu
  void _animateToPage(int pageIndex) {
    _pageController.animateToPage(
      pageIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Sayfa geçiş animasyonu (butonlarla)
  void _goToNextPage() {
    if (mounted) {
      final currentState = _readerBloc.state;
      if (currentState is ReaderLoaded && currentState.currentPage < currentState.totalPages - 1) {
        HapticFeedback.lightImpact();
        _animateToPage(currentState.currentPage + 1);
        _readerBloc.add(NextPage());
      }
    }
  }

  void _goToPreviousPage() {
    if (mounted) {
      final currentState = _readerBloc.state;
      if (currentState is ReaderLoaded && currentState.currentPage > 0) {
        HapticFeedback.lightImpact();
        _animateToPage(currentState.currentPage - 1);
        _readerBloc.add(PreviousPage());
      }
    }
  }

  // Dokunulan pozisyona göre cümleyi çıkar
  String _extractSentenceAtOffset(
    String fullText,
    TextStyle style,
    double maxWidth,
    Offset localPos,
  ) {
    if (fullText.isEmpty || maxWidth <= 0) return '';

    final textSpan = TextSpan(text: fullText, style: style);
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    tp.layout(maxWidth: maxWidth);

    // Paragraph offset: içerik container'ında üstte başlıyor; padding 0 kabul ediyoruz
    final pos = tp.getPositionForOffset(localPos);
    final idx = pos.offset.clamp(0, fullText.length);

    // Basit cümle sınırları: . ! ? ve yeni satır
    final separators = RegExp(r'[.!?]\s|\n');

    // Solda cümle başlangıcını bul
    int start = 0;
    for (int i = idx - 1; i >= 0; i--) {
      final ch = fullText[i];
      if (ch == '.' || ch == '!' || ch == '?' || ch == '\n') {
        start = i + 1;
        break;
      }
    }

    // Sağda cümle sonunu bul
    int end = fullText.length;
    for (int i = idx; i < fullText.length; i++) {
      final ch = fullText[i];
      if (ch == '.' || ch == '!' || ch == '?' || ch == '\n') {
        end = i + 1;
        break;
      }
    }

    final sentence = fullText.substring(start, end).trim();
    return sentence;
  }

  void _navigateToQuiz(ReaderLoaded state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => ReadingQuizCubit(getIt<ReadingQuizService>()),
          child: ReadingQuizPage(
            readingTextId: int.tryParse(state.book.id) ?? 0,
            bookTitle: state.book.title,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
} 