import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
    int? readingTextId,
  }) async {
    try {
      final questions = await _quizService.getQuestions(
        count: count,
        category: category,
        difficulty: difficulty,
        readingTextId: readingTextId,
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
      final prefs = await SharedPreferences.getInstance();
      final resultsKey = 'quiz_results';
      
      // Get existing results
      final existingResultsJson = prefs.getStringList(resultsKey) ?? [];
      final existingResults = existingResultsJson
          .map((json) => QuizResult.fromJson(jsonDecode(json)))
          .toList();
      
      // Add new result
      existingResults.add(result);
      
      // Keep only last 100 results to prevent storage bloat
      if (existingResults.length > 100) {
        existingResults.removeRange(0, existingResults.length - 100);
      }
      
      // Save back to storage
      final resultsToSave = existingResults
          .map((result) => jsonEncode(result.toJson()))
          .toList();
      
      await prefs.setStringList(resultsKey, resultsToSave);
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to save quiz result: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, List<QuizResult>>> getQuizResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultsKey = 'quiz_results';
      
      final resultsJson = prefs.getStringList(resultsKey) ?? [];
      final results = resultsJson
          .map((json) => QuizResult.fromJson(jsonDecode(json)))
          .toList();
      
      return Right(results);
    } catch (e) {
      return Left(CacheFailure(
        message: 'Failed to retrieve quiz results: ${e.toString()}',
      ));
    }
  }
}
