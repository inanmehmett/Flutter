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
import '../../../../core/storage/last_read_manager.dart';
import '../../../../core/analytics/event_service.dart';
import 'reader_event.dart';
import 'reader_state.dart';

class AdvancedReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final BookRepository _bookRepository;
  final FlutterTts _flutterTts;
  final TranslationService _translationService;
  final EventService _eventService;
  final PageManager _pageManager;
  final AudioPlayer _audioPlayer;
  final LastReadManager _lastReadManager;
  final Map<int, List<Map<String, dynamic>>> _manifestCache = {};
  final bool _enableTts;
  StreamSubscription<PlayerState>? _audioStateSub;
  bool _sequentialInProgress = false;
  Timer? _endUiDebounce;
  static const Duration _endUiDebounceDuration = Duration(milliseconds: 150);
  StreamSubscription<Duration>? _audioPosSub;
  StreamSubscription<Duration>? _audioDurSub;
  
  Book? _currentBook;
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _speechRate = 0.40;
  // Track user-initiated single sentence playback and resumption logic
  bool _invokedBySequential = false;              // true while sequential calls play
  bool _resumeSequentialAfterSingle = false;      // if a single tap interrupted sequential
  int? _resumeStartGlobalIndex;                   // next global sentence index to continue from
  int? _lastPlayedSentenceIndexGlobal;            // last global sentence index played

  double _audioRateForTts(double ttsRate) {
    // Map normalized TTS rate (0.1-1.0) to a practical audio playback rate
    if (ttsRate <= 0.40) return 0.7;    // Yavaş (düşürüldü)
    if (ttsRate <= 0.50) return 0.9;    // Normal (düşürüldü)
    if (ttsRate <= 0.65) return 1.0;    // Orta-Hızlı (düşürüldü)
    return 1.2;                         // Hızlı
  }
  double _fontSize = 27.0;
  int? _currentPlayingSentenceIndex;
  int? _currentSentenceBaseInPage;
  Timer? _readingHeartbeat;

  AdvancedReaderBloc({
    required BookRepository bookRepository,
    required FlutterTts flutterTts,
    required TranslationService translationService,
    required EventService eventService,
    required LastReadManager lastReadManager,
    PageManager? pageManager,
    AudioPlayer? audioPlayer,
    bool enableTts = true,
  })  : _bookRepository = bookRepository,
        _flutterTts = flutterTts,
        _translationService = translationService,
        _eventService = eventService,
        _lastReadManager = lastReadManager,
        _pageManager = pageManager ?? PageManager(),
        _audioPlayer = audioPlayer ?? AudioPlayer(),
        _enableTts = enableTts,
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

    if (_enableTts) {
      _initializeTts();
    } else {
      Logger.debug('TTS initialization skipped (enableTts=false)');
    }
    _initializeAudioListeners();
    _setupPageManager();
  }

  // Simple helper exposed to UI for sentence translation; will be wired to DI
  Future<String> translateSentence(String sentence) async {
    try {
      return await _translationService.translateSentence(sentence);
    } catch (e) {
      Logger.error('translateSentence error', e);
      return '';
    }
  }

  // Word translation helper
  Future<String> translateWord(String word) async {
    try {
      return await _translationService.translateWord(word);
    } catch (e) {
      Logger.error('translateWord error', e);
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
    } catch (e) { Logger.warning('findSentenceAudioUrl: manifest lookup failed'); }
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
      Logger.info('Speak sentence via TTS | index=$sentenceIndex, lang=$languageCode');
      // Ensure mutual exclusion with streaming audio
      try { await _audioPlayer.stop(); } catch (_) {}
      _endUiDebounce?.cancel();
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
            playingRangeEnd: localRange[1], // highlight entire sentence
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
  Future<void> playSentenceFromUrl(String url, {int? sentenceIndex}) async {
    try {
      Logger.info('Play sentence from URL | url=$url');
      // Ensure mutual exclusion with TTS
      try { await _flutterTts.stop(); } catch (_) {}
      _endUiDebounce?.cancel();
      await _audioPlayer.stop();
      try { await _audioPlayer.setPlaybackRate(_audioRateForTts(_speechRate).clamp(0.1, 2.0)); } catch (_) {}
      await _audioPlayer.play(UrlSource(url));
      _isSpeaking = true;
      _isPaused = false;
      if (sentenceIndex != null) {
        _lastPlayedSentenceIndexGlobal = sentenceIndex;
        // If user tapped during sequential, request resumption after this single finishes
        if (!_invokedBySequential && _sequentialInProgress) {
          _resumeSequentialAfterSingle = true;
        }
        // Always remember where to resume if user later presses Play
        _resumeStartGlobalIndex = sentenceIndex + 1;
      }
      if (sentenceIndex != null && state is ReaderLoaded) {
        _currentPlayingSentenceIndex = sentenceIndex;
        final s = state as ReaderLoaded;
        final localRange = computeLocalRangeForSentence(_getCurrentPageContent(), sentenceIndex);
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
          emit(s.copyWith(isSpeaking: true, isPaused: false, playingSentenceIndex: sentenceIndex));
        }
      }
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

  Future<void> _playPageSequentially({int? startGlobalIndex}) async {
    if (state is! ReaderLoaded) return;
    var currentState = state as ReaderLoaded;
    final readingTextId = int.tryParse(_currentBook?.id ?? '0') ?? 0;
    var pageIndex = _pageManager.currentPageIndex;
    if (_sequentialInProgress) {
      Logger.debug('Sequential playback already in progress, ignoring duplicate call');
      return;
    }
    _sequentialInProgress = true;

    // If a specific start sentence is requested, navigate to its page first
    if (startGlobalIndex != null) {
      try {
        final targetPage = await _findPageIndexForGlobalSentence(startGlobalIndex);
        if (targetPage != null) {
          await _pageManager.goToPage(targetPage);
          pageIndex = targetPage;
          if (state is ReaderLoaded) {
            final updated = (state as ReaderLoaded).copyWith(
              currentPage: _pageManager.currentPageIndex,
              currentPageContent: _getCurrentPageContent(),
            );
            emit(updated);
            currentState = updated;
          }
        }
      } catch (e) { Logger.warning('readingActive heartbeat failed'); }
    }

    // start heartbeat to credit non-audio reading time
    _readingHeartbeat?.cancel();
    if (readingTextId > 0) {
      _readingHeartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
        try { unawaited(_eventService.readingActive(readingTextId, 15)); } catch (_) {}
      });
    }

    while (_isSpeaking && pageIndex < _pageManager.totalPages) {
      final pageText = _getCurrentPageContent();
      final indices = _computeSentenceIndicesForPage(pageText);

      for (final idx in indices) {
        // Skip until the requested start index on the first iteration
        if (startGlobalIndex != null && idx < startGlobalIndex) {
          continue;
        }
        if (!_isSpeaking) break;
        emit(currentState.copyWith(playingSentenceIndex: idx));
        final url = await findSentenceAudioUrl(readingTextId, idx);
        if (url != null) {
          Logger.debug('Sequential play start | page=$pageIndex, sentence=$idx');
          final startedAt = DateTime.now();
          _invokedBySequential = true;
          await playSentenceFromUrl(url, sentenceIndex: idx);
          _invokedBySequential = false;
          try { await _audioPlayer.onPlayerComplete.first; } catch (e) { Logger.warning('onPlayerComplete await failed'); }
          final endedAt = DateTime.now();
          final durationMs = endedAt.difference(startedAt).inMilliseconds;
          Logger.debug('Sequential play complete | page=$pageIndex, sentence=$idx, durationMs=$durationMs');
          if (readingTextId > 0) {
            unawaited(_eventService.sentenceListened(readingTextId, idx, durationMs));
          }
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
      // After the first page, clear start constraint
      startGlobalIndex = null;
    }

    _isSpeaking = false;
    _isPaused = false;
    _readingHeartbeat?.cancel();
    if (state is ReaderLoaded) {
      final endState = state as ReaderLoaded;
      emit(endState.copyWith(isSpeaking: false, isPaused: false, playingSentenceIndex: null));
    }

    // Fire reading_completed when reached the end naturally
    if (readingTextId > 0 && pageIndex >= _pageManager.totalPages - 1) {
      try {
        unawaited(_eventService.readingCompleted(readingTextId));
      } catch (e) { Logger.warning('readingCompleted event failed'); }
    }
    _sequentialInProgress = false;
  }

  Future<int?> _findPageIndexForGlobalSentence(int globalSentenceIndex) async {
    try {
      final total = _pageManager.totalPages;
      for (int i = _pageManager.currentPageIndex; i < total; i++) {
        final content = _pageManager.attributedPages[i].string;
        final range = computeLocalRangeForSentence(content, globalSentenceIndex);
        if (range != null) return i;
      }
      // Optionally search previous pages
      for (int i = 0; i < _pageManager.currentPageIndex; i++) {
        final content = _pageManager.attributedPages[i].string;
        final range = computeLocalRangeForSentence(content, globalSentenceIndex);
        if (range != null) return i;
      }
    } catch (e) { Logger.warning('findPageIndexForSentence failed'); }
    return null;
  }

  void _setupPageManager() {
    _pageManager.onPageChanged = (pageIndex) async {
      Logger.book('Page changed to: $pageIndex');
      try {
        if (_currentBook != null) {
          await _lastReadManager.saveLastRead(
            bookId: _currentBook!.id,
            pageIndex: pageIndex,
          );
        }
      } catch (e) { Logger.warning('saveLastRead failed'); }
    };
  }

  void _initializeAudioListeners() {
    try {
      _audioStateSub = _audioPlayer.onPlayerStateChanged.listen((playerState) {
        Logger.debug('Audio state changed: $playerState');
        if (playerState == PlayerState.completed || playerState == PlayerState.stopped) {
          // During sequential playback we keep isSpeaking=true across sentence boundaries
          if (_sequentialInProgress) {
            // If a single-tap interrupted sequential and asked to resume, we'll handle after complete
            return;
          }
          // Debounce end-state to avoid quick flicker if a new sentence starts immediately
          _endUiDebounce?.cancel();
          _endUiDebounce = Timer(_endUiDebounceDuration, () {
            _isSpeaking = false;
            _isPaused = false;
            if (state is ReaderLoaded) {
              final s = state as ReaderLoaded;
              emit(s.copyWith(
                isSpeaking: false,
                isPaused: false,
                playingSentenceIndex: null,
                playingRangeStart: null,
                playingRangeEnd: null,
              ));
            }
            // If a user-tapped single sentence finished and sequential was active before, resume
            if (_resumeSequentialAfterSingle && _resumeStartGlobalIndex != null) {
              _resumeSequentialAfterSingle = false;
              _isSpeaking = true;
              _isPaused = false;
              unawaited(_playPageSequentially(startGlobalIndex: _resumeStartGlobalIndex));
            }
          });
        }
      });
      // For streamed audio, keep full sentence highlighted (no progressive update)
      Duration currentDuration = Duration.zero;
      _audioDurSub = _audioPlayer.onDurationChanged.listen((d) {
        currentDuration = d;
      });
      _audioPosSub = _audioPlayer.onPositionChanged.listen((pos) {
        try {
          if (state is! ReaderLoaded) return;
          final s = state as ReaderLoaded;
          if (_currentPlayingSentenceIndex == null) return;
          final localRange = computeLocalRangeForSentence(_getCurrentPageContent(), _currentPlayingSentenceIndex!);
          if (localRange == null || localRange.length != 2) return;
          emit(s.copyWith(
            playingSentenceIndex: _currentPlayingSentenceIndex,
            playingRangeStart: localRange[0],
            playingRangeEnd: localRange[1],
          ));
        } catch (e) { Logger.warning('audio position emit failed'); }
      });
      try {
        _audioPlayer.onSeekComplete.listen((_) {
          Logger.debug('Audio seek completed');
        });
      } catch (e) { Logger.warning('onSeekComplete listener attach failed'); }
    } catch (e) {
      Logger.error('initializeAudioListeners error', e);
    }
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
      try {
        _flutterTts.setProgressHandler((String text, int start, int end, String word) async {
          // Keep entire sentence highlighted during TTS
          if (state is! ReaderLoaded) return;
          final s = state as ReaderLoaded;
          if (_currentPlayingSentenceIndex == null) return;
          final range = computeLocalRangeForSentence(_getCurrentPageContent(), _currentPlayingSentenceIndex!);
          if (range == null || range.length != 2) return;
          emit(s.copyWith(
            playingRangeStart: range[0],
            playingRangeEnd: range[1],
          ));
        });
        _flutterTts.setStartHandler(() {
          Logger.debug('TTS start');
        });
        _flutterTts.setCompletionHandler(() {
          Logger.debug('TTS completed');
          _isSpeaking = false;
          _isPaused = false;
          if (state is ReaderLoaded) {
            final s = state as ReaderLoaded;
            emit(s.copyWith(isSpeaking: false, isPaused: false, playingSentenceIndex: null));
          }
        });
        _flutterTts.setCancelHandler(() {
          Logger.debug('TTS canceled');
          _isSpeaking = false;
          _isPaused = false;
          if (state is ReaderLoaded) {
            final s = state as ReaderLoaded;
            emit(s.copyWith(isSpeaking: false, isPaused: false));
          }
        });
        _flutterTts.setPauseHandler(() {
          Logger.debug('TTS paused');
          _isPaused = true;
          if (state is ReaderLoaded) {
            final s = state as ReaderLoaded;
            emit(s.copyWith(isPaused: true));
          }
        });
        _flutterTts.setContinueHandler(() {
          Logger.debug('TTS continued');
          _isPaused = false;
          if (state is ReaderLoaded) {
            final s = state as ReaderLoaded;
            emit(s.copyWith(isPaused: false));
          }
        });
      } catch (e) { Logger.warning('flutterTts handler setup failed'); }
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

          // Try to restore last read page
          int initialPage = 0;
          try {
            final lastRead = await _lastReadManager.getLastRead();
            if (lastRead != null && lastRead.book.id == bookModel.id) {
              initialPage = lastRead.pageIndex.clamp(0, _pageManager.totalPages > 0 ? _pageManager.totalPages - 1 : 0);
              if (initialPage != _pageManager.currentPageIndex) {
                await _pageManager.goToPage(initialPage);
              }
            }
          } catch (e) { Logger.warning('restore lastRead failed'); }

          // Emit initial loaded state with restored page if available
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

          // Persist last read immediately to ensure Home picks it up
          try {
            await _lastReadManager.saveLastRead(
              bookId: bookModel.id,
              pageIndex: _pageManager.currentPageIndex,
            );
          } catch (e) { Logger.warning('initial saveLastRead failed'); }

          // Fire reading_started event (non-blocking)
          final readingTextId = int.tryParse(bookModel.id) ?? 0;
          if (readingTextId > 0) {
            unawaited(_eventService.readingStarted(readingTextId));
            // Start passive reading heartbeat for users who read silently
            _readingHeartbeat?.cancel();
            _readingHeartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
              try { unawaited(_eventService.readingActive(readingTextId, 15)); } catch (_) {}
            });
          }
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
      // Stop any ongoing playback when navigating pages
      add(StopSpeech());
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
      // Stop any ongoing playback when navigating pages
      add(StopSpeech());
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
      // Stop any ongoing playback when jumping to a specific page
      add(StopSpeech());
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
      Logger.debug('TogglePlayPause | isSpeaking=$_isSpeaking, isPaused=$_isPaused');
      if (_isSpeaking) {
        if (_isPaused) {
          Logger.debug('Audio resume requested');
          await _audioPlayer.resume();
          _isPaused = false;
        } else {
          Logger.debug('Audio pause requested');
          await _audioPlayer.pause();
          _isPaused = true;
        }
      } else {
        Logger.debug('Start sequential playback');
        _isSpeaking = true;
        _isPaused = false;
        // If user last played a single tapped sentence, continue from the next one
        final startFrom = _resumeStartGlobalIndex;
        await _playPageSequentially(startGlobalIndex: startFrom);
      }

      emit(currentState.copyWith(
        isSpeaking: _isSpeaking,
        isPaused: _isPaused,
      ));
    }
  }

  Future<void> _onStopSpeech(StopSpeech event, Emitter<ReaderState> emit) async {
    Logger.debug('StopSpeech requested');
    _endUiDebounce?.cancel();
    await _audioPlayer.stop();
    await _flutterTts.stop();
    _isSpeaking = false;
    _isPaused = false;
    _sequentialInProgress = false;
    _currentPlayingSentenceIndex = null;
    _currentSentenceBaseInPage = null;
    _readingHeartbeat?.cancel();
    // Reset resume/continuation flags for a clean stop
    _invokedBySequential = false;
    _resumeSequentialAfterSingle = false;
    _resumeStartGlobalIndex = null;
    _lastPlayedSentenceIndexGlobal = null;
    
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      emit(currentState.copyWith(
        isSpeaking: false,
        isPaused: false,
        playingSentenceIndex: null,
        playingRangeStart: null,
        playingRangeEnd: null,
      ));
    }
  }

  Future<void> _onUpdateSpeechRate(UpdateSpeechRate event, Emitter<ReaderState> emit) async {
    _speechRate = event.rate;
    await _flutterTts.setSpeechRate(_speechRate);
    final mapped = _audioRateForTts(_speechRate).clamp(0.1, 2.0);
    Logger.debug('UpdateSpeechRate | ttsRate=${event.rate} -> audioRate=$mapped');
    try { await _audioPlayer.setPlaybackRate(mapped); } catch (_) {}
    
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
    _readingHeartbeat?.cancel();
    try { await _audioStateSub?.cancel(); } catch (_) {}
    try { await _audioPosSub?.cancel(); } catch (_) {}
    try { await _audioDurSub?.cancel(); } catch (_) {}
    _pageManager.dispose();
    return super.close();
  }
} 