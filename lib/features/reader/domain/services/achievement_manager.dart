import 'package:daily_english/core/network/network_manager.dart';
import 'package:daily_english/core/cache/cache_manager.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconUrl;
  final int points;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconUrl,
    required this.points,
    required this.isUnlocked,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String,
      points: json['points'] as int,
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconUrl': iconUrl,
      'points': points,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }
}

@singleton
class AchievementManager {
  final Dio _dio;
  final NetworkManager _networkManager;
  final CacheManager _cacheManager;
  static const String _achievementsKey = 'achievements';
  static const String _statsKey = 'user_stats';

  AchievementManager(this._dio, this._networkManager, this._cacheManager);

  Future<Either<Failure, List<Achievement>>> getAchievements() async {
    try {
      final response = await _dio.get('/achievements');
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final achievements = data
            .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
            .toList();
        await _cacheManager.setData(_achievementsKey, achievements);
        return Right(achievements);
      }
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, Achievement>> getAchievement(String id) async {
    try {
      final response = await _dio.get('/achievements/$id');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return Right(Achievement.fromJson(data));
      }
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, void>> unlockAchievement(String id) async {
    try {
      await _dio.post(
        '/achievements/$id/unlock',
        data: {},
      );
      await _cacheManager.removeData(_statsKey);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, void>> lockAchievement(String id) async {
    try {
      await _dio.post(
        '/achievements/$id/lock',
        data: {},
      );
      await _cacheManager.removeData(_statsKey);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, List<Achievement>>> getUserAchievements() async {
    try {
      final response = await _dio.get('/user/achievements');
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final achievements = data
            .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(achievements);
      }
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final cachedStats =
          await _cacheManager.getData<Map<String, dynamic>>(_statsKey);
      if (cachedStats != null) {
        return cachedStats;
      }

      final response = await _networkManager.get('/user/stats');
      final stats = response.data as Map<String, dynamic>;

      await _cacheManager.setData(_statsKey, stats);
      return stats;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> trackReadingProgress({
    required String bookId,
    required int pagesRead,
    required int totalPages,
  }) async {
    try {
      await _networkManager.post(
        '/user/progress',
        data: {
          'bookId': bookId,
          'pagesRead': pagesRead,
          'totalPages': totalPages,
        },
      );

      // Invalidate stats cache
      await _cacheManager.removeData(_statsKey);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> trackQuizCompletion({
    required String bookId,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      await _networkManager.post(
        '/user/quiz-completion',
        data: {
          'bookId': bookId,
          'score': score,
          'totalQuestions': totalQuestions,
        },
      );

      // Invalidate stats cache
      await _cacheManager.removeData(_statsKey);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> trackWordLearned(String word) async {
    try {
      await _networkManager.post(
        '/user/words',
        data: {'word': word},
      );

      // Invalidate stats cache
      await _cacheManager.removeData(_statsKey);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getLearnedWords() async {
    try {
      final response = await _networkManager.get('/user/words');
      final data = response.data as Map<String, dynamic>;
      return (data['words'] as List).map((word) => word as String).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> resetProgress() async {
    try {
      await _networkManager.delete('/user/progress');
      await _cacheManager.removeData(_statsKey);
      await _cacheManager.removeData(_achievementsKey);
    } catch (e) {
      rethrow;
    }
  }
}
