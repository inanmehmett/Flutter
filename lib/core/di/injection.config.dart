// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive/hive.dart' as _i979;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/auth/data/services/auth_service.dart' as _i449;
import '../../features/quests/data/services/quests_service.dart' as _i512;
import '../../features/reader/data/datasources/book_local_data_source.dart'
    as _i386;
import '../../features/reader/data/datasources/book_remote_data_source.dart'
    as _i435;
import '../../features/reader/data/models/book_model.dart' as _i525;
import '../../features/reader/data/repositories/book_repository_impl.dart'
    as _i707;
import '../../features/reader/data/services/translation_service.dart' as _i696;
import '../../features/reader/domain/repositories/book_repository.dart'
    as _i413;
import '../../features/reader/domain/services/achievement_manager.dart'
    as _i689;
import '../../features/reader/domain/services/auth_service.dart' as _i331;
import '../../features/reader/domain/services/user_service.dart' as _i121;
import '../analytics/event_service.dart' as _i859;
import '../cache/cache_manager.dart' as _i326;
import '../network/api_client.dart' as _i557;
import '../network/network_manager.dart' as _i474;
import '../realtime/signalr_service.dart' as _i550;
import '../storage/last_read_manager.dart' as _i298;
import '../storage/secure_storage_service.dart' as _i666;
import '../storage/storage_manager.dart' as _i392;
import '../sync/sync_manager.dart' as _i417;
import 'dio_module.dart' as _i1045;
import 'hive_module.dart' as _i576;
import 'storage_module.dart' as _i371;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final dioModule = _$DioModule();
    final storageModule = _$StorageModule();
    final hiveModule = _$HiveModule();
    gh.singleton<_i361.Dio>(() => dioModule.dio);
    gh.singleton<_i558.FlutterSecureStorage>(() => storageModule.secureStorage);
    gh.singleton<_i979.Box<_i525.BookModel>>(() => hiveModule.bookBox);
    gh.singleton<_i979.Box<int>>(() => hiveModule.progressBox);
    gh.singleton<_i979.Box<DateTime>>(() => hiveModule.lastReadBox);
    gh.singleton<_i979.Box<String>>(
      () => hiveModule.appCacheBox,
      instanceName: 'app_cache',
    );
    gh.singleton<_i979.Box<String>>(
      () => hiveModule.favoritesBox,
      instanceName: 'favorites',
    );
    gh.factory<_i435.BookRemoteDataSource>(
        () => _i435.BookRemoteDataSourceImpl(gh<_i361.Dio>()));
    gh.singleton<_i121.UserService>(() => _i121.UserService(gh<_i361.Dio>()));
    gh.singleton<_i392.StorageManager>(() =>
        _i392.StorageManager(gh<_i979.Box<String>>(instanceName: 'app_cache')));
    gh.singleton<_i666.SecureStorageService>(
        () => _i666.SecureStorageService(gh<_i558.FlutterSecureStorage>()));
    gh.singleton<_i557.ApiClient>(
        () => _i557.ApiClient(gh<_i666.SecureStorageService>()));
    gh.factory<_i386.BookLocalDataSource>(
        () => _i386.BookLocalDataSourceImpl(gh<_i979.Box<_i525.BookModel>>()));
    gh.singleton<_i326.CacheManager>(() => _i326.CacheManager(
          gh<_i979.Box<String>>(instanceName: 'app_cache'),
          gh<Duration>(),
        ));
    gh.singleton<_i331.AuthService>(() => _i331.AuthService(
          gh<_i361.Dio>(),
          gh<_i326.CacheManager>(),
          gh<_i666.SecureStorageService>(),
        ));
    gh.lazySingleton<_i859.EventService>(
        () => _i859.EventService(gh<_i557.ApiClient>()));
    gh.singleton<_i474.NetworkManager>(() => _i474.NetworkManager(
          gh<_i361.Dio>(),
          gh<_i666.SecureStorageService>(),
        ));
    gh.factory<_i413.BookRepository>(() => _i707.BookRepositoryImpl(
          networkManager: gh<_i474.NetworkManager>(),
          cacheManager: gh<_i326.CacheManager>(),
          dio: gh<_i361.Dio>(),
          bookBox: gh<_i979.Box<_i525.BookModel>>(),
          favoritesBox: gh<_i979.Box<String>>(instanceName: 'favorites'),
          progressBox: gh<_i979.Box<int>>(),
          lastReadBox: gh<_i979.Box<DateTime>>(),
          remoteDataSource: gh<_i435.BookRemoteDataSource>(),
          localDataSource: gh<_i386.BookLocalDataSource>(),
        ));
    gh.lazySingleton<_i696.TranslationService>(
        () => _i696.TranslationService(gh<_i474.NetworkManager>()));
    gh.lazySingleton<_i512.QuestsService>(() => _i512.QuestsService(
          gh<_i557.ApiClient>(),
          gh<_i326.CacheManager>(),
        ));
    gh.lazySingleton<_i298.LastReadManager>(() => _i298.LastReadManager(
          gh<_i392.StorageManager>(),
          gh<_i413.BookRepository>(),
        ));
    gh.singleton<_i449.AuthService>(() => _i449.AuthService(
          gh<_i474.NetworkManager>(),
          gh<_i666.SecureStorageService>(),
          gh<_i326.CacheManager>(),
        ));
    gh.singleton<_i689.AchievementManager>(() => _i689.AchievementManager(
          gh<_i361.Dio>(),
          gh<_i474.NetworkManager>(),
          gh<_i326.CacheManager>(),
        ));
    gh.singleton<_i550.SignalRService>(() => _i550.SignalRService(
          gh<_i474.NetworkManager>(),
          gh<_i666.SecureStorageService>(),
        ));
    gh.singleton<_i417.SyncManager>(() => _i417.SyncManager(
          gh<_i392.StorageManager>(),
          gh<_i413.BookRepository>(),
        ));
    return this;
  }
}

class _$DioModule extends _i1045.DioModule {}

class _$StorageModule extends _i371.StorageModule {}

class _$HiveModule extends _i576.HiveModule {}
