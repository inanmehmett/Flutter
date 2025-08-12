import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/utils/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../services/page_manager.dart';
import '../../data/services/translation_service.dart';
import '../../../../core/di/injection.dart';
import 'reader_event.dart';
import 'reader_state.dart';

class AdvancedReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final BookRepository _bookRepository;
  final FlutterTts _flutterTts;
  final TranslationService _translationService = getIt<TranslationService>();
  final PageManager _pageManager;
  
  Book? _currentBook;
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _speechRate = 0.5;
  double _fontSize = 16.0;

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

  void _setupPageManager() {
    _pageManager.onPageChanged = (pageIndex) {
      Logger.book('Page changed to: $pageIndex');
    };
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
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
          // FlutterTts doesn't have resume, so we restart speaking
          await _flutterTts.speak(currentState.currentPageContent);
          _isPaused = false;
        } else {
          await _flutterTts.pause();
          _isPaused = true;
        }
      } else {
        _isSpeaking = true;
        _isPaused = false;
        await _flutterTts.speak(currentState.currentPageContent);
      }

      emit(currentState.copyWith(
        isSpeaking: _isSpeaking,
        isPaused: _isPaused,
      ));
    }
  }

  Future<void> _onStopSpeech(StopSpeech event, Emitter<ReaderState> emit) async {
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
    _pageManager.dispose();
    return super.close();
  }
} 