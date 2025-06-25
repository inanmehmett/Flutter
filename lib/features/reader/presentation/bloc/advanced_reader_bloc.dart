import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import 'reader_event.dart';
import 'reader_state.dart';

class AdvancedReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final BookRepository _bookRepository;
  final FlutterTts _flutterTts;
  
  Book? _currentBook;
  List<String> _pages = [];
  int _currentPageIndex = 0;
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _speechRate = 0.5;
  double _fontSize = 16.0;

  AdvancedReaderBloc({
    required BookRepository bookRepository,
    required FlutterTts flutterTts,
  })  : _bookRepository = bookRepository,
        _flutterTts = flutterTts,
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
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
    } catch (e) {
      // Handle TTS initialization error
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

          // Split book content into pages
          final content = bookModel.content;
          final pages = _splitContentIntoPages(content);

          _currentBook = bookModel;
          _pages = pages;
          _currentPageIndex = 0;

          emit(ReaderLoaded(
            book: bookModel,
            currentPage: 0,
            totalPages: pages.length,
            currentPageContent: pages.isNotEmpty ? pages[0] : '',
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

  List<String> _splitContentIntoPages(String content) {
    // Simple page splitting logic - split by paragraphs
    final paragraphs = content.split('\n\n');
    final pages = <String>[];
    String currentPage = '';
    
    print('📖 [AdvancedReaderBloc] Splitting content into pages...');
    print('📖 [AdvancedReaderBloc] Total content length: ${content.length} characters');
    print('📖 [AdvancedReaderBloc] Number of paragraphs: ${paragraphs.length}');
    
    for (final paragraph in paragraphs) {
      if (currentPage.length + paragraph.length > 1000) { // ~1000 chars per page
        if (currentPage.isNotEmpty) {
          pages.add(currentPage.trim());
          print('📖 [AdvancedReaderBloc] Created page ${pages.length} with ${currentPage.length} characters');
          currentPage = '';
        }
      }
      currentPage += paragraph + '\n\n';
    }
    
    if (currentPage.isNotEmpty) {
      pages.add(currentPage.trim());
      print('📖 [AdvancedReaderBloc] Created final page ${pages.length} with ${currentPage.length} characters');
    }
    
    print('📖 [AdvancedReaderBloc] Total pages created: ${pages.length}');
    return pages.isEmpty ? [content] : pages;
  }

  void _onNextPage(NextPage event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      print('📖 [AdvancedReaderBloc] NextPage event - Current page: $_currentPageIndex, Total pages: ${_pages.length}');
      
      if (_currentPageIndex < _pages.length - 1) {
        _currentPageIndex++;
        print('📖 [AdvancedReaderBloc] Moving to page $_currentPageIndex');
        emit(currentState.copyWith(
          currentPage: _currentPageIndex,
          currentPageContent: _pages[_currentPageIndex],
        ));
      } else {
        print('📖 [AdvancedReaderBloc] Already at last page');
      }
    }
  }

  void _onPreviousPage(PreviousPage event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      print('📖 [AdvancedReaderBloc] PreviousPage event - Current page: $_currentPageIndex, Total pages: ${_pages.length}');
      
      if (_currentPageIndex > 0) {
        _currentPageIndex--;
        print('📖 [AdvancedReaderBloc] Moving to page $_currentPageIndex');
        emit(currentState.copyWith(
          currentPage: _currentPageIndex,
          currentPageContent: _pages[_currentPageIndex],
        ));
      } else {
        print('📖 [AdvancedReaderBloc] Already at first page');
      }
    }
  }

  void _onGoToPage(GoToPage event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      if (event.page >= 0 && event.page < _pages.length) {
        _currentPageIndex = event.page;
        emit(currentState.copyWith(
          currentPage: _currentPageIndex,
          currentPageContent: _pages[_currentPageIndex],
        ));
      }
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
    }
  }

  @override
  Future<void> close() async {
    await _flutterTts.stop();
    return super.close();
  }
} 