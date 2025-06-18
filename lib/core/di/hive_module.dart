import 'package:injectable/injectable.dart';
import 'package:hive/hive.dart';
import '../../features/reader/data/models/book_model.dart';

@module
abstract class HiveModule {
  @singleton
  Box<BookModel> get bookBox => Hive.box<BookModel>('books');

  @Named('favorites')
  @singleton
  Box<String> get favoritesBox => Hive.box<String>('favorites');

  @singleton
  Box<int> get progressBox => Hive.box<int>('progress');

  @singleton
  Box<DateTime> get lastReadBox => Hive.box<DateTime>('last_read');

  @Named('app_cache')
  @singleton
  Box<String> get appCacheBox => Hive.box<String>('app_cache');
}
