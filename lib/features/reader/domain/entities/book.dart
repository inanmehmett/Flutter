import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'book.g.dart';

@HiveType(typeId: 0)
class Book extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String author;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final String? translation;

  @HiveField(5)
  final String? summary;

  @HiveField(6)
  final String? textLevel;

  @HiveField(7)
  final String textLanguage;

  @HiveField(8)
  final String translationLanguage;

  @HiveField(9)
  final int estimatedReadingTimeInMinutes;

  @HiveField(10)
  final int? wordCount;

  @HiveField(11)
  final bool isActive;

  @HiveField(12)
  final int? categoryId;

  @HiveField(13)
  final String? categoryName;

  @HiveField(14)
  final DateTime createdAt;

  @HiveField(15)
  final DateTime updatedAt;

  @HiveField(16)
  final String? imageUrl;

  @HiveField(17)
  final String? iconUrl;

  @HiveField(18)
  final String? slug;

  @HiveField(19)
  final double? rating;

  const Book({
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
    this.rating,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      content: json['content'] as String,
      translation: json['translation'] as String?,
      summary: json['summary'] as String?,
      textLevel: json['textLevel'] as String?,
      textLanguage: json['textLanguage'] as String,
      translationLanguage: json['translationLanguage'] as String,
      estimatedReadingTimeInMinutes:
          json['estimatedReadingTimeInMinutes'] as int,
      wordCount: json['wordCount'] as int?,
      isActive: json['isActive'] as bool,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      iconUrl: json['iconUrl'] as String?,
      slug: json['slug'] as String?,
      rating: json['rating'] as double?,
    );
  }

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
      'rating': rating,
    };
  }

  Book copyWith({
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
    return Book(
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
      rating: rating ?? this.rating,
    );
  }

  factory Book.empty() {
    final now = DateTime.now();
    return Book(
      id: '',
      title: '',
      author: '',
      content: '',
      textLevel: '1',
      textLanguage: '',
      translationLanguage: '',
      estimatedReadingTimeInMinutes: 0,
      isActive: false,
      categoryId: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

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
}
