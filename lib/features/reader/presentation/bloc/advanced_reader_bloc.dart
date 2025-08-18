import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../services/page_manager.dart';
import '../../data/services/translation_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/storage/last_read_manager.dart';
import 'reader_event.dart';
import 'reader_state.dart';

class AdvancedReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final BookRepository _bookRepository;
  final FlutterTts _flutterTts;
  final TranslationService _translationService = getIt<TranslationService>();
  final PageManager _pageManager;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<int, List<Map<String, dynamic>>> _manifestCache = {};
  
  Book? _currentBook;
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _speechRate = 0.5;
  double _fontSize = 27.0;
  int? _currentPlayingSentenceIndex;
  int? _currentSentenceBaseInPage;

  AdvancedReaderBloc({
    required BookRepository bookRepository,
    required FlutterTts flutterTts,
  })  : _bookRepository = bookRepository,
        _flutterTts = flutterTts,
        _pageManager = PageManager(),
        super(ReaderInitial()) {
    
    // Event handlers
    on<LoadBook>(_onLoadBook);
    on<NextPage>(_onNextPage);
    on<PreviousPage>(_onPreviousPage);
    on<GoToPage>(_onGoToPage);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<StopSpeech>(_onStopSpeech);
    on<UpdateSpeechRate>(_onUpdateSpeechRate);
    on<UpdateFontSize>(_onUpdateFontSize);

    _initializeTts();
    _setupPageManager();
  }

  // Simple helper exposed to UI for sentence translation; will be wired to DI
  Future<String> translateSentence(String sentence) async {
    try {
      // In a full setup, TranslationService is injected; to avoid crash if not, return empty
      if ((_translationService as dynamic) == null) return '';
      return await _translationService.translateSentence(sentence);
    } catch (_) {
      return '';
    }
  }

  Future<String?> findSentenceAudioUrl(int readingTextId, int sentenceIndex, {String voiceId = 'default'}) async {
    try {
      final manifest = _manifestCache[readingTextId] ??
          await _translationService.getAudioManifest(readingTextId, voiceId: voiceId);
      _manifestCache[readingTextId] = manifest;
      // naive: server-side order matches sentence order
      if (sentenceIndex >= 0 && sentenceIndex < manifest.length) {
        final item = manifest[sentenceIndex];
        final url = (item['audioUrl'] ?? item['AudioUrl']) as String?;
        if (url != null && url.isNotEmpty) {
          return url.startsWith('http') ? url : '${AppConfig.apiBaseUrl}$url';
        }
      }
      // Try by matching Index field if provided
      for (final item in manifest) {
        final idx = item['index'] ?? item['Index'];
        if (idx is int && idx == sentenceIndex) {
          final url = (item['audioUrl'] ?? item['AudioUrl']) as String?;
          if (url != null && url.isNotEmpty) {
            return url.startsWith('http') ? url : '${AppConfig.apiBaseUrl}$url';
          }
        }
      }
    } catch (_) {}
    return null;
  }

  int computeSentenceIndex(String tappedSentence, String pageContent) {
    try {
      final full = _currentBook?.content ?? '';
      if (full.isEmpty || tappedSentence.isEmpty) return 0;
      int pageStart = full.indexOf(pageContent);
      if (pageStart < 0) {
        pageStart = 0;
      }
      int sentStartInPage = pageContent.indexOf(tappedSentence);
      if (sentStartInPage < 0) sentStartInPage = 0;
      final globalPos = pageStart + sentStartInPage;
      final splitter = RegExp(r'(?<=[.!?])\s+');
      int count = 0;
      int cursor = 0;
      for (final match in splitter.allMatches(full)) {
        final end = match.start + 1; // position just after punctuation
        if (end > globalPos) break;
        count++;
        cursor = match.end;
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  // Speak a single sentence with known global sentence index for segment highlighting
  Future<void> speakSentenceWithIndex(String sentence, int sentenceIndex, {String languageCode = 'en-US'}) async {
    try {
      // TODO: replaced by server-side audio when available from manifest
      await _flutterTts.stop();
      await _flutterTts.setLanguage(languageCode);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
      _currentPlayingSentenceIndex = sentenceIndex;
      _currentSentenceBaseInPage = null;
      if (state is ReaderLoaded) {
        final s = state as ReaderLoaded;
        final localRange = computeLocalRangeForSentence(s.currentPageContent, sentenceIndex);
        if (localRange != null && localRange.length == 2) {
          _currentSentenceBaseInPage = localRange[0];
          emit(s.copyWith(
            isSpeaking: true,
            isPaused: false,
            playingSentenceIndex: sentenceIndex,
            playingRangeStart: localRange[0],
            playingRangeEnd: localRange[1],
          ));
        } else {
          emit(s.copyWith(
            isSpeaking: true,
            isPaused: false,
            playingSentenceIndex: sentenceIndex,
            playingRangeStart: null,
            playingRangeEnd: null,
          ));
        }
      }

      await _flutterTts.speak(sentence);

      _isSpeaking = true;
      _isPaused = false;
    } catch (e) {
      Logger.error('speakSentence error', e);
    }
  }

  // Stream sentence audio from backend manifest instead of local TTS
  Future<void> playSentenceFromUrl(String url) async {
    try {
      await _audioPlayer.stop();
      try { await _audioPlayer.setPlaybackRate(_speechRate.clamp(0.1, 2.0)); } catch (_) {}
      await _audioPlayer.play(UrlSource(url));
      _isSpeaking = true;
      _isPaused = false;
      if (state is ReaderLoaded) {
        final currentState = state as ReaderLoaded;
        emit(currentState.copyWith(isSpeaking: true, isPaused: false));
      }
    } catch (e) {
      Logger.error('playSentenceFromUrl error', e);
    }
  }

  List<int> _computeSentenceIndicesForPage(String pageContent) {
    final full = _currentBook?.content ?? '';
    if (full.isEmpty || pageContent.isEmpty) return [];
    final splitter = RegExp(r'(?<=[.!?])\s+');
    final sentences = full.split(splitter);
    final pageStart = full.indexOf(pageContent);
    if (pageStart < 0) return [];
    final pageEnd = pageStart + pageContent.length;
    final indices = <int>[];
    int offset = 0;
    for (int i = 0; i < sentences.length; i++) {
      final s = sentences[i];
      final start = full.indexOf(s, offset);
      if (start < 0) continue;
      final int end = start + s.length;
      offset = end;
      if (start >= pageStart && end <= pageEnd) {
        indices.add(i);
      }
      if (start > pageEnd) break;
    }
    return indices;
  }

  // Compute local start/end within the provided pageContent for a global sentence index.
  // Returns [start, end] or null if the sentence is not on this page.
  List<int>? computeLocalRangeForSentence(String pageContent, int globalSentenceIndex) {
    try {
      final full = _currentBook?.content ?? '';
      if (full.isEmpty || pageContent.isEmpty) return null;
      final pageStart = full.indexOf(pageContent);
      if (pageStart < 0) return null;
      final pageEnd = pageStart + pageContent.length;

      final splitter = RegExp(r'(?<=[.!?])\s+');
      final sentences = full.split(splitter);
      if (globalSentenceIndex < 0 || globalSentenceIndex >= sentences.length) return null;

      int offset = 0;
      for (int i = 0; i < sentences.length; i++) {
        final s = sentences[i];
        final start = full.indexOf(s, offset);
        if (start < 0) return null;
        final end = start + s.length;
        offset = end;
        if (i == globalSentenceIndex) {
          if (start >= pageStart && end <= pageEnd) {
            final localStart = start - pageStart;
            final localEnd = localStart + s.length;
            return [localStart, localEnd];
          }
          return null;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _playPageSequentially() async {
    if (state is! ReaderLoaded) return;
    var currentState = state as ReaderLoaded;
    final readingTextId = int.tryParse(_currentBook?.id ?? '0') ?? 0;
    var pageIndex = _pageManager.currentPageIndex;

    while (_isSpeaking && pageIndex < _pageManager.totalPages) {
      final pageText = _getCurrentPageContent();
      final indices = _computeSentenceIndicesForPage(pageText);

      for (final idx in indices) {
        if (!_isSpeaking) break;
        emit(currentState.copyWith(playingSentenceIndex: idx));
        final url = await findSentenceAudioUrl(readingTextId, idx);
        if (url != null) {
          await playSentenceFromUrl(url);
          try { await _audioPlayer.onPlayerComplete.first; } catch (_) {}
        }
      }

      if (!_isSpeaking) break;
      if (pageIndex >= _pageManager.totalPages - 1) break;

      // Advance to next page and update state
      await _pageManager.nextPage();
      pageIndex = _pageManager.currentPageIndex;
      if (state is ReaderLoaded) {
        currentState = (state as ReaderLoaded).copyWith(
          currentPage: _pageManager.currentPageIndex,
          currentPageContent: _getCurrentPageContent(),
        );
        emit(currentState);
      }
    }

    _isSpeaking = false;
    _isPaused = false;
    if (state is ReaderLoaded) {
      final endState = state as ReaderLoaded;
      emit(endState.copyWith(isSpeaking: false, isPaused: false, playingSentenceIndex: null));
    }
  }

  void _setupPageManager() {
    _pageManager.onPageChanged = (pageIndex) async {
      Logger.book('Page changed to: $pageIndex');
      try {
        if (_currentBook != null) {
          await getIt<LastReadManager>()
              .saveLastRead(bookId: _currentBook!.id, pageIndex: pageIndex);
        }
      } catch (_) {}
    };
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
      try {
        _flutterTts.setProgressHandler((String text, int start, int end, String word) async {
          if (state is! ReaderLoaded) return;
          final s = state as ReaderLoaded;
          if (_currentSentenceBaseInPage == null) return;
          final base = _currentSentenceBaseInPage!;
          final localStart = base + start;
          final localEnd = base + end;
          emit(s.copyWith(
            playingRangeStart: localStart,
            playingRangeEnd: localEnd,
          ));
        });
      } catch (_) {}
    } catch (e) {
      Logger.error('TTS initialization error', e);
    }
  }

  Future<void> _onLoadBook(LoadBook event, Emitter<ReaderState> emit) async {
    try {
      emit(ReaderLoading());

      final bookResult = await _bookRepository.getBook(event.bookId);

      await bookResult.fold(
        (failure) async {
          emit(ReaderError(failure.toString()));
        },
        (bookModel) async {
          if (bookModel == null) {
            emit(ReaderError('Book not found'));
            return;
          }

          _currentBook = bookModel;
          
          // Configure page manager for this book
          _pageManager.configureBook(int.tryParse(bookModel.id) ?? 0);
          
          // Initialize pagination with the book content
          await _initializePagination(bookModel.content);

          emit(ReaderLoaded(
            book: bookModel,
            currentPage: _pageManager.currentPageIndex,
            totalPages: _pageManager.totalPages,
            currentPageContent: _getCurrentPageContent(),
            fontSize: _fontSize,
            isSpeaking: _isSpeaking,
            isPaused: _isPaused,
            speechRate: _speechRate,
          ));
        },
      );
    } catch (e) {
      emit(ReaderError(e.toString()));
    }
  }

  Future<void> _initializePagination(String content) async {
    Logger.book('Initializing pagination for ${content.length} characters');
    
    final textStyle = TextStyle(
      fontSize: _fontSize,
      height: 1.6,
      letterSpacing: 0.1,
    );
    
    // Use a reasonable page size (will be updated when UI is available)
    const pageSize = Size(400, 600);
    
    await _pageManager.paginateText(
      text: content,
      style: textStyle,
      size: pageSize,
    );
    
    Logger.book('Pagination initialized: ${_pageManager.totalPages} pages');
  }

  String _getCurrentPageContent() {
    if (_pageManager.currentPageIndex < _pageManager.attributedPages.length) {
      return _pageManager.attributedPages[_pageManager.currentPageIndex].string;
    }
    return '';
  }

  void _onNextPage(NextPage event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      Logger.book('NextPage - Current: ${_pageManager.currentPageIndex} / ${_pageManager.totalPages}');
      
      _pageManager.nextPage().then((_) {
        if (state is ReaderLoaded) {
          final updatedState = state as ReaderLoaded;
          emit(updatedState.copyWith(
            currentPage: _pageManager.currentPageIndex,
            currentPageContent: _getCurrentPageContent(),
          ));
        }
      });
    }
  }

  void _onPreviousPage(PreviousPage event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      Logger.book('PreviousPage - Current: ${_pageManager.currentPageIndex} / ${_pageManager.totalPages}');
      
      _pageManager.previousPage().then((_) {
        if (state is ReaderLoaded) {
          final updatedState = state as ReaderLoaded;
          emit(updatedState.copyWith(
            currentPage: _pageManager.currentPageIndex,
            currentPageContent: _getCurrentPageContent(),
          ));
        }
      });
    }
  }

  void _onGoToPage(GoToPage event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      Logger.book('GoToPage - Target: ${event.page}');
      if (event.page == _pageManager.currentPageIndex) {
        return;
      }
      _pageManager.goToPage(event.page).then((_) {
        if (state is ReaderLoaded) {
          final updatedState = state as ReaderLoaded;
          emit(updatedState.copyWith(
            currentPage: _pageManager.currentPageIndex,
            currentPageContent: _getCurrentPageContent(),
          ));
        }
      });
    }
  }

  Future<void> _onTogglePlayPause(TogglePlayPause event, Emitter<ReaderState> emit) async {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      
      if (_isSpeaking) {
        if (_isPaused) {
          await _audioPlayer.resume();
          _isPaused = false;
        } else {
          await _audioPlayer.pause();
          _isPaused = true;
        }
      } else {
        _isSpeaking = true;
        _isPaused = false;
        await _playPageSequentially();
      }

      emit(currentState.copyWith(
        isSpeaking: _isSpeaking,
        isPaused: _isPaused,
      ));
    }
  }

  Future<void> _onStopSpeech(StopSpeech event, Emitter<ReaderState> emit) async {
    await _audioPlayer.stop();
    await _flutterTts.stop();
    _isSpeaking = false;
    _isPaused = false;
    
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      emit(currentState.copyWith(
        isSpeaking: false,
        isPaused: false,
      ));
    }
  }

  Future<void> _onUpdateSpeechRate(UpdateSpeechRate event, Emitter<ReaderState> emit) async {
    _speechRate = event.rate;
    await _flutterTts.setSpeechRate(_speechRate);
    try { await _audioPlayer.setPlaybackRate(_speechRate.clamp(0.1, 2.0)); } catch (_) {}
    
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      emit(currentState.copyWith(speechRate: _speechRate));
    }
  }

  void _onUpdateFontSize(UpdateFontSize event, Emitter<ReaderState> emit) {
    _fontSize = event.size;
    
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      emit(currentState.copyWith(fontSize: _fontSize));
      
      // Reinitialize pagination with new font size
      if (_currentBook != null) {
        _initializePagination(_currentBook!.content);
      }
    }
  }

  // MARK: - Debug Methods
  Map<String, dynamic> getMemoryStats() {
    return _pageManager.getMemoryStats();
  }

  Map<String, dynamic> getPerformanceMetrics() {
    return _pageManager.getPerformanceMetrics();
  }

  // MARK: - PageManager Access
  PageManager get pageManager => _pageManager;

  @override
  Future<void> close() async {
    await _flutterTts.stop();
    try { await _audioPlayer.dispose(); } catch (_) {}
    _pageManager.dispose();
    return super.close();
  }
} 