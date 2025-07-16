import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/book.dart';
import '../../../../core/sync/sync_state.dart';
import '../../../../core/config/app_config.dart';

part 'book_model.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class BookModel extends HiveObject implements Book {
  @HiveField(0)
  @override
  final String id;

  @HiveField(1)
  @override
  final String title;

  @HiveField(2)
  @override
  final String author;

  @HiveField(3)
  @override
  final String content;

  @HiveField(4)
  @override
  final String? translation;

  @HiveField(5)
  @override
  final String? summary;

  @HiveField(6)
  @override
  final String? textLevel;

  @HiveField(7)
  @override
  final String textLanguage;

  @HiveField(8)
  @override
  final String translationLanguage;

  @HiveField(9)
  @override
  final int estimatedReadingTimeInMinutes;

  @HiveField(10)
  @override
  final int? wordCount;

  @HiveField(11)
  @override
  final bool isActive;

  @HiveField(12)
  @override
  final int? categoryId;

  @HiveField(13)
  @override
  final String? categoryName;

  @HiveField(14)
  @override
  final DateTime createdAt;

  @HiveField(15)
  @override
  final DateTime updatedAt;

  @HiveField(16)
  @override
  final String? imageUrl;

  @HiveField(17)
  @override
  final String? iconUrl;

  @HiveField(18)
  @override
  final String? slug;

  @HiveField(19)
  SyncState syncState;

  @HiveField(20)
  final DateTime? lastSyncDate;

  @HiveField(21)
  final DateTime lastModifiedDate;

  @HiveField(22)
  @override
  final double? rating;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    this.translation,
    this.summary,
    this.textLevel,
    required this.textLanguage,
    required this.translationLanguage,
    required this.estimatedReadingTimeInMinutes,
    this.wordCount,
    required this.isActive,
    this.categoryId,
    this.categoryName,
    required this.createdAt,
    required this.updatedAt,
    this.imageUrl,
    this.iconUrl,
    this.slug,
    this.syncState = SyncState.synced,
    this.lastSyncDate,
    DateTime? lastModifiedDate,
    this.rating,
  }) : lastModifiedDate = lastModifiedDate ?? DateTime.now();

  factory BookModel.fromJson(Map<String, dynamic> json) {
    print('📚 [BookModel] Parsing JSON: ${json.keys.toList()}');
    
    // Icon URL'yi tam URL'ye çevir
    String? processIconUrl(String? iconUrl) {
      if (iconUrl == null || iconUrl.isEmpty) return null;
      if (iconUrl.startsWith('http://') || iconUrl.startsWith('https://')) {
        return iconUrl;
      }
      if (iconUrl.startsWith('file://')) {
        return iconUrl.replaceFirst('file://', AppConfig.apiBaseUrl);
      }
      if (iconUrl.startsWith('/')) {
        return '${AppConfig.apiBaseUrl}$iconUrl';
      }
      return '${AppConfig.apiBaseUrl}/$iconUrl';
    }
    
    return BookModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      content: json['originalText']?.toString() ?? json['content']?.toString() ?? '',
      translation: json['translation']?.toString(),
      summary: json['summary']?.toString(),
      textLevel: json['textLevel']?.toString(),
      textLanguage: json['textLanguage']?.toString() ?? 'en',
      translationLanguage: json['translationLanguage']?.toString() ?? 'tr',
      estimatedReadingTimeInMinutes: json['estimatedReadingTimeInMinutes'] as int? ?? 1,
      wordCount: json['wordCount'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName']?.toString(),
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      imageUrl: json['imageUrl']?.toString(),
      iconUrl: processIconUrl(json['iconUrl']?.toString()),
      slug: json['slug']?.toString(),
      syncState: SyncState.values.firstWhere(
        (state) => state.toString() == json['syncState'],
        orElse: () => SyncState.synced,
      ),
      lastSyncDate: json['lastSyncDate'] != null
          ? DateTime.tryParse(json['lastSyncDate'].toString())
          : null,
      rating: json['rating'] as double?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'content': content,
      'translation': translation,
      'summary': summary,
      'textLevel': textLevel,
      'textLanguage': textLanguage,
      'translationLanguage': translationLanguage,
      'estimatedReadingTimeInMinutes': estimatedReadingTimeInMinutes,
      'wordCount': wordCount,
      'isActive': isActive,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imageUrl': imageUrl,
      'iconUrl': iconUrl,
      'slug': slug,
      'syncState': syncState.toString(),
      'lastSyncDate': lastSyncDate?.toIso8601String(),
      'rating': rating,
    };
  }

  factory BookModel.fromBook(Book book) {
    return BookModel(
      id: book.id,
      title: book.title,
      author: book.author,
      content: book.content,
      translation: book.translation,
      summary: book.summary,
      textLevel: book.textLevel,
      textLanguage: book.textLanguage,
      translationLanguage: book.translationLanguage,
      estimatedReadingTimeInMinutes: book.estimatedReadingTimeInMinutes,
      wordCount: book.wordCount,
      isActive: book.isActive,
      categoryId: book.categoryId,
      categoryName: book.categoryName,
      createdAt: book.createdAt,
      updatedAt: book.updatedAt,
      imageUrl: book.imageUrl,
      iconUrl: book.iconUrl,
      slug: book.slug,
      rating: book.rating,
    );
  }

  @override
  BookModel copyWith({
    String? id,
    String? title,
    String? author,
    String? content,
    String? translation,
    String? summary,
    String? textLevel,
    String? textLanguage,
    String? translationLanguage,
    int? estimatedReadingTimeInMinutes,
    int? wordCount,
    bool? isActive,
    int? categoryId,
    String? categoryName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
    String? iconUrl,
    String? slug,
    double? rating,
  }) {
    return BookModel(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      content: content ?? this.content,
      translation: translation ?? this.translation,
      summary: summary ?? this.summary,
      textLevel: textLevel ?? this.textLevel,
      textLanguage: textLanguage ?? this.textLanguage,
      translationLanguage: translationLanguage ?? this.translationLanguage,
      estimatedReadingTimeInMinutes:
          estimatedReadingTimeInMinutes ?? this.estimatedReadingTimeInMinutes,
      wordCount: wordCount ?? this.wordCount,
      isActive: isActive ?? this.isActive,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      slug: slug ?? this.slug,
      syncState: syncState,
      lastSyncDate: lastSyncDate,
      lastModifiedDate: lastModifiedDate,
      rating: rating ?? this.rating,
    );
  }

  @override
  bool? get stringify => true;

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        content,
        translation,
        summary,
        textLevel,
        textLanguage,
        translationLanguage,
        estimatedReadingTimeInMinutes,
        wordCount,
        isActive,
        categoryId,
        categoryName,
        createdAt,
        updatedAt,
        imageUrl,
        iconUrl,
        slug,
        rating,
      ];

  Book toEntity() {
    return Book(
      id: id,
      title: title,
      author: author,
      content: content,
      translation: translation,
      summary: summary,
      textLevel: textLevel,
      textLanguage: textLanguage,
      translationLanguage: translationLanguage,
      estimatedReadingTimeInMinutes: estimatedReadingTimeInMinutes,
      wordCount: wordCount,
      isActive: isActive,
      categoryId: categoryId,
      categoryName: categoryName,
      createdAt: createdAt,
      updatedAt: updatedAt,
      imageUrl: imageUrl,
      iconUrl: iconUrl,
      slug: slug,
      rating: rating,
    );
  }
}
