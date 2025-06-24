import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import 'reader_event.dart';
import 'reader_state.dart';

class ReaderBloc extends Bloc<ReaderEvent, ReaderState> {
  final BookRepository _bookRepository;
  final FlutterTts _flutterTts;
  Book? _currentBook;
  List<String> _pages = [];
  bool _isSpeaking = false;
  bool _isPaused = false;
  double _speechRate = 0.5;
  double _pitch = 1.0;
  String _selectedVoice = '';
  List<String> _availableVoices = [];
  double _fontSize = 16.0;

  ReaderBloc({
    required BookRepository bookRepository,
    required FlutterTts flutterTts,
  })  : _bookRepository = bookRepository,
        _flutterTts = flutterTts,
        super(ReaderInitial()) {
    on<LoadBook>(_onLoadBook);
    on<NextPage>(_onNextPage);
    on<PreviousPage>(_onPreviousPage);
    on<GoToPage>(_onGoToPage);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<UpdateSpeechRate>(_onUpdateSpeechRate);
    on<UpdatePitch>(_onUpdatePitch);
    on<UpdateVoice>(_onUpdateVoice);
    on<UpdateFontSize>(_onUpdateFontSize);
    on<UpdateTheme>(_onUpdateTheme);
    on<AddToFavorites>(_onAddToFavorites);

    _initializeTts();
  }

  Future<void> _initializeTts() async {
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(1.0);

      final voices = await _flutterTts.getVoices;
      if (voices != null) {
        _availableVoices = voices
            .where((voice) => voice['locale'] == 'en-US')
            .map((voice) => voice['name'] as String)
            .toList();
        if (_availableVoices.isNotEmpty) {
          _selectedVoice = _availableVoices.first;
          await _flutterTts
              .setVoice({'name': _selectedVoice, 'locale': 'en-US'});
        }
      }
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

          emit(ReaderLoaded(
            book: bookModel,
            currentPage: 0,
            totalPages: pages.length,
            currentPageContent: pages.isNotEmpty ? pages[0] : '',
            fontSize: _fontSize,
            isSpeaking: _isSpeaking,
            isPaused: _isPaused,
            speechRate: _speechRate,
            pitch: _pitch,
            selectedVoice: _selectedVoice,
            availableVoices: _availableVoices,
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
    
    for (final paragraph in paragraphs) {
      if (currentPage.length + paragraph.length > 1000) { // ~1000 chars per page
        if (currentPage.isNotEmpty) {
          pages.add(currentPage.trim());
          currentPage = '';
        }
      }
      currentPage += paragraph + '\n\n';
    }
    
    if (currentPage.isNotEmpty) {
      pages.add(currentPage.trim());
    }
    
    return pages.isEmpty ? [content] : pages;
  }

  void _onNextPage(NextPage event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      if (currentState.currentPage < currentState.totalPages - 1) {
        emit(currentState.copyWith(
          currentPage: currentState.currentPage + 1,
          currentPageContent: _pages[currentState.currentPage + 1],
        ));
      }
    }
  }

  void _onPreviousPage(PreviousPage event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      if (currentState.currentPage > 0) {
        emit(currentState.copyWith(
          currentPage: currentState.currentPage - 1,
          currentPageContent: _pages[currentState.currentPage - 1],
        ));
      }
    }
  }

  void _onGoToPage(GoToPage event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      if (event.page >= 0 && event.page < currentState.totalPages) {
        emit(currentState.copyWith(
          currentPage: event.page,
          currentPageContent: _pages[event.page],
        ));
      }
    }
  }

  Future<void> _onTogglePlayPause(
      TogglePlayPause event, Emitter<ReaderState> emit) async {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      if (_isSpeaking) {
        if (_isPaused) {
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

  Future<void> _onUpdateSpeechRate(
      UpdateSpeechRate event, Emitter<ReaderState> emit) async {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      _speechRate = event.rate;
      await _flutterTts.setSpeechRate(_speechRate);
      emit(currentState.copyWith(speechRate: _speechRate));
    }
  }

  Future<void> _onUpdatePitch(
      UpdatePitch event, Emitter<ReaderState> emit) async {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      _pitch = event.pitch;
      await _flutterTts.setPitch(_pitch);
      emit(currentState.copyWith(pitch: _pitch));
    }
  }

  Future<void> _onUpdateVoice(
      UpdateVoice event, Emitter<ReaderState> emit) async {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      _selectedVoice = event.voice;
      await _flutterTts.setVoice({'name': _selectedVoice, 'locale': 'en-US'});
      emit(currentState.copyWith(selectedVoice: _selectedVoice));
    }
  }

  void _onUpdateFontSize(UpdateFontSize event, Emitter<ReaderState> emit) {
    if (state is ReaderLoaded) {
      final currentState = state as ReaderLoaded;
      _fontSize = event.size;
      emit(currentState.copyWith(fontSize: _fontSize));
    }
  }

  void _onUpdateTheme(UpdateTheme event, Emitter<ReaderState> emit) {
    // Theme changes are handled at the app level
  }

  Future<void> _onAddToFavorites(
      AddToFavorites event, Emitter<ReaderState> emit) async {
    if (_currentBook != null) {
      await _bookRepository.addToFavorites(_currentBook!.id, event.word);
    }
  }

  Future<String> translateWord(String word) async {
    // Implement translation logic here
    return 'Translation of $word';
  }

  @override
  Future<void> close() async {
    await _flutterTts.stop();
    return super.close();
  }
}
