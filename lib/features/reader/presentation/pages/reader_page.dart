import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../widgets/attributed_text_view.dart';
import '../widgets/tooltip_view.dart';
import '../widgets/font_settings_view.dart';
import '../widgets/speech_control_view.dart';
import '../bloc/reader_bloc.dart';
import '../bloc/reader_event.dart';
import '../bloc/reader_state.dart';
import '../../data/models/book_model.dart';

class ReaderPage extends StatefulWidget {
  final BookModel book;

  const ReaderPage({
    Key? key,
    required this.book,
  }) : super(key: key);

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late final ReaderBloc _readerBloc;
  late final FlutterTts _flutterTts;
  String? _selectedWord;
  bool _showTooltip = false;
  final Offset _tooltipPosition = Offset.zero;
  String _translatedWord = '';
  bool _isTranslating = false;
  final bool _isAutoAdvancing = false;
  DateTime _lastUserInteraction = DateTime.now();
  final _tooltipAutoHideDelay = const Duration(seconds: 5);
  int currentPage = 0;
  late List<String> pages;
  double fontSize = 20;
  Color backgroundColor = const Color(0xFFFCFCF7);
  Color textColor = Colors.black87;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _readerBloc = context.read<ReaderBloc>();
    _flutterTts = FlutterTts();
    _initializeTts();
    _loadBook();
    pages = _splitTextIntoPages(widget.book.content ?? '', 1100);
  }

  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
  }

  void _loadBook() {
    _readerBloc.add(LoadBook(widget.book.id.toString()));
  }

  List<String> _splitTextIntoPages(String text, int charsPerPage) {
    List<String> result = [];
    int start = 0;
    while (start < text.length) {
      int end = (start + charsPerPage < text.length) ? start + charsPerPage : text.length;
      result.add(text.substring(start, end));
      start = end;
    }
    return result.isEmpty ? ['No content'] : result;
  }

  void _toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
      backgroundColor = isDarkMode ? Color(0xFF232323) : Color(0xFFFCFCF7);
      textColor = isDarkMode ? Colors.white : Colors.black87;
    });
  }

  void _changeFontSize(double delta) {
    setState(() {
      fontSize = (fontSize + delta).clamp(14, 32);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.book.title ?? '';
    final totalPages = pages.length;
    final progress = (currentPage + 1) / totalPages;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round, color: textColor),
                    onPressed: _toggleTheme,
                  ),
                  IconButton(
                    icon: Icon(Icons.text_fields, color: textColor),
                    onPressed: () => _changeFontSize(2),
                  ),
                  IconButton(
                    icon: Icon(Icons.text_fields, color: textColor.withOpacity(0.5)),
                    onPressed: () => _changeFontSize(-2),
                  ),
                ],
              ),
            ),
            // İlerleme barı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.grey[200],
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('${((progress) * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                ],
              ),
            ),
            SizedBox(height: 8),
            // Sayfa numarası
            Text('${currentPage + 1}/$totalPages', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            SizedBox(height: 8),
            // Kitap metni (sayfa swipe)
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < 0 && currentPage < totalPages - 1) {
                      setState(() => currentPage++);
                    } else if (details.primaryVelocity! > 0 && currentPage > 0) {
                      setState(() => currentPage--);
                    }
                  }
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    pages[currentPage],
                    style: TextStyle(fontSize: fontSize, height: 1.6, color: textColor),
                  ),
                ),
              ),
            ),
            // Alt bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: backgroundColor,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.skip_previous, size: 32, color: currentPage > 0 ? textColor : Colors.grey[400]),
                    onPressed: currentPage > 0 ? () => setState(() => currentPage--) : null,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.record_voice_over, size: 28, color: textColor),
                        onPressed: () {}, // TTS entegrasyonu için
                      ),
                      IconButton(
                        icon: Icon(Icons.timer, size: 28, color: textColor),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.edit, size: 28, color: textColor),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.skip_next, size: 32, color: currentPage < totalPages - 1 ? textColor : Colors.grey[400]),
                    onPressed: currentPage < totalPages - 1 ? () => setState(() => currentPage++) : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(ReaderLoaded state) {
    return Column(
      children: [
        _buildTopBar(state),
        _buildProgressBar(state),
        Expanded(
          child: _buildReadingArea(state),
        ),
        _buildSpeechControls(state),
      ],
    );
  }

  Widget _buildTopBar(ReaderLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              state.book.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showFontSettings(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ReaderLoaded state) {
    final progress = (state.currentPage + 1) / state.totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${state.currentPage + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '/ ${state.totalPages}',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReadingArea(ReaderLoaded state) {
    return GestureDetector(
      onTapDown: (details) {
        setState(() {
          _lastUserInteraction = DateTime.now();
          if (_showTooltip) {
            _showTooltip = false;
          }
        });
      },
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        child: AttributedTextView(
          text: state.currentPageContent,
          onWordSelected: _handleWordSelection,
          showTooltip: _showTooltip,
          tooltipPosition: _tooltipPosition,
          fontSize: state.fontSize,
          textColor: Theme.of(context).colorScheme.onSurface,
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  Widget _buildSpeechControls(ReaderLoaded state) {
    return SpeechControlView(
      isSpeaking: state.isSpeaking,
      isPaused: state.isPaused,
      progress: (state.currentPage + 1) / state.totalPages,
      currentPage: state.currentPage,
      totalPages: state.totalPages,
      speechRate: state.speechRate,
      pitch: state.pitch,
      selectedVoice: state.selectedVoice,
      availableVoices: state.availableVoices,
      onPlayPause: _handlePlayPause,
      onPreviousPage: _handlePreviousPage,
      onNextPage: _handleNextPage,
      onSpeechRateChanged: _handleSpeechRateChanged,
      onPitchChanged: _handlePitchChanged,
      onVoiceChanged: _handleVoiceChanged,
      onPageChanged: _handlePageChanged,
    );
  }

  Widget _buildTooltip() {
    return TooltipView(
      word: _selectedWord ?? '',
      translation: _isTranslating ? 'Translating...' : _translatedWord,
      onClose: () {
        setState(() {
          _showTooltip = false;
          _selectedWord = null;
        });
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      textColor: Theme.of(context).colorScheme.onSurface,
      fontSize: 16,
      position: _tooltipPosition,
      visibleScreenHeight: MediaQuery.of(context).size.height,
      onFavoriteTap: _handleFavoriteTap,
      onPronounceTap: _handlePronounceTap,
    );
  }

  void _handleWordSelection(String? word) {
    if (word == null) {
      setState(() {
        _showTooltip = false;
        _selectedWord = null;
      });
      return;
    }

    setState(() {
      _selectedWord = word;
      _showTooltip = true;
      _translatedWord = '';
      _isTranslating = true;
    });

    _translateWord(word);
  }

  Future<void> _translateWord(String word) async {
    try {
      final translation = await _readerBloc.translateWord(word);
      if (mounted) {
        setState(() {
          _translatedWord = translation;
          _isTranslating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _translatedWord = 'Translation failed';
          _isTranslating = false;
        });
      }
    }
  }

  void _handlePlayPause() {
    _readerBloc.add(TogglePlayPause());
  }

  void _handlePreviousPage() {
    _readerBloc.add(PreviousPage());
  }

  void _handleNextPage() {
    _readerBloc.add(NextPage());
  }

  void _handleSpeechRateChanged(double rate) {
    _readerBloc.add(UpdateSpeechRate(rate));
  }

  void _handlePitchChanged(double pitch) {
    _readerBloc.add(UpdatePitch(pitch));
  }

  void _handleVoiceChanged(String voice) {
    _readerBloc.add(UpdateVoice(voice));
  }

  void _handlePageChanged(int page) {
    _readerBloc.add(GoToPage(page));
  }

  void _handleFavoriteTap() {
    if (_selectedWord != null) {
      _readerBloc.add(AddToFavorites(_selectedWord!));
    }
  }

  void _handlePronounceTap() {
    if (_selectedWord != null) {
      _flutterTts.speak(_selectedWord!);
    }
  }

  void _showFontSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final state = _readerBloc.state;
        final fontSize = state is ReaderLoaded ? state.fontSize : 16.0;

        return FontSettingsView(
          currentFontSize: fontSize,
          onFontSizeChanged: (size) {
            _readerBloc.add(UpdateFontSize(size));
          },
          currentTheme: Theme.of(context).brightness == Brightness.light
              ? ThemeMode.light
              : ThemeMode.dark,
          onThemeChanged: (theme) {
            _readerBloc.add(UpdateTheme(theme));
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
