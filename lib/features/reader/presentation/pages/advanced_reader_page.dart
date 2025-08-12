import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../../../core/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/advanced_reader_bloc.dart';
import '../bloc/reader_event.dart';
import '../bloc/reader_state.dart';
import '../../data/models/book_model.dart';

class AdvancedReaderPage extends StatefulWidget {
  final BookModel book;

  const AdvancedReaderPage({
    Key? key,
    required this.book,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(state),
            _buildProgressBar(state),
            Expanded(
              child: _buildReadingArea(state),
            ),
            _buildControls(state),
          ],
        ),
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.book.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Sayfa ${state.currentPage + 1} / ${state.totalPages}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(state),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ReaderLoaded state) {
    final progress = (state.currentPage + 1) / state.totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: Theme.of(context).colorScheme.surface,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildReadingArea(ReaderLoaded state) {
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
              physics: const PageScrollPhysics(),
              onPageChanged: (index) {
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
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sayfa numarası göstergesi
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Sayfa ${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
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
                                color: Theme.of(context).colorScheme.onSurface,
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
                                await bloc.speakSentence(sentence);
                              }
                              final translation = await bloc.translateSentence(sentence);
                              if (!mounted) return;
                              if (translation.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(translation),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                            child: _buildRichTextWithHighlight(
                              pageContent,
                              TextStyle(
                                fontSize: state.fontSize,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.6,
                                letterSpacing: 0.1,
                              ),
                              index,
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
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Theme.of(context).colorScheme.primary,
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
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
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

  Widget _buildRichTextWithHighlight(String text, TextStyle style, int pageIndex) {
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
          TextSpan(text: mid, style: style.copyWith(backgroundColor: Colors.yellow.withOpacity(0.4))),
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

  Widget _buildControls(ReaderLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          ),
          
          // Page info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sayfa ${state.currentPage + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '/ ${state.totalPages}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Text(
                  '${(((state.currentPage + 1) / state.totalPages) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
              
              // Play/Pause button
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: IconButton(
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
              
              // Stop button
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: () => _readerBloc.add(StopSpeech()),
                iconSize: 32,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              
              // Next page
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: _goToNextPage,
                iconSize: 32,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(ReaderLoaded state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Okuma Ayarları'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Font size control
            ListTile(
              title: const Text('Yazı Boyutu'),
              subtitle: Slider(
                value: state.fontSize,
                min: 12.0,
                max: 32.0,
                divisions: 20,
                onChanged: (size) {
                  _readerBloc.add(UpdateFontSize(size));
                },
              ),
              trailing: Text('${state.fontSize.round()}'),
            ),
            
            // Speech rate control
            ListTile(
              title: const Text('Konuşma Hızı'),
              subtitle: Slider(
                value: state.speechRate,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                onChanged: (rate) {
                  _readerBloc.add(UpdateSpeechRate(rate));
                },
              ),
              trailing: Text('${state.speechRate.toStringAsFixed(1)}x'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
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

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
} 