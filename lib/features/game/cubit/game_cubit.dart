import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/game_service.dart';

sealed class GameState {}

class GameInitial extends GameState {}

class GameLoading extends GameState {}

class GameLoaded extends GameState {
  final UserProfileSummary summary;
  GameLoaded(this.summary);
}

class GameError extends GameState {
  final String message;
  GameError(this.message);
}

class GameCubit extends Cubit<GameState> {
  final GameService _gameService;
  GameCubit(this._gameService) : super(GameInitial());

  Future<void> loadProfile() async {
    emit(GameLoading());
    try {
      final summary = await _gameService.getProfileSummary();
      emit(GameLoaded(summary));
    } catch (e) {
      emit(GameError(e.toString()));
    }
  }
}


