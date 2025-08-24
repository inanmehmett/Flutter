part of 'reading_quiz_cubit.dart';

abstract class ReadingQuizState extends Equatable {
  const ReadingQuizState();

  @override
  List<Object?> get props => [];
}

class ReadingQuizInitial extends ReadingQuizState {}

class ReadingQuizLoading extends ReadingQuizState {}

class ReadingQuizStarted extends ReadingQuizState {
  final ReadingQuizData quizData;
  final int currentQuestionIndex;
  final List<ReadingQuizUserAnswer> userAnswers;
  final DateTime startTime;
  final DateTime? questionStartTime;

  const ReadingQuizStarted({
    required this.quizData,
    required this.currentQuestionIndex,
    required this.userAnswers,
    required this.startTime,
    this.questionStartTime,
  });

  @override
  List<Object?> get props => [
        quizData,
        currentQuestionIndex,
        userAnswers,
        startTime,
        questionStartTime,
      ];
}

class ReadingQuizCompleted extends ReadingQuizState {
  final ReadingQuizData quizData;
  final List<ReadingQuizUserAnswer> userAnswers;
  final DateTime startTime;

  const ReadingQuizCompleted({
    required this.quizData,
    required this.userAnswers,
    required this.startTime,
  });

  @override
  List<Object?> get props => [quizData, userAnswers, startTime];
}

class ReadingQuizSubmitting extends ReadingQuizState {}

class ReadingQuizFinished extends ReadingQuizState {
  final ReadingQuizResult result;

  const ReadingQuizFinished(this.result);

  @override
  List<Object?> get props => [result];
}

class ReadingQuizError extends ReadingQuizState {
  final String message;

  const ReadingQuizError(this.message);

  @override
  List<Object?> get props => [message];
}
