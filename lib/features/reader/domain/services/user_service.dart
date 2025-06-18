import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

@singleton
class UserService {
  final Dio _dio;

  UserService(this._dio);

  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final response = await _dio.get('/user/profile');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return Right(User.fromJson(data));
      }
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, User>> updateProfile({
    required String name,
    String? avatar,
  }) async {
    try {
      final response = await _dio.put(
        '/user/profile',
        data: {
          'name': name,
          if (avatar != null) 'avatar': avatar,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return Right(User.fromJson(data));
      }
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put(
        '/user/password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, void>> deleteAccount() async {
    try {
      await _dio.delete('/user');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, List<User>>> getFriends() async {
    try {
      final response = await _dio.get('/user/friends');
      if (response.statusCode == 200) {
        final data = response.data as List<dynamic>;
        final friends = data
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
        return Right(friends);
      }
      return Left(ServerFailure());
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, void>> addFriend(String userId) async {
    try {
      await _dio.post(
        '/user/friends',
        data: {
          'user_id': userId,
        },
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  Future<Either<Failure, void>> removeFriend(String userId) async {
    try {
      await _dio.delete('/user/friends/$userId');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}
