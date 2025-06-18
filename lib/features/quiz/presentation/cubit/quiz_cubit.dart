import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/quiz_models.dart';
import '../../domain/repositories/quiz_repository.dart';
import 'quiz_state.dart';

class QuizCubit extends Cubit<QuizState> {
  final QuizRepository _repository;
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  List<QuestionResult> _questionResults = [];

  QuizCubit(this._repository) : super(const QuizInitial());

  Future<void> startQuiz() async {
    emit(const QuizLoading());
    try {
      final result = await _repository.getQuestions(
        count: 10,
        category: null,
        difficulty: null,
      );

      result.fold(
        (failure) => emit(QuizError(message: failure.message)),
        (questions) {
          _questions = questions;
          _currentQuestionIndex = 0;
          _score = 0;
          _questionResults = [];
          emit(QuizQuestionState(
            question: questions[0],
            selectedOption: null,
          ));
        },
      );
    } catch (e) {
      emit(QuizError(message: e.toString()));
    }
  }

  void selectOption(QuizOption option) {
    if (state is QuizQuestionState) {
      final currentState = state as QuizQuestionState;
      emit(QuizQuestionState(
        question: currentState.question,
        selectedOption: option,
      ));
    }
  }

  Future<void> checkAnswer() async {
    if (state is QuizQuestionState) {
      final currentState = state as QuizQuestionState;
      if (currentState.selectedOption == null) return;

      try {
        final result = await _repository.checkAnswer(
          question: currentState.question,
          selectedOption: currentState.selectedOption!,
        );

        result.fold(
          (failure) => emit(QuizError(message: failure.message)),
          (answerResult) {
            if (answerResult.isCorrect) {
              _score += 10;
            }

            _questionResults.add(QuestionResult(
              question: currentState.question,
              selectedOption: currentState.selectedOption!,
              isCorrect: answerResult.isCorrect,
            ));

            emit(QuizAnswered(
              question: currentState.question,
              selectedOption: currentState.selectedOption!,
              result: answerResult,
            ));
          },
        );
      } catch (e) {
        emit(QuizError(message: e.toString()));
      }
    }
  }

  void nextQuestion() {
    _currentQuestionIndex++;
    if (_currentQuestionIndex < _questions.length) {
      emit(QuizQuestionState(
        question: _questions[_currentQuestionIndex],
        selectedOption: null,
      ));
    } else {
      final result = QuizResult(
        score: _score,
        totalQuestions: _questions.length,
        correctAnswers: _questionResults.where((r) => r.isCorrect).length,
        wrongAnswers: _questionResults.where((r) => !r.isCorrect).length,
        percentage: (_score / (_questions.length * 10)) * 100,
        questionResults: _questionResults,
      );

      _repository.saveQuizResult(result);
      emit(QuizResultState(result: result));
    }
  }
}
