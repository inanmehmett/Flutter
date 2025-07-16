import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/data/models/user_profile.dart';

// Events
abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {
  const LoadHomeData();
}

// States
abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final UserProfile userProfile;
  final bool isFirstWelcome;
  final List<dynamic> recommendedBooks;
  final List<dynamic> trendingBooks;

  const HomeLoaded({
    required this.userProfile,
    this.isFirstWelcome = false,
    this.recommendedBooks = const [],
    this.trendingBooks = const [],
  });

  @override
  List<Object?> get props =>
      [userProfile, isFirstWelcome, recommendedBooks, trendingBooks];
}

class HomeError extends HomeState {
  final String message;

  const HomeError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeLoading()) {
    on<LoadHomeData>(_onLoadHomeData);
  }

  Future<void> _onLoadHomeData(
    LoadHomeData event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      // Dummy data
      await Future.delayed(const Duration(seconds: 1));
      emit(HomeLoaded(
        userProfile: UserProfile(
          id: '1',
          userName: 'Kullanıcı',
          email: 'user@example.com',
          profileImageUrl: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isActive: true,
          level: 1,
          experiencePoints: 0,
          totalReadBooks: 0,
          totalQuizScore: 0,
        ),
        isFirstWelcome: true,
        recommendedBooks: [],
        trendingBooks: [],
      ));
    } catch (e) {
      emit(const HomeError('Bir hata oluştu'));
    }
  }
}
