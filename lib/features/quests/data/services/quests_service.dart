import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/cache/cache_manager.dart';
import '../models/daily_task.dart';

@lazySingleton
class QuestsService {
  final ApiClient _apiClient;
  final CacheManager _cacheManager;
  QuestsService(this._apiClient, this._cacheManager);

  Future<List<DailyTaskModel>> fetchDailyTasks({bool forceRefresh = false}) async {
    const String cacheKey = 'quests/daily';

    // Cache-first unless forceRefresh
    if (!forceRefresh) {
      final cached = await _cacheManager.getData<List<dynamic>>(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached
            .whereType<Map<String, dynamic>>()
            .map((m) => DailyTaskModel.fromJson(m))
            .toList();
      }
    }

    final Response resp = await _apiClient.get(ApiEndpoints.dailyTasks);
    final data = resp.data;
    final list = (data is Map<String, dynamic> && data['data'] is List)
        ? data['data'] as List<dynamic>
        : const <dynamic>[];

    // Store raw json list for easy decode later
    await _cacheManager.setData(cacheKey, list, timeout: const Duration(minutes: 5));

    return list
        .whereType<Map<String, dynamic>>()
        .map((m) => DailyTaskModel.fromJson(m))
        .toList();
  }

  Future<Map<String, dynamic>> claimTask(int taskId) async {
    final Response resp = await _apiClient.post(ApiEndpoints.claimTask, data: {'taskId': taskId});
    final data = resp.data is Map<String, dynamic> ? resp.data as Map<String, dynamic> : <String, dynamic>{};
    // Invalidate quests cache after a successful claim
    try {
      await _cacheManager.removeData('quests/daily');
    } catch (_) {}
    return data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : <String, dynamic>{};
  }
}


