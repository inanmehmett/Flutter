import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Events
abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object> get props => [];
}

class CheckAuthStatus extends SplashEvent {}

// States
abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object> get props => [];
}

class SplashInitial extends SplashState {}

class SplashLoading extends SplashState {}

class NavigateToHome extends SplashState {}

// Bloc
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial()) {
    print('🔄 SplashBloc created');
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<SplashState> emit,
  ) async {
    print('🔍 Checking auth status...');
    emit(SplashLoading());
    print('⏳ SplashLoading emitted');

    await Future.delayed(const Duration(seconds: 2));
    print('⏰ 2 seconds delay completed');

    emit(NavigateToHome());
    print('🏠 NavigateToHome emitted');
  }
}
