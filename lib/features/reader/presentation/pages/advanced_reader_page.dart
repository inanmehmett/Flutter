import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/app/app_manager.dart';
import '../bloc/advanced_reader_bloc.dart';
import '../bloc/reader_event.dart';
import '../bloc/reader_state.dart';
import '../cubit/reading_quiz_cubit.dart';
import '../../data/models/book_model.dart';
import '../../data/services/reading_quiz_service.dart';
import 'reading_quiz_page.dart';
import '../../data/phrasal_verbs_tr.dart';
import '../widgets/daily_media_bar.dart';

// Anchor data for tooltip positioning
class TooltipAnchor {
  final bool showAbove;
  final double left;
  final double? top;
  final double? bottom;
  final double notchLeft;

  const TooltipAnchor({
    required this.showAbove,
    required this.left,
    this.top,
    this.bottom,
    required this.notchLeft,
  });
}

class AdvancedReaderPage extends StatefulWidget {
  final BookModel book;

  const AdvancedReaderPage({
    super.key,
    required this.book,
  });

  @override
  State<AdvancedReaderPage> createState() => _AdvancedReaderPageState();
}

class _AdvancedReaderPageState extends State<AdvancedReaderPage> with WidgetsBindingObserver {
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
  
  // Word detection variables
  int? _wordStart;
  int? _wordEnd;
  int? _wordPageIndex;
  String? _selectedWord;
  String? _wordTranslation;
  bool _isLoadingTranslation = false;
  OverlayEntry? _wordOverlay;
  ScrollController? _activeOverlayScrollController;
  VoidCallback? _overlayScrollListener;
  
  // TTS instance
  FlutterTts? _flutterTts;
  
  // Tooltip state
  bool _isTooltipVisible = false;
  Offset? _lastTooltipPosition;

  // Sentence translation premium overlay
  OverlayEntry? _sentenceOverlay;
  Timer? _sentenceOverlayTimer;

  // Local phrasal verb cache
  Map<String, PhrasalVerbEntry>? _phrasalMapCache;
  Map<String, PhrasalVerbEntry> get _phrasalMap {
    if (_phrasalMapCache != null) return _phrasalMapCache!;
    final map = <String, PhrasalVerbEntry>{};
    for (final e in kPhrasalVerbsTr) {
      for (final f in e.forms) {
        map[f] = e;
      }
    }
    _phrasalMapCache = map;
    return map;
  }

  // Quick tokenization (letters/digits/apostrophe/hyphen), returns [start, end, text]
  List<Map<String, dynamic>> _tokenize(String text) {
    final reg = RegExp(r"[A-Za-z0-9'\-]+");
    final tokens = <Map<String, dynamic>>[];
    for (final m in reg.allMatches(text)) {
      tokens.add({
        'start': m.start,
        'end': m.end,
        'text': text.substring(m.start, m.end),
      });
    }
    return tokens;
  }

  // Try to detect a phrasal verb around the given word span. Returns null if none.
  Map<String, dynamic>? _detectLocalPhrasalAt(String fullText, int wordStart, int wordEnd) {
    if (fullText.isEmpty) return null;
    final tokens = _tokenize(fullText);
    if (tokens.isEmpty) return null;
    int i = -1;
    for (int t = 0; t < tokens.length; t++) {
      final s = tokens[t]['start'] as int;
      final e = tokens[t]['end'] as int;
      if (wordStart >= s && wordStart < e) {
        i = t;
        break;
      }
    }
    if (i < 0) return null;

    String formOf(int si, int ei) {
      return List.generate(ei - si + 1, (k) => tokens[si + k]['text']).join(' ').toLowerCase();
    }

    Map<String, dynamic>? makeResult(int si, int ei, PhrasalVerbEntry entry) {
      final start = tokens[si]['start'] as int;
      final end = tokens[ei]['end'] as int;
      final phrase = fullText.substring(start, end);
      return {
        'start': start,
        'end': end,
        'phrase': phrase,
        'entry': entry,
      };
    }

    // 1) Contiguous longest-match first: try trigram then bigram windows including i
    for (final len in [3, 2]) {
      for (int s = i - (len - 1); s <= i; s++) {
        final e = s + len - 1;
        if (s < 0 || e >= tokens.length) continue;
        if (i < s || i > e) continue; // ensure selection inside window
        final cand = formOf(s, e);
        final entry = _phrasalMap[cand];
        if (entry != null) {
          return makeResult(s, e, entry);
        }
      }
    }

    // 2) Simple separable detection: verb token at i, particle within next 3 tokens
    //    Match entries where some form starts with "<verb> ".
    final verbLower = (tokens[i]['text'] as String).toLowerCase();
    for (final entry in kPhrasalVerbsTr.where((e) => e.separable)) {
      final hasVerbFormPrefix = entry.forms.any((f) => f.startsWith('$verbLower '));
      if (!hasVerbFormPrefix) continue;
      final particle = entry.base.split(' ').last.toLowerCase();
      for (int j = i + 1; j <= i + 3 && j < tokens.length; j++) {
        final tj = (tokens[j]['text'] as String).toLowerCase();
        if (tj == particle) {
          return makeResult(i, j, entry);
        }
      }
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _readerBloc = context.read<AdvancedReaderBloc>();
    _loadBook();
    _initializeTts();
    
    // 3 saniye sonra kaydırma ipucunu gizle
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSwipeHint = false;
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Stop any ongoing playback when app goes to background or becomes inactive
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      try { _readerBloc.add(StopSpeech()); } catch (_) {}
    }
  }

  // Backdrop tap: close if tap is far from text content; otherwise retarget to new word
  void _onBackdropTapDown(Offset globalPosition, ThemeManager themeManager) {
    try {
      // If tap is near the reading text area, detect word and open there; else just close
      final int pageIndex = _wordPageIndex ?? (_readerBloc.state is ReaderLoaded ? (_readerBloc.state as ReaderLoaded).currentPage : 0);
      final renderBox = _textKeys[pageIndex]?.currentContext?.findRenderObject() as RenderBox?;
      final pageContent = _getPageContent(pageIndex);
      if (renderBox == null || pageContent.isEmpty) {
        _hideWordOverlay();
        return;
      }
      final local = renderBox.globalToLocal(globalPosition);
      // Quick containment check (a bit generous)
      final rect = Offset.zero & renderBox.size;
      if (!rect.inflate(12).contains(local)) {
        _hideWordOverlay();
        return;
      }

      // Build style from current state
      double fontSize = 20;
      final current = _readerBloc.state;
      if (current is ReaderLoaded) fontSize = current.fontSize;
      final style = TextStyle(
        fontSize: fontSize,
        height: 1.6,
        letterSpacing: 0.1,
        color: _getThemeTextColor(themeManager),
      );

      final wordInfo = _extractWordAtOffset(
        pageContent,
        style,
        renderBox.size.width,
        local,
      );

      if (wordInfo['word'] != null && wordInfo['word'].toString().isNotEmpty) {
        // Try local phrasal detection around the tapped word
        final localHit = _detectLocalPhrasalAt(pageContent, wordInfo['start'], wordInfo['end']);
        final selStart = localHit != null ? localHit['start'] as int : wordInfo['start'] as int;
        final selEnd = localHit != null ? localHit['end'] as int : wordInfo['end'] as int;
        final selText = pageContent.substring(selStart, selEnd);
        setState(() {
          _wordStart = selStart;
          _wordEnd = selEnd;
          _wordPageIndex = pageIndex;
          _selectedWord = selText;
          _isLoadingTranslation = true;
          _wordTranslation = null;
        });
        _showWordOverlay(globalPosition, selText, themeManager);
        if (localHit != null) {
          final entry = localHit['entry'] as PhrasalVerbEntry;
          setState(() {
            _wordTranslation = entry.meaningTr;
            _isLoadingTranslation = false;
          });
          _updateWordOverlay();
        } else {
          _translateWord(selText);
        }
      } else {
        _hideWordOverlay();
      }
    } catch (_) {
      _hideWordOverlay();
    }
  }

  void _loadBook() {
    _readerBloc.add(LoadBook(widget.book.id.toString()));
  }

  // TTS initialize
  void _initializeTts() async {
    _flutterTts = FlutterTts();
    
    await _flutterTts?.setLanguage("en-US");
    await _flutterTts?.setSpeechRate(0.40);
    await _flutterTts?.setVolume(1.0);
    await _flutterTts?.setPitch(1.0);
    
    print('🎤 [TTS] Initialized successfully');
  }

  // Kelime seslendirme
  Future<void> _speakWord(String word) async {
    try {
      print('🎤 [TTS] Speaking word: "$word"');
      await _flutterTts?.speak(word);
    } catch (e) {
      print('🎤 [TTS] Error speaking word: $e');
    }
  }

  // Kelimeyi kelime defterine ekle
  Future<void> _addToVocabulary(String word) async {
    try {
      print('📚 [Vocabulary] Adding word to dictionary: "$word"');
      // TODO: API call to add word to vocabulary
      // Bu API endpoint'i henüz yok, eklenmeli
      
      // Şimdilik sadece log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kelime defterine eklendi: $word'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('📚 [Vocabulary] Error adding word: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kelime eklenirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Kitap yükleniyor...',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hata'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
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
              color: AppColors.error,
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
        return WillPopScope(
          onWillPop: () async {
            return await _handleExitAttemptWithQuiz(state, themeManager);
          },
          child: Scaffold(
          backgroundColor: _getThemeBackgroundColor(themeManager),
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(state, themeManager),
                _buildProgressBar(state, themeManager),
                Expanded(
                  child: _buildReadingArea(state, themeManager),
                ),
                DailyMediaBar(
                  isSpeaking: state.isSpeaking,
                  isPaused: state.isPaused,
                  speechRate: state.speechRate,
                  currentPage: state.currentPage,
                  totalPages: state.totalPages,
                  onPrevPage: _goToPreviousPage,
                  onNextPage: _goToNextPage,
                  onTogglePlayPause: () => _readerBloc.add(TogglePlayPause()),
                  onStop: () {
                    // Full reset on Stop: clear local UI states too
                    try {
                      _highlightTimer?.cancel();
                      _highlightPageIndex = null;
                      _highlightStart = null;
                      _highlightEnd = null;
                      _hideWordOverlay();
                    } catch (_) {}
                    _readerBloc.add(StopSpeech());
                  },
                  onCycleRate: () {
                    final List<double> rates = [0.30, 0.40, 0.50, 0.65];
                    final idx = rates.indexWhere((r) => (r - state.speechRate).abs() < 0.02);
                    final next = rates[(idx < 0 ? 1 : (idx + 1) % rates.length)];
                    _readerBloc.add(UpdateSpeechRate(next));
                  },
                  onScrubToPageFraction: (v) {
                    final target = (v * state.totalPages).clamp(0, state.totalPages.toDouble());
                    final page = target.ceil() - 1;
                    if (page >= 0 && page < state.totalPages) {
                      _readerBloc.add(GoToPage(page));
                    }
                  },
                ),
              ],
            ),
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
            onPressed: () async {
              final shouldExit = await _handleExitAttemptWithQuiz(state, themeManager);
              if (shouldExit && mounted) {
                Navigator.of(context).pop();
              }
            },
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

  Future<bool> _handleExitAttemptWithQuiz(ReaderLoaded state, ThemeManager themeManager) async {
    try { _readerBloc.add(StopSpeech()); } catch (_) {}
    final bool isAtLastPage = state.currentPage >= (state.totalPages - 1);
    if (!isAtLastPage) {
      return true;
    }

    final decision = await _showExitQuizSheet(state, themeManager);
    if (decision == false) {
      // User chose to take the quiz
      _navigateToQuiz(state);
      return false;
    }
    // decision == true => exit, decision == null => stay
    return decision == true;
  }

  Future<bool?> _showExitQuizSheet(ReaderLoaded state, ThemeManager themeManager) async {
    final Color surface = _getThemeSurfaceColor(themeManager);
    final Color onSurface = _getThemeOnSurfaceColor(themeManager);
    final Color onSurfaceMuted = _getThemeOnSurfaceVariantColor(themeManager);
    final Color primary = _getThemePrimaryColor(themeManager);

    return await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primary.withOpacity(0.12), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [primary, primary.withOpacity(0.8)]),
                  ),
                  child: const Icon(Icons.quiz_outlined, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Quiz ile pekiştir',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: onSurface),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Çıkmadan önce 3 soruluk kısa quizi çözelim mi?',
                  style: TextStyle(fontSize: 13, color: onSurfaceMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.bolt),
                    label: const Text("Quiz'i Çöz", style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: onSurfaceMuted.withOpacity(0.4)),
                    ),
                    child: Text('Şimdilik çık', style: TextStyle(color: onSurface)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pill({required IconData icon, required String label, required Color fg, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bg.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
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
                // Stop any ongoing playback on manual page swipe
                try { _readerBloc.add(StopSpeech()); } catch (_) {}
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
                            onLongPressStart: (details) {
                              final textStyle = TextStyle(
                                fontSize: state.fontSize,
                                color: _getThemeTextColor(themeManager),
                                height: 1.6,
                                letterSpacing: 0.1,
                              );
                              _onWordLongPressStart(details, pageContent, constraints, themeManager, textStyle);
                            },
                            onLongPressEnd: (details) => _onWordLongPressEnd(),
                            onPanStart: (details) {
                              // Hareket başladığında tooltip'i kapat
                              if (_isTooltipVisible) {
                                _hideWordOverlay();
                              }
                            },
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
                              final maxTextWidth = (box?.size.width ?? constraints.maxWidth).toDouble();
                              final localPosRaw = box != null
                                  ? box.globalToLocal(details.globalPosition)
                                  : details.localPosition;
                              final scrollOffset = _scrollControllers[index]?.offset ?? 0.0;
                              final localPos = Offset(localPosRaw.dx, localPosRaw.dy + scrollOffset);
                               final sentence = _extractSentenceAtOffset(
                                pageContent,
                                textStyle,
                                maxTextWidth.toDouble(),
                                localPos,
                              );

                              if (sentence.isEmpty) return;

                              // Premium highlight removed: no upsell, optional future gating can be added elsewhere
                              if (AppManager().settings.premiumHighlightEnabled) {
                                _setTemporaryHighlight(index, pageContent, sentence);
                              }

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
                                final globalIndex = bloc.computeSentenceIndex(sentence, pageContent);
                                await bloc.playSentenceFromUrl(audioUrl, sentenceIndex: globalIndex);
                              } else {
                                await bloc.speakSentenceWithIndex(sentence, sentenceIndex);
                              }
                              // Removed premium upsell
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
                                 themeManager,
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

  // ================= PREMIUM TRANSLATION OVERLAY =================
  void _showSentenceOverlayPremium(String original, String translated, ThemeManager themeManager) {
    _hideSentenceOverlay();

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.7);
    final Color border = isDark ? Colors.white.withOpacity(0.14) : Colors.black.withOpacity(0.08);
    final Color textPrimary = _getThemeOnSurfaceColor(themeManager);
    final Color textSecondary = _getThemeOnSurfaceVariantColor(themeManager);

    _sentenceOverlay = OverlayEntry(
      builder: (ctx) {
        final mq = MediaQuery.of(ctx);
        final double horizontal = 16;
        final double maxWidth = mq.size.width - (horizontal * 2);
        return AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 180),
          child: Stack(
            children: [
              // Backdrop tap to dismiss
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _hideSentenceOverlay,
                  child: const SizedBox.shrink(),
                ),
              ),
              // Floating glass card
              Positioned(
                left: horizontal,
                right: horizontal,
                bottom: mq.padding.bottom + 20,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, (1 - value) * 12),
                      child: Transform.scale(
                        scale: 0.98 + value * 0.02,
                        child: child,
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(CupertinoIcons.globe, size: 16, color: textSecondary),
                                const SizedBox(width: 6),
                                Text('Translation', style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _hideSentenceOverlay,
                                  child: Icon(CupertinoIcons.xmark_circle_fill, size: 18, color: textSecondary.withOpacity(0.8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              translated,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              original,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                _iconAction(
                                  icon: CupertinoIcons.speaker_2_fill,
                                  label: 'Listen',
                                  onTap: () => _readerBloc.speakSentenceWithIndex(original, _readerBloc.computeSentenceIndex(original, _getPageContent((_readerBloc.state as ReaderLoaded).currentPage))),
                                  themeManager: themeManager,
                                ),
                                const SizedBox(width: 10),
                                _iconAction(
                                  icon: CupertinoIcons.doc_on_doc,
                                  label: 'Copy',
                                  onTap: () => Clipboard.setData(ClipboardData(text: translated)),
                                  themeManager: themeManager,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    Overlay.of(context).insert(_sentenceOverlay!);

    _sentenceOverlayTimer?.cancel();
    _sentenceOverlayTimer = Timer(const Duration(seconds: 7), _hideSentenceOverlay);
  }

  Widget _iconAction({required IconData icon, required String label, required VoidCallback onTap, required ThemeManager themeManager}) {
    final Color fg = _getThemeOnSurfaceVariantColor(themeManager);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: fg, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _hideSentenceOverlay() {
    _sentenceOverlayTimer?.cancel();
    _sentenceOverlayTimer = null;
    _sentenceOverlay?.remove();
    _sentenceOverlay = null;
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

  Widget _buildRichTextWithHighlight(String text, TextStyle style, int pageIndex, ReaderLoaded state, ThemeManager themeManager) {
    List<TextSpan> spans = [];
    int currentIndex = 0;
    
    // Collect all highlight ranges
    List<Map<String, dynamic>> highlights = [];
    
    // Playing sentence highlight
    if (state.playingSentenceIndex != null) {
      final range = context.read<AdvancedReaderBloc>().computeLocalRangeForSentence(text, state.playingSentenceIndex!);
      if (range != null) {
        final start = state.playingRangeStart ?? range[0];
        final end = state.playingRangeEnd ?? range[1];
        highlights.add({
          'start': start,
          'end': end,
          'color': Colors.yellow.withValues(alpha: 0.35),
          'priority': 1
        });
      }
    }
    
    // Sentence highlight (tap)
    if (_highlightPageIndex == pageIndex && _highlightStart != null && _highlightEnd != null) {
      highlights.add({
        'start': _highlightStart!,
        'end': _highlightEnd!,
        'color': Colors.yellow.withValues(alpha: 0.4),
        'priority': 2
      });
    }
    
    // Word highlight (long press)
    if (_wordPageIndex == pageIndex && _wordStart != null && _wordEnd != null) {
      highlights.add({
        'start': _wordStart!,
        'end': _wordEnd!,
        'color': _getThemePrimaryColor(themeManager).withValues(alpha: 0.3),
        'priority': 3
      });
    }
    
    // Sort highlights by start position
    highlights.sort((a, b) => a['start'].compareTo(b['start']));
    
    // Build text spans
    for (var highlight in highlights) {
      final start = highlight['start'] as int;
      final end = highlight['end'] as int;
      
      // Add text before highlight
      if (start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, start)));
      }
      
      // Add highlighted text
      spans.add(TextSpan(
        text: text.substring(start, end),
        style: style.copyWith(backgroundColor: highlight['color']),
      ));
      
      currentIndex = end;
    }
    
    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }
    
    if (spans.isEmpty) {
      return Text(text, style: style);
    }
    
    return RichText(
      text: TextSpan(style: style, children: spans),
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
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spotify tarzı progress bar
          _buildSpotifyProgressBar(state, themeManager),
          
          const SizedBox(height: 20),
          
          // Spotify tarzı kontrol butonları
          _buildSpotifyControls(state, themeManager),
          
          const SizedBox(height: 20),
          
          // Quiz button - Son sayfada görünür
          if (state.currentPage == state.totalPages - 1) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSpotifyQuizButton(state, themeManager),
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildSpotifyProgressBar(ReaderLoaded state, ThemeManager themeManager) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.black,
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: Colors.black,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
            ),
            child: Slider(
              value: (state.currentPage + 1) / state.totalPages,
              onChanged: (value) {
                final targetPage = (value * state.totalPages).round() - 1;
                if (targetPage >= 0 && targetPage < state.totalPages) {
                  _readerBloc.add(GoToPage(targetPage));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotifyControls(ReaderLoaded state, ThemeManager themeManager) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous page - Spotify tarzı
          _buildSpotifyControlButton(
            icon: Icons.skip_previous,
            onPressed: _goToPreviousPage,
            size: 24,
          ),
          
          // Play/Pause button - Spotify tarzı büyük
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade600,
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: () => _readerBloc.add(TogglePlayPause()),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    state.isSpeaking
                        ? (state.isPaused ? Icons.play_arrow : Icons.pause)
                        : Icons.play_arrow,
                    key: ValueKey(
                      state.isSpeaking ? (state.isPaused ? 'play' : 'pause') : 'play',
                    ),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          
          // Stop button - Spotify tarzı
          _buildSpotifyControlButton(
            icon: Icons.stop,
            onPressed: () => _readerBloc.add(StopSpeech()),
            size: 24,
          ),
          
          // Next page - Spotify tarzı
          _buildSpotifyControlButton(
            icon: Icons.skip_next,
            onPressed: _goToNextPage,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildSpotifyControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade100,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Icon(
            icon,
            color: Colors.grey.shade700,
            size: size,
          ),
        ),
      ),
    );
  }

  Widget _buildSpotifyQuizButton(ReaderLoaded state, ThemeManager themeManager) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => _navigateToQuiz(state),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.quiz_outlined,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Quiz\'i Çöz',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
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
                      _buildRateChip(label: 'Yavaş', value: 0.30, current: currentRate, themeManager: themeManager),
                      _buildRateChip(label: 'Normal', value: 0.40, current: currentRate, themeManager: themeManager),
                      _buildRateChip(label: 'Orta-Hızlı', value: 0.50, current: currentRate, themeManager: themeManager),
                      _buildRateChip(label: 'Hızlı', value: 0.65, current: currentRate, themeManager: themeManager),
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

  // Dokunulan pozisyona göre kelimeyi çıkar
  Map<String, dynamic> _extractWordAtOffset(
    String fullText,
    TextStyle style,
    double maxWidth,
    Offset localPos,
  ) {
    print('🔍 [Extract Word] ===== EXTRACT WORD START =====');
    print('🔍 [Extract Word] Input Local Position: $localPos');
    print('🔍 [Extract Word] Max Width: $maxWidth');
    print('🔍 [Extract Word] Font Size: ${style.fontSize}');
    print('🔍 [Extract Word] Text Length: ${fullText.length}');
    
    if (fullText.isEmpty || maxWidth <= 0) {
      print('🔍 [Extract Word] ❌ Empty text or invalid maxWidth');
      return {'word': '', 'start': 0, 'end': 0};
    }

    final textSpan = TextSpan(text: fullText, style: style);
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    tp.layout(maxWidth: maxWidth);
    
    print('🔍 [Extract Word] TextPainter Size: ${tp.size}');
    print('🔍 [Extract Word] TextPainter Line Count: ${tp.computeLineMetrics().length}');

    // Pozisyonu daha hassas hesapla
    final pos = tp.getPositionForOffset(localPos);
    int idx = pos.offset.clamp(0, fullText.length - 1);
    
    print('🔍 [Extract Word] TextPainter Position: $pos');
    print('🔍 [Extract Word] Character Index: $idx');
    print('🔍 [Extract Word] Character at Index: "${idx < fullText.length ? fullText[idx] : 'EOF'}"');
    
    // Çevredeki karakterleri göster
    final contextStart = (idx - 10).clamp(0, fullText.length);
    final contextEnd = (idx + 10).clamp(0, fullText.length);
    print('🔍 [Extract Word] Context: "${fullText.substring(contextStart, contextEnd)}"');
    print('🔍 [Extract Word] Context Index: $contextStart-$contextEnd, Target: $idx');

    // Kelime karakter tanımı: harf/rakam, apostrof (' veya ’) ve tire (-)
    bool isWordChar(String ch) {
      if (ch.isEmpty) return false;
      final code = ch.codeUnitAt(0);
      final isAsciiLetter = (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
      final isDigit = code >= 48 && code <= 57;
      final isApostrophe = ch == "'" || ch == "’";
      final isHyphen = ch == '-';
      return isAsciiLetter || isDigit || isApostrophe || isHyphen;
    }

    // Eğer boşluk/noktalama üzerine tıklandıysa en yakın kelime karakterine kaydır
    if (!isWordChar(fullText[idx])) {
      int left = idx - 1;
      while (left >= 0 && !isWordChar(fullText[left])) {
        left--;
      }
      int right = idx + 1;
      while (right < fullText.length && !isWordChar(fullText[right])) {
        right++;
      }
      if (left >= 0 && right < fullText.length) {
        idx = (idx - left) <= (right - idx) ? left : right;
      } else if (left >= 0) {
        idx = left;
      } else if (right < fullText.length) {
        idx = right;
      } else {
        print('🔍 [Extract Word] ❌ No word characters around tap');
        return {'word': '', 'start': 0, 'end': 0};
      }
      print('🔍 [Extract Word] Adjusted Character Index: $idx (char="${fullText[idx]}")');
    }

    // Solda kelime başlangıcını bul
    int start = idx;
    while (start > 0 && isWordChar(fullText[start - 1])) {
      start--;
    }

    // Sağda kelime sonunu bul
    int end = idx;
    while (end < fullText.length && isWordChar(fullText[end])) {
      end++;
    }
    
    print('🔍 [Extract Word] Word Boundaries: start=$start, end=$end');
    // Guard against invalid ranges (e.g., when tapping punctuation/space)
    if (end <= start) {
      print('🔍 [Extract Word] ❌ Invalid range: end <= start');
      return {'word': '', 'start': 0, 'end': 0};
    }

    // Clamp indices safely before substring
    final int safeStart = start.clamp(0, fullText.length);
    final int safeEnd = end.clamp(safeStart, fullText.length);
    if (safeEnd <= safeStart) {
      print('🔍 [Extract Word] ❌ Safe invalid range after clamp');
      return {'word': '', 'start': 0, 'end': 0};
    }

    final word = fullText.substring(safeStart, safeEnd).trim();
    
    print('🔍 [Extract Word] Extracted Word: "$word"');
    
    // Kelime boşsa veya çok kısaysa (1 karakterden az) geçersiz kabul et
    if (word.isEmpty || word.length < 1) {
      print('🔍 [Extract Word] ❌ Word too short or empty');
      return {'word': '', 'start': 0, 'end': 0};
    }

    // Kelime sadece noktalama işaretlerinden oluşuyorsa geçersiz
    final hasAlphaNum = RegExp(r'[A-Za-z0-9]').hasMatch(word);
    if (!hasAlphaNum) {
      print('🔍 [Extract Word] ❌ Word contains no alphanumeric');
      return {'word': '', 'start': 0, 'end': 0};
    }

    print('🔍 [Extract Word] ✅ Valid word: "$word"');
    print('🔍 [Extract Word] ===== EXTRACT WORD END =====');
    
    return {'word': word, 'start': start, 'end': end};
  }

  // Long press başlangıcı
  void _onWordLongPressStart(LongPressStartDetails details, String pageContent, BoxConstraints constraints, ThemeManager themeManager, TextStyle actualTextStyle) {
    HapticFeedback.mediumImpact();
    
    // Get current page index from the context
    final currentPageIndex = _readerBloc.state is ReaderLoaded ? (_readerBloc.state as ReaderLoaded).currentPage : 0;
    
    // Gerçek metin genişliğini render edilmiş metin kutusundan al
    
    // RenderBox'ı bul ve pozisyonu doğru hesapla
    final box = _textKeys[currentPageIndex]?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) {
      print('🔍 [Word Detection] RenderBox bulunamadı! PageIndex: $currentPageIndex');
      return;
    }
    
    // Box zaten scroll ile taşındığı için ekstra offset eklemiyoruz
    final localPos = box.globalToLocal(details.globalPosition);
    final double maxTextWidth = box.size.width;
    
    // Detaylı loglar
    print('🔍 [Word Detection] ===== LONG PRESS START =====');
    print('🔍 [Word Detection] Page Index: $currentPageIndex');
    print('🔍 [Word Detection] Global Position: ${details.globalPosition}');
    print('🔍 [Word Detection] Local Position: $localPos');
    print('🔍 [Word Detection] Box Size: ${box.size}');
    print('🔍 [Word Detection] Max Text Width: $maxTextWidth');
    print('🔍 [Word Detection] Font Size: ${actualTextStyle.fontSize}');
    print('🔍 [Word Detection] Page Content Length: ${pageContent.length}');
    print('🔍 [Word Detection] Page Content Preview: ${pageContent.substring(0, 100)}...');
    
    final wordInfo = _extractWordAtOffset(
      pageContent,
      actualTextStyle, // Gerçek text style kullan
      maxTextWidth,
      localPos,
    );
    
    print('🔍 [Word Detection] Detected Word: "${wordInfo['word']}"');
    print('🔍 [Word Detection] Word Start: ${wordInfo['start']}');
    print('🔍 [Word Detection] Word End: ${wordInfo['end']}');
    
    if (wordInfo['word'].toString().isNotEmpty) {
      // Try local phrasal detection
      final localHit = _detectLocalPhrasalAt(pageContent, wordInfo['start'], wordInfo['end']);
      final selStart = localHit != null ? localHit['start'] as int : wordInfo['start'] as int;
      final selEnd = localHit != null ? localHit['end'] as int : wordInfo['end'] as int;
      final selText = pageContent.substring(selStart, selEnd);
      setState(() {
        _wordStart = selStart;
        _wordEnd = selEnd;
        _wordPageIndex = currentPageIndex;
        _selectedWord = selText;
        _isLoadingTranslation = true;
        _wordTranslation = null;
      });
      
      print('🔍 [Word Detection] ✅ Word selected: "$selText"');
      
      // Show word popup overlay
      _showWordOverlay(details.globalPosition, selText, themeManager);
      
      if (localHit != null) {
        final entry = localHit['entry'] as PhrasalVerbEntry;
        setState(() {
          _wordTranslation = entry.meaningTr;
          _isLoadingTranslation = false;
        });
        _updateWordOverlay();
      } else {
        // Get translation from network
        _translateWord(selText);
      }
    } else {
      print('🔍 [Word Detection] ❌ No word detected');
    }
    
    print('🔍 [Word Detection] ===== LONG PRESS START END =====');
  }

  // Long press sonu
  void _onWordLongPressEnd() {
    // Tooltip kalıcı; seçim korunur ki çentik ve konum tekrar hesaplanabilsin
    print('🔍 [Word Detection] Long press ended - tooltip remains visible');
  }

  // Kelime çevirisi
  Future<void> _translateWord(String word) async {
    if (word.isEmpty) return;
    
    setState(() {
      _isLoadingTranslation = true;
    });
    // Reflect loading state in overlay immediately
    _updateWordOverlay();
    
    try {
      print('🌐 [Word Translation] Translating word: "$word"');
      final bloc = context.read<AdvancedReaderBloc>();
      final translation = await bloc.translateWord(word);
      
      print('🌐 [Word Translation] Translation result: "$translation"');
      
      if (mounted) {
        setState(() {
          _wordTranslation = translation.isNotEmpty ? translation : 'Çeviri bulunamadı';
          _isLoadingTranslation = false;
        });
        
        // Update overlay with translation
        _updateWordOverlay();
      }
    } catch (e) {
      print('🌐 [Word Translation] Translation error: $e');
      if (mounted) {
        setState(() {
          _wordTranslation = 'Çeviri hatası: $e';
          _isLoadingTranslation = false;
        });
        // Reflect error state/content in overlay as well
        _updateWordOverlay();
      }
    }
  }

  // Minimal Tooltip - Inspired by the image
  void _showWordOverlay(Offset globalPosition, String word, ThemeManager themeManager) {
    _hideWordOverlay();
    
    setState(() {
      _isTooltipVisible = true;
      _lastTooltipPosition = globalPosition;
    });
    print('📍 [Tooltip] Open at tap: '+(_lastTooltipPosition?.toString() ?? 'null')+', word="'+word+'"');
    
    _wordOverlay = OverlayEntry(
      builder: (context) {
        return AnimatedOpacity(
          opacity: _isTooltipVisible ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 150),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTapDown: (details) => _onBackdropTapDown(details.globalPosition, themeManager),
                  child: Container(color: Colors.black.withValues(alpha: 0.05)),
                ),
              ),
              Builder(builder: (context) {
                final anchor = _computeAnchor(context, _lastTooltipPosition);
                return Positioned(
                  left: anchor.left,
                  top: anchor.top,
                  bottom: anchor.bottom,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOut,
                    builder: (context, value, _) {
                      return Transform.scale(
                        scale: 0.98 + (0.02 * value),
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 8),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {},
                            child: Container(
                              width: 240,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                    left: anchor.notchLeft,
                                    top: anchor.showAbove ? null : -7,
                                    bottom: anchor.showAbove ? -7 : null,
                                    child: Transform.rotate(
                                      angle: 0.785398,
                                      child: Container(
                                        width: 14.0,
                                        height: 14.0,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.06),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -10,
                                    right: -10,
                                    child: GestureDetector(
                                      onTap: () => _hideWordOverlay(),
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.12),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.xmark,
                                          size: 14,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE6F0FF),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  word,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.black,
                                                    decoration: TextDecoration.none,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                GestureDetector(
                                                  onTap: () => _addToVocabulary(word),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    child: Icon(
                                                      CupertinoIcons.star,
                                                      size: 18,
                                                      color: Colors.amber,
                                                    ),
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () => _speakWord(word),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6),
                                                    child: Icon(
                                                      CupertinoIcons.speaker_2_fill,
                                                      size: 18,
                                                      color: CupertinoColors.activeBlue,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(vertical: 8),
                                          height: 1,
                                          color: Colors.black.withValues(alpha: 0.06),
                                        ),
                                        if (_isLoadingTranslation)
                                          Row(
                                            children: [
                                              const SizedBox(
                                                width: 14,
                                                height: 14,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 1.5,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                'Translating...',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[600],
                                                  decoration: TextDecoration.none,
                                                ),
                                              ),
                                            ],
                                          )
                                        else if (_wordTranslation != null && _wordTranslation!.isNotEmpty)
                                          Text(
                                            _wordTranslation!,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                              decoration: TextDecoration.none,
                                            ),
                                          )
                                        else
                                          Text(
                                            'Loading...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              decoration: TextDecoration.none,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
    
    Overlay.of(context).insert(_wordOverlay!);
    _attachOverlayRepositionListener(themeManager);
  }

  // Kelime popup overlay güncelle
  void _updateWordOverlay() {
    if (_wordOverlay != null) {
      print('🔄 [Overlay] markNeedsBuild triggered. Loading: '+
          _isLoadingTranslation.toString()+', Has translation: '+
          ((_wordTranslation ?? '').isNotEmpty).toString());
      _wordOverlay!.markNeedsBuild();
    }
  }

  // Overlay konumunu seçili kelimeye göre tekrar hesapla (scroll/pan sonrasında)
  void _repositionOverlayToSelectedWord(ThemeManager themeManager) {
    if (_wordPageIndex == null || _wordStart == null || _wordEnd == null) return;
    final textKey = _textKeys[_wordPageIndex!];
    final renderBox = textKey?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final pageContent = _getPageContent(_wordPageIndex!);
    if (pageContent.isEmpty) return;

    // Font style current
    final currentState = _readerBloc.state;
    double fontSize = 20;
    if (currentState is ReaderLoaded) {
      fontSize = currentState.fontSize;
    }
    final style = TextStyle(
      fontSize: fontSize,
      height: 1.6,
      letterSpacing: 0.1,
      color: _getThemeTextColor(themeManager),
    );

    final availableWidth = renderBox.size.width;
    final tp = TextPainter(
      text: TextSpan(text: pageContent, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );
    tp.layout(maxWidth: availableWidth);
    final centerIndex = ((_wordStart! + _wordEnd!) / 2).round();
    final caret = tp.getOffsetForCaret(TextPosition(offset: centerIndex), Rect.zero);
    final baselineY = caret.dy; // top of the word line
    final global = renderBox.localToGlobal(Offset(caret.dx, baselineY));
    print('📍 [Tooltip] Reposition to: '+global.toString()+' (caret.dx='+caret.dx.toString()+', caret.dy='+baselineY.toString()+')');
    setState(() {
      _lastTooltipPosition = global;
    });
    _updateWordOverlay();
  }

  void _attachOverlayRepositionListener(ThemeManager themeManager) {
    if (_wordPageIndex == null) return;
    _activeOverlayScrollController = _scrollControllers[_wordPageIndex!];
    _overlayScrollListener = () => _repositionOverlayToSelectedWord(themeManager);
    _activeOverlayScrollController?.addListener(_overlayScrollListener!);
  }

  void _detachOverlayRepositionListener() {
    if (_activeOverlayScrollController != null && _overlayScrollListener != null) {
      _activeOverlayScrollController!.removeListener(_overlayScrollListener!);
    }
    _overlayScrollListener = null;
    _activeOverlayScrollController = null;
  }

  TooltipAnchor _computeAnchor(BuildContext context, Offset? tap) {
    final size = MediaQuery.of(context).size;
    final safePadding = MediaQuery.of(context).padding;
    final Offset anchorTap = tap ?? Offset(size.width / 2, size.height / 2);
    const double tooltipWidth = 240.0;
    const double tooltipHeight = 120.0; // approx content height
    const double screenEdgePadding = 16.0; // padding from screen edges
    const double sidePadding = 12.0; // internal padding for notch clamping
    const double notchSize = 14.0;

    final double leftRaw = anchorTap.dx - tooltipWidth / 2;
    final double left = leftRaw.clamp(screenEdgePadding, size.width - tooltipWidth - screenEdgePadding);
    // Determine vertical bounds using reading area's RenderBox if available
    double safeTop = safePadding.top + screenEdgePadding;
    double safeBottom = size.height - screenEdgePadding;
    try {
      if (_wordPageIndex != null) {
        final renderBox = _textKeys[_wordPageIndex!]?.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final contentTop = renderBox.localToGlobal(Offset.zero).dy;
          final contentBottom = contentTop + renderBox.size.height;
          // Clamp to content rect to avoid overlapping top bar/controls
          safeTop = (contentTop + screenEdgePadding).clamp(safeTop, size.height);
          safeBottom = (contentBottom - screenEdgePadding).clamp(0.0, safeBottom);
          // If bounds inverted due to extremely small content, reset to screen bounds
          if (safeBottom <= safeTop) {
            safeTop = safePadding.top + screenEdgePadding;
            safeBottom = size.height - screenEdgePadding;
          }
        }
      }
    } catch (_) {
      // Fallback to screen-based bounds
      safeTop = safePadding.top + screenEdgePadding;
      safeBottom = size.height - screenEdgePadding;
    }

    // Choose above/below based on available space within the clamped bounds
    final double spaceAbove = (anchorTap.dy - safeTop).clamp(0.0, double.infinity);
    final double spaceBelow = (safeBottom - anchorTap.dy).clamp(0.0, double.infinity);
    final bool showAbove = spaceAbove >= tooltipHeight + 12.0 || (spaceAbove >= spaceBelow);
    final double topLimit = safeBottom - tooltipHeight;
    final double candidateTop = showAbove
        ? (anchorTap.dy - tooltipHeight - 12.0)
        : (anchorTap.dy + 12.0);
    final double? top = candidateTop.clamp(safeTop, topLimit);
    final double? bottom = null;

    // Notch left, clamped inside tooltip
    double notchLeft = (anchorTap.dx - left) - (notchSize / 2);
    notchLeft = notchLeft.clamp(sidePadding, tooltipWidth - sidePadding - notchSize);

    print('📍 [Tooltip] Anchor -> tap='+anchorTap.toString()+
        ', left='+left.toString()+
        ', top='+(top?.toString() ?? 'null')+
        ', bottom='+(bottom?.toString() ?? 'null')+
        ', showAbove='+showAbove.toString()+
        ', notchLeft='+notchLeft.toString()+
        ', screen='+size.width.toString()+'x'+size.height.toString()+
        ', safeTop='+safeTop.toString()+
        ', safeBottom='+safeBottom.toString());

    return TooltipAnchor(showAbove: showAbove, left: left.toDouble(), top: top?.toDouble(), bottom: bottom, notchLeft: notchLeft.toDouble());
  }

  // Kelime popup overlay gizle
  void _hideWordOverlay() {
    _wordOverlay?.remove();
    _wordOverlay = null;
    _detachOverlayRepositionListener();
    
    setState(() {
      _isTooltipVisible = false;
      _selectedWord = null;
      _wordTranslation = null;
      _isLoadingTranslation = false;
      _lastTooltipPosition = null;
    });
  }

  void _navigateToQuiz(ReaderLoaded state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: BlocProvider(
            create: (context) => ReadingQuizCubit(getIt<ReadingQuizService>()),
            child: ReadingQuizPage(
              readingTextId: _readerBloc.pageManager.bookId ?? 0,
              bookTitle: state.book.title,
              book: BookModel.fromBook(state.book),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _hideWordOverlay();
    _pageController.dispose();
    try { _readerBloc.add(StopSpeech()); } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    _flutterTts?.stop();
    _flutterTts = null;
    super.dispose();
  }
} 