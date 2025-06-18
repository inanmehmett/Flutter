import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/quiz_models.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../services/quiz_service.dart';

class QuizRepositoryImpl implements QuizRepository {
  final QuizService _quizService;

  QuizRepositoryImpl(this._quizService);

  @override
  Future<Either<Failure, List<QuizQuestion>>> getQuestions({
    required int count,
    String? category,
    String? difficulty,
  }) async {
    try {
      final questions = await _quizService.getQuestions(
        count: count,
        category: category,
        difficulty: difficulty,
      );
      return Right(questions);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to fetch questions: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, AnswerResult>> checkAnswer({
    required QuizQuestion question,
    required QuizOption selectedOption,
  }) async {
    try {
      final result = await _quizService.checkAnswer(
        question,
        selectedOption,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(
        message: 'Failed to check answer: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> saveQuizResult(QuizResult result) async {
    try {
      // TODO: Implement local storage for quiz results
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to save quiz result: ${e.toString()}',
      ));
    }
  }
}
