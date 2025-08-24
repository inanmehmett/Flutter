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
  int? _readingTextId;

  QuizCubit(this._repository) : super(const QuizInitial());

  Future<void> startQuiz({int? readingTextId}) async {
    emit(const QuizLoading());
    try {
      _readingTextId = readingTextId;
      
      final result = await _repository.getQuestions(
        count: 10,
        category: null,
        difficulty: null,
        readingTextId: readingTextId,
      );

      result.fold(
        (failure) => emit(QuizError(message: failure.message)),
        (questions) {
          _questions = questions;
          _currentQuestionIndex = 0;
          _score = 0;
          _questionResults = [];
          
          if (questions.isNotEmpty) {
            emit(QuizQuestionState(
              question: questions[0],
              selectedOption: null,
            ));
          } else {
            emit(QuizError(message: 'Quiz soruları bulunamadı'));
          }
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
            // Her doğru cevap için 10 puan
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
      // Quiz tamamlandı, sonucu hesapla
      _calculateAndEmitResult();
    }
  }

  void _calculateAndEmitResult() {
    if (_questions.isEmpty) return;

    final correctAnswers = _questionResults.where((r) => r.isCorrect).length;
    final wrongAnswers = _questionResults.where((r) => !r.isCorrect).length;
    final totalQuestions = _questions.length;
    
    // Yüzde hesaplama - her soru 10 puan
    final maxPossibleScore = totalQuestions * 10;
    final percentage = maxPossibleScore > 0 ? (_score / maxPossibleScore) * 100 : 0.0;

    final result = QuizResult(
      score: _score,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      wrongAnswers: wrongAnswers,
      percentage: percentage,
      questionResults: _questionResults,
    );

    // Sonucu kaydet
    _repository.saveQuizResult(result);
    
    // Sonuç state'ini emit et
    emit(QuizResultState(result: result));
  }

  // Quiz'i yeniden başlat
  void restartQuiz() {
    if (_readingTextId != null) {
      startQuiz(readingTextId: _readingTextId);
    } else {
      startQuiz();
    }
  }
}
