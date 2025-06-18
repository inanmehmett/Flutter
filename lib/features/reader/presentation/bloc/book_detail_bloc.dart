import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';
import '../../domain/repositories/translation_repository.dart';

// Events
abstract class BookDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadBookDetails extends BookDetailEvent {
  final String bookId;
  LoadBookDetails(this.bookId);

  @override
  List<Object?> get props => [bookId];
}

class NextPage extends BookDetailEvent {}

class PreviousPage extends BookDetailEvent {}

class TranslateWord extends BookDetailEvent {
  final String word;
  TranslateWord(this.word);

  @override
  List<Object?> get props => [word];
}

// States
abstract class BookDetailState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookDetailInitial extends BookDetailState {}

class BookDetailLoading extends BookDetailState {}

class BookDetailLoaded extends BookDetailState {
  final Book book;
  final List<String> pages;
  final int currentPageIndex;
  final String? translatedWord;
  final String? errorMessage;

  BookDetailLoaded({
    required this.book,
    required this.pages,
    required this.currentPageIndex,
    this.translatedWord,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [
        book,
        pages,
        currentPageIndex,
        translatedWord,
        errorMessage,
      ];

  BookDetailLoaded copyWith({
    Book? book,
    List<String>? pages,
    int? currentPageIndex,
    String? translatedWord,
    String? errorMessage,
  }) {
    return BookDetailLoaded(
      book: book ?? this.book,
      pages: pages ?? this.pages,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      translatedWord: translatedWord ?? this.translatedWord,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// BLoC
class BookDetailBloc extends Bloc<BookDetailEvent, BookDetailState> {
  final BookRepository bookRepository;
  final TranslationRepository translationRepository;
  final int maxCharactersPerPage = 500;

  BookDetailBloc({
    required this.bookRepository,
    required this.translationRepository,
  }) : super(BookDetailInitial()) {
    on<LoadBookDetails>(_onLoadBookDetails);
    on<NextPage>(_onNextPage);
    on<PreviousPage>(_onPreviousPage);
    on<TranslateWord>(_onTranslateWord);
  }

  List<String> _paginateText(String text) {
    final List<String> pages = [];
    int startIndex = 0;

    while (startIndex < text.length) {
      int endIndex = startIndex + maxCharactersPerPage;
      if (endIndex > text.length) {
        endIndex = text.length;
      } else {
        // Try to find a natural break point
        while (endIndex > startIndex &&
            text[endIndex - 1] != '.' &&
            text[endIndex - 1] != '\n') {
          endIndex--;
        }
      }
      pages.add(text.substring(startIndex, endIndex).trim());
      startIndex = endIndex;
    }

    return pages;
  }

  Future<void> _onLoadBookDetails(
    LoadBookDetails event,
    Emitter<BookDetailState> emit,
  ) async {
    emit(BookDetailLoading());
    try {
      final bookResult = await bookRepository.fetchBookDetails(event.bookId);

      await bookResult.fold(
        (failure) async {
          emit(BookDetailLoaded(
            book: Book.empty(),
            pages: [],
            currentPageIndex: 0,
            errorMessage: failure.toString(),
          ));
        },
        (bookModel) async {
          if (bookModel == null) {
            emit(BookDetailLoaded(
              book: Book.empty(),
              pages: [],
              currentPageIndex: 0,
              errorMessage: 'Book not found',
            ));
            return;
          }

          final book = bookModel.toEntity();
          final pages = _paginateText(book.content);
          emit(BookDetailLoaded(
            book: book,
            pages: pages,
            currentPageIndex: 0,
          ));
        },
      );
    } catch (e) {
      emit(BookDetailLoaded(
        book: Book.empty(),
        pages: [],
        currentPageIndex: 0,
        errorMessage: e.toString(),
      ));
    }
  }

  void _onNextPage(NextPage event, Emitter<BookDetailState> emit) {
    if (state is BookDetailLoaded) {
      final currentState = state as BookDetailLoaded;
      if (currentState.currentPageIndex < currentState.pages.length - 1) {
        emit(currentState.copyWith(
          currentPageIndex: currentState.currentPageIndex + 1,
        ));
      }
    }
  }

  void _onPreviousPage(PreviousPage event, Emitter<BookDetailState> emit) {
    if (state is BookDetailLoaded) {
      final currentState = state as BookDetailLoaded;
      if (currentState.currentPageIndex > 0) {
        emit(currentState.copyWith(
          currentPageIndex: currentState.currentPageIndex - 1,
        ));
      }
    }
  }

  Future<void> _onTranslateWord(
    TranslateWord event,
    Emitter<BookDetailState> emit,
  ) async {
    if (state is BookDetailLoaded) {
      final currentState = state as BookDetailLoaded;
      try {
        final translation =
            await translationRepository.translateWord(event.word);
        emit(currentState.copyWith(translatedWord: translation));
      } catch (e) {
        emit(currentState.copyWith(
          errorMessage: 'Failed to translate word: ${e.toString()}',
        ));
      }
    }
  }
}
