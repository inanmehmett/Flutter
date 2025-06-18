import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/book.dart';

part 'api_response.g.dart';

@JsonSerializable()
class ApiResponse {
  final bool success;
  final String message;
  final List<MobileBook> data;
  final int? count;

  ApiResponse({
    required this.success,
    required this.message,
    required this.data,
    this.count,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ApiResponseToJson(this);
}

@JsonSerializable()
class ApiDetailResponse {
  final bool success;
  final String message;
  final MobileBook data;

  ApiDetailResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ApiDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiDetailResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ApiDetailResponseToJson(this);
}

@JsonSerializable()
class MobileBook {
  final int id;
  final String title;
  final String? author;
  final String? summary;
  final String? textLevel;
  final String? textLanguage;
  final String? translationLanguage;
  final int estimatedReadingTimeInMinutes;
  final int? wordCount;
  final String? iconUrl;
  final String? imageUrl;
  final int? categoryId;
  final String? categoryName;
  final String? createdAt;
  final String? slug;
  final List<MobileChapter>? chapters;
  final String? originalText;
  final String? translation;
  final bool? isActive;

  MobileBook({
    required this.id,
    required this.title,
    this.author,
    this.summary,
    this.textLevel,
    this.textLanguage,
    this.translationLanguage,
    required this.estimatedReadingTimeInMinutes,
    this.wordCount,
    this.iconUrl,
    this.imageUrl,
    this.categoryId,
    this.categoryName,
    this.createdAt,
    this.slug,
    this.chapters,
    this.originalText,
    this.translation,
    this.isActive,
  });

  factory MobileBook.fromJson(Map<String, dynamic> json) =>
      _$MobileBookFromJson(json);
  Map<String, dynamic> toJson() => _$MobileBookToJson(this);

  Book toBook() {
    final bookText = originalText ?? chapters?.first.text ?? '';
    final bookTranslation = translation ?? chapters?.first.translation;
    final level = textLevel ?? '1';

    return Book(
      id: id.toString(),
      title: title,
      author: author ?? '',
      content: bookText,
      translation: bookTranslation,
      summary: summary,
      textLevel: level,
      textLanguage: textLanguage ?? 'en',
      translationLanguage: translationLanguage ?? 'tr',
      estimatedReadingTimeInMinutes: estimatedReadingTimeInMinutes,
      wordCount: wordCount,
      isActive: isActive ?? true,
      categoryId: categoryId,
      categoryName: categoryName,
      createdAt:
          createdAt != null ? DateTime.parse(createdAt!) : DateTime.now(),
      updatedAt: DateTime.now(),
      imageUrl: imageUrl,
      iconUrl: iconUrl,
      slug: slug,
    );
  }
}

@JsonSerializable()
class MobileChapter {
  final int id;
  final String title;
  final String text;
  final int chapterNumber;
  final String translation;

  MobileChapter({
    required this.id,
    required this.title,
    required this.text,
    required this.chapterNumber,
    required this.translation,
  });

  factory MobileChapter.fromJson(Map<String, dynamic> json) =>
      _$MobileChapterFromJson(json);
  Map<String, dynamic> toJson() => _$MobileChapterToJson(this);
}
