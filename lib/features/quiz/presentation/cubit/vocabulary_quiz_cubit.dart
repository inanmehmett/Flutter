import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/vocabulary_quiz_models.dart';
import '../../data/services/vocabulary_quiz_service.dart';

// States
abstract class VocabularyQuizState extends Equatable {
  const VocabularyQuizState();

  @override
  List<Object?> get props => [];
}

class VocabularyQuizInitial extends VocabularyQuizState {}

class VocabularyQuizLoading extends VocabularyQuizState {}

class VocabularyQuizStarted extends VocabularyQuizState {
  final List<VocabularyQuizQuestion> questions;
  final VocabularyQuizProgress progress;
  final int currentQuestionIndex;
  final int timeRemaining;

  const VocabularyQuizStarted({
    required this.questions,
    required this.progress,
    required this.currentQuestionIndex,
    required this.timeRemaining,
  });

  VocabularyQuizQuestion get currentQuestion => questions[currentQuestionIndex];

  @override
  List<Object?> get props => [questions, progress, currentQuestionIndex, timeRemaining];
}

class VocabularyQuizQuestionAnswered extends VocabularyQuizState {
  final List<VocabularyQuizQuestion> questions;
  final VocabularyQuizProgress progress;
  final int currentQuestionIndex;
  final VocabularyQuizAnswer lastAnswer;
  final bool isCorrect;
  final int timeRemaining;

  const VocabularyQuizQuestionAnswered({
    required this.questions,
    required this.progress,
    required this.currentQuestionIndex,
    required this.lastAnswer,
    required this.isCorrect,
    required this.timeRemaining,
  });

  VocabularyQuizQuestion get currentQuestion => questions[currentQuestionIndex];

  @override
  List<Object?> get props => [
        questions,
        progress,
        currentQuestionIndex,
        lastAnswer,
        isCorrect,
        timeRemaining,
      ];
}

class VocabularyQuizCompleted extends VocabularyQuizState {
  final VocabularyQuizResult result;
  final List<VocabularyQuizAnswer> allAnswers;

  const VocabularyQuizCompleted({
    required this.result,
    required this.allAnswers,
  });

  @override
  List<Object?> get props => [result, allAnswers];
}

class VocabularyQuizError extends VocabularyQuizState {
  final String message;

  const VocabularyQuizError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Cubit
class VocabularyQuizCubit extends Cubit<VocabularyQuizState> {
  final VocabularyQuizService _quizService;
  
  List<VocabularyQuizQuestion> _questions = [];
  List<VocabularyQuizAnswer> _answers = [];
  VocabularyQuizProgress _progress = const VocabularyQuizProgress(
    currentQuestion: 0,
    totalQuestions: 0,
    correctAnswers: 0,
    wrongAnswers: 0,
    percentage: 0.0,
    timeSpent: 0,
  );
  int _currentQuestionIndex = 0;
  int _timeRemaining = 10;
  DateTime? _questionStartTime;
  int _quizId = 0;

  VocabularyQuizCubit(this._quizService) : super(VocabularyQuizInitial());

  /// Start a new vocabulary quiz
  Future<void> startQuiz() async {
    emit(VocabularyQuizLoading());
    
    try {
      _questions = await _quizService.getRandomQuiz();
      _answers = [];
      _currentQuestionIndex = 0;
      _quizId = DateTime.now().millisecondsSinceEpoch % 1000000; // Generate smaller unique quiz ID
      
      if (_questions.isEmpty) {
        emit(const VocabularyQuizError(message: 'Quiz soruları bulunamadı'));
        return;
      }

      _progress = VocabularyQuizProgress(
        currentQuestion: 1,
        totalQuestions: _questions.length,
        correctAnswers: 0,
        wrongAnswers: 0,
        percentage: 0.0,
        timeSpent: 0,
      );

      _timeRemaining = _questions.first.timeLimitSeconds;
      _questionStartTime = DateTime.now();

      emit(VocabularyQuizStarted(
        questions: _questions,
        progress: _progress,
        currentQuestionIndex: _currentQuestionIndex,
        timeRemaining: _timeRemaining,
      ));
    } catch (e) {
      emit(VocabularyQuizError(message: e.toString()));
    }
  }

  /// Answer the current question
  Future<void> answerQuestion(String selectedAnswer) async {
    if (state is! VocabularyQuizStarted && state is! VocabularyQuizQuestionAnswered) {
      return;
    }

    final currentState = state;
    VocabularyQuizQuestion question;
    if (currentState is VocabularyQuizStarted) {
      question = currentState.currentQuestion;
    } else if (currentState is VocabularyQuizQuestionAnswered) {
      question = currentState.currentQuestion;
    } else {
      return;
    }
    
    final correctOption = question.correctOption;
    final isCorrect = correctOption?.text == selectedAnswer;
    
    final timeSpent = _questionStartTime != null 
        ? DateTime.now().difference(_questionStartTime!).inSeconds
        : 0;

    final answer = VocabularyQuizAnswer(
      questionId: question.id,
      userAnswer: selectedAnswer,
      isCorrect: isCorrect,
      timeSpentSeconds: timeSpent,
      answeredAt: DateTime.now(),
    );

    _answers.add(answer);

    // Update progress
    _progress = VocabularyQuizProgress(
      currentQuestion: _currentQuestionIndex + 1,
      totalQuestions: _questions.length,
      correctAnswers: _answers.where((a) => a.isCorrect).length,
      wrongAnswers: _answers.where((a) => !a.isCorrect).length,
      percentage: (_answers.where((a) => a.isCorrect).length / _questions.length) * 100,
      timeSpent: _answers.fold(0, (sum, answer) => sum + answer.timeSpentSeconds),
    );

    emit(VocabularyQuizQuestionAnswered(
      questions: _questions,
      progress: _progress,
      currentQuestionIndex: _currentQuestionIndex,
      lastAnswer: answer,
      isCorrect: isCorrect,
      timeRemaining: _timeRemaining,
    ));
  }

  /// Move to the next question
  Future<void> nextQuestion() async {
    if (state is! VocabularyQuizQuestionAnswered) {
      return;
    }

    _currentQuestionIndex++;
    
    if (_currentQuestionIndex >= _questions.length) {
      // Quiz completed
      await _completeQuiz();
    } else {
      // Move to next question
      _timeRemaining = _questions[_currentQuestionIndex].timeLimitSeconds;
      _questionStartTime = DateTime.now();

      emit(VocabularyQuizStarted(
        questions: _questions,
        progress: _progress,
        currentQuestionIndex: _currentQuestionIndex,
        timeRemaining: _timeRemaining,
      ));
    }
  }

  /// Update timer (called from UI)
  void updateTimer(int timeRemaining) {
    _timeRemaining = timeRemaining;
    
    if (timeRemaining <= 0) {
      // Time's up - auto-answer with wrong answer
      final currentState = state;
      if (currentState is VocabularyQuizStarted) {
        final question = currentState.currentQuestion;
        final wrongAnswer = question.options.firstWhere((opt) => !opt.isCorrect).text;
        answerQuestion(wrongAnswer);
      }
    } else {
      // Update current state with new time
      final currentState = state;
      if (currentState is VocabularyQuizStarted) {
        emit(VocabularyQuizStarted(
          questions: _questions,
          progress: _progress,
          currentQuestionIndex: _currentQuestionIndex,
          timeRemaining: _timeRemaining,
        ));
      } else if (currentState is VocabularyQuizQuestionAnswered) {
        emit(VocabularyQuizQuestionAnswered(
          questions: _questions,
          progress: _progress,
          currentQuestionIndex: _currentQuestionIndex,
          lastAnswer: currentState.lastAnswer,
          isCorrect: currentState.isCorrect,
          timeRemaining: _timeRemaining,
        ));
      }
    }
  }

  /// Complete the quiz and get results
  Future<void> _completeQuiz() async {
    try {
      final completionRequest = VocabularyQuizCompletionRequest(
        quizId: _quizId,
        answers: _answers,
        completionTimeMinutes: _progress.timeSpent ~/ 60,
        vocabularyQuizScore: _progress.correctAnswers * 10, // 10 points per correct answer
        vocabularyCorrectAnswers: _progress.correctAnswers,
        vocabularyTotalQuestions: _progress.totalQuestions,
      );

      final result = await _quizService.completeQuiz(completionRequest);

      emit(VocabularyQuizCompleted(
        result: result,
        allAnswers: _answers,
      ));
    } catch (e) {
      emit(VocabularyQuizError(message: 'Quiz tamamlanırken hata oluştu: $e'));
    }
  }

  /// Restart the quiz
  Future<void> restartQuiz() async {
    await startQuiz();
  }

  /// Get current progress
  VocabularyQuizProgress get progress => _progress;

  /// Get current question index
  int get currentQuestionIndex => _currentQuestionIndex;

  /// Get total questions
  int get totalQuestions => _questions.length;

  /// Get time remaining
  int get timeRemaining => _timeRemaining;
}