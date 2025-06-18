import 'package:equatable/equatable.dart';
import '../../domain/entities/quiz_models.dart';

abstract class QuizState extends Equatable {
  const QuizState();

  @override
  List<Object?> get props => [];
}

class QuizInitial extends QuizState {
  const QuizInitial();
}

class QuizLoading extends QuizState {
  const QuizLoading();
}

class QuizError extends QuizState {
  final String message;

  const QuizError({required this.message});

  @override
  List<Object?> get props => [message];
}

class QuizQuestionState extends QuizState {
  final QuizQuestion question;
  final QuizOption? selectedOption;

  const QuizQuestionState({
    required this.question,
    this.selectedOption,
  });

  @override
  List<Object?> get props => [question, selectedOption];
}

class QuizAnswered extends QuizState {
  final QuizQuestion question;
  final QuizOption selectedOption;
  final AnswerResult result;

  const QuizAnswered({
    required this.question,
    required this.selectedOption,
    required this.result,
  });

  @override
  List<Object?> get props => [question, selectedOption, result];
}

class QuizResultState extends QuizState {
  final QuizResult result;

  const QuizResultState({required this.result});

  @override
  List<Object?> get props => [result];
}
