import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/book.dart';
import '../../domain/repositories/book_repository.dart';

// Events
abstract class BookListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadBooks extends BookListEvent {}

// States
abstract class BookListState extends Equatable {
  @override
  List<Object?> get props => [];
}

class BookListInitial extends BookListState {}

class BookListLoading extends BookListState {}

class BookListLoaded extends BookListState {
  final List<Book> books;
  final DateTime? lastRefreshed;
  final String? errorMessage;

  BookListLoaded({required this.books, this.lastRefreshed, this.errorMessage});

  List<Book> get recommendedBooks => books.take(5).toList();

  List<Book> get trendingBooks {
    final shuffled = List<Book>.from(books)..shuffle();
    return shuffled.take(5).toList();
  }

  @override
  List<Object?> get props => [books, lastRefreshed, errorMessage];
}

// BLoC
class BookListBloc extends Bloc<BookListEvent, BookListState> {
  final BookRepository bookRepository;

  BookListBloc({required this.bookRepository}) : super(BookListInitial()) {
    on<LoadBooks>(_onLoadBooks);
    _loadCachedBooksFirst();
  }

  Future<void> _loadCachedBooksFirst() async {
    try {
      final cachedBooksEither = await bookRepository.getCachedBooks();
      cachedBooksEither.fold(
        (failure) => print('Error loading cached books: $failure'),
        (books) {
          if (books.isNotEmpty) {
            emit(BookListLoaded(
              books: books.map((model) => model.toEntity()).toList(),
              lastRefreshed: DateTime.now(),
            ));
          }
        },
      );
    } catch (e) {
      print('Error loading cached books: $e');
    }
  }

  Future<void> _onLoadBooks(
    LoadBooks event,
    Emitter<BookListState> emit,
  ) async {
    emit(BookListLoading());
    try {
      final booksEither = await bookRepository.fetchBooks();
      booksEither.fold(
        (failure) async {
          final cachedBooksEither = await bookRepository.getCachedBooks();
          cachedBooksEither.fold(
            (cacheFailure) => emit(
              BookListLoaded(
                books: [],
                errorMessage: 'Kitap listesi alınamadı ve çevrimdışı veri yok.',
              ),
            ),
            (cachedBooks) => emit(
              BookListLoaded(
                books: cachedBooks.map((model) => model.toEntity()).toList(),
                lastRefreshed: DateTime.now(),
                errorMessage:
                    'Çevrimdışı modda, önceden kaydedilmiş kitaplar gösteriliyor.',
              ),
            ),
          );
        },
        (books) {
          final activeBooks = books
              .where((book) => book.isActive ?? true)
              .map((model) => model.toEntity())
              .toList();
          emit(BookListLoaded(
            books: activeBooks,
            lastRefreshed: DateTime.now(),
          ));
        },
      );
    } catch (e) {
      emit(
        BookListLoaded(
          books: [],
          errorMessage: e.toString(),
        ),
      );
    }
  }

  List<Book> booksInCategory(int categoryId) {
    if (state is BookListLoaded) {
      return (state as BookListLoaded)
          .books
          .where((book) => book.categoryId == categoryId)
          .toList();
    }
    return [];
  }

  List<Book> booksByLevel(int level) {
    if (state is BookListLoaded) {
      return (state as BookListLoaded)
          .books
          .where((book) => book.textLevel == level)
          .toList();
    }
    return [];
  }

  List<Book> quickReads({int lessThanMinutes = 10}) {
    if (state is BookListLoaded) {
      return (state as BookListLoaded)
          .books
          .where(
            (book) =>
                book.estimatedReadingTimeInMinutes < lessThanMinutes,
          )
          .toList();
    }
    return [];
  }
}
