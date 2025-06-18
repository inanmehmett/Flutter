// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResponse _$ApiResponseFromJson(Map<String, dynamic> json) => ApiResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => MobileBook.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ApiResponseToJson(ApiResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'count': instance.count,
    };

ApiDetailResponse _$ApiDetailResponseFromJson(Map<String, dynamic> json) =>
    ApiDetailResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: MobileBook.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ApiDetailResponseToJson(ApiDetailResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

MobileBook _$MobileBookFromJson(Map<String, dynamic> json) => MobileBook(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      author: json['author'] as String?,
      summary: json['summary'] as String?,
      textLevel: json['textLevel'] as String?,
      textLanguage: json['textLanguage'] as String?,
      translationLanguage: json['translationLanguage'] as String?,
      estimatedReadingTimeInMinutes:
          (json['estimatedReadingTimeInMinutes'] as num).toInt(),
      wordCount: (json['wordCount'] as num?)?.toInt(),
      iconUrl: json['iconUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
      createdAt: json['createdAt'] as String?,
      slug: json['slug'] as String?,
      chapters: (json['chapters'] as List<dynamic>?)
          ?.map((e) => MobileChapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      originalText: json['originalText'] as String?,
      translation: json['translation'] as String?,
      isActive: json['isActive'] as bool?,
    );

Map<String, dynamic> _$MobileBookToJson(MobileBook instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'summary': instance.summary,
      'textLevel': instance.textLevel,
      'textLanguage': instance.textLanguage,
      'translationLanguage': instance.translationLanguage,
      'estimatedReadingTimeInMinutes': instance.estimatedReadingTimeInMinutes,
      'wordCount': instance.wordCount,
      'iconUrl': instance.iconUrl,
      'imageUrl': instance.imageUrl,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'createdAt': instance.createdAt,
      'slug': instance.slug,
      'chapters': instance.chapters,
      'originalText': instance.originalText,
      'translation': instance.translation,
      'isActive': instance.isActive,
    };

MobileChapter _$MobileChapterFromJson(Map<String, dynamic> json) =>
    MobileChapter(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      text: json['text'] as String,
      chapterNumber: (json['chapterNumber'] as num).toInt(),
      translation: json['translation'] as String,
    );

Map<String, dynamic> _$MobileChapterToJson(MobileChapter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'text': instance.text,
      'chapterNumber': instance.chapterNumber,
      'translation': instance.translation,
    };
