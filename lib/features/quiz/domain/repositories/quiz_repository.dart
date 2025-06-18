import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/quiz_models.dart';

abstract class QuizRepository {
  Future<Either<Failure, List<QuizQuestion>>> getQuestions({
    required int count,
    String? category,
    String? difficulty,
  });

  Future<Either<Failure, AnswerResult>> checkAnswer({
    required QuizQuestion question,
    required QuizOption selectedOption,
  });

  Future<Either<Failure, void>> saveQuizResult(QuizResult result);
}
