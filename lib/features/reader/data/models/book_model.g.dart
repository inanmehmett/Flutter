// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookModelAdapter extends TypeAdapter<BookModel> {
  @override
  final int typeId = 0;

  @override
  BookModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookModel(
      id: fields[0] as String,
      title: fields[1] as String,
      author: fields[2] as String,
      content: fields[3] as String,
      translation: fields[4] as String?,
      summary: fields[5] as String?,
      textLevel: fields[6] as String?,
      textLanguage: fields[7] as String,
      translationLanguage: fields[8] as String,
      estimatedReadingTimeInMinutes: fields[9] as int,
      wordCount: fields[10] as int?,
      isActive: fields[11] as bool,
      categoryId: fields[12] as int?,
      categoryName: fields[13] as String?,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
      imageUrl: fields[16] as String?,
      iconUrl: fields[17] as String?,
      slug: fields[18] as String?,
      syncState: fields[19] as SyncState,
      lastSyncDate: fields[20] as DateTime?,
      lastModifiedDate: fields[21] as DateTime?,
      rating: fields[22] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, BookModel obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.author)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.translation)
      ..writeByte(5)
      ..write(obj.summary)
      ..writeByte(6)
      ..write(obj.textLevel)
      ..writeByte(7)
      ..write(obj.textLanguage)
      ..writeByte(8)
      ..write(obj.translationLanguage)
      ..writeByte(9)
      ..write(obj.estimatedReadingTimeInMinutes)
      ..writeByte(10)
      ..write(obj.wordCount)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.categoryId)
      ..writeByte(13)
      ..write(obj.categoryName)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.imageUrl)
      ..writeByte(17)
      ..write(obj.iconUrl)
      ..writeByte(18)
      ..write(obj.slug)
      ..writeByte(19)
      ..write(obj.syncState)
      ..writeByte(20)
      ..write(obj.lastSyncDate)
      ..writeByte(21)
      ..write(obj.lastModifiedDate)
      ..writeByte(22)
      ..write(obj.rating);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookModel _$BookModelFromJson(Map<String, dynamic> json) => BookModel(
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
          (json['estimatedReadingTimeInMinutes'] as num).toInt(),
      wordCount: (json['wordCount'] as num?)?.toInt(),
      isActive: json['isActive'] as bool,
      categoryId: (json['categoryId'] as num?)?.toInt(),
      categoryName: json['categoryName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      imageUrl: json['imageUrl'] as String?,
      iconUrl: json['iconUrl'] as String?,
      slug: json['slug'] as String?,
      syncState: $enumDecodeNullable(_$SyncStateEnumMap, json['syncState']) ??
          SyncState.synced,
      lastSyncDate: json['lastSyncDate'] == null
          ? null
          : DateTime.parse(json['lastSyncDate'] as String),
      lastModifiedDate: json['lastModifiedDate'] == null
          ? null
          : DateTime.parse(json['lastModifiedDate'] as String),
      rating: (json['rating'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$BookModelToJson(BookModel instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'content': instance.content,
      'translation': instance.translation,
      'summary': instance.summary,
      'textLevel': instance.textLevel,
      'textLanguage': instance.textLanguage,
      'translationLanguage': instance.translationLanguage,
      'estimatedReadingTimeInMinutes': instance.estimatedReadingTimeInMinutes,
      'wordCount': instance.wordCount,
      'isActive': instance.isActive,
      'categoryId': instance.categoryId,
      'categoryName': instance.categoryName,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'imageUrl': instance.imageUrl,
      'iconUrl': instance.iconUrl,
      'slug': instance.slug,
      'syncState': _$SyncStateEnumMap[instance.syncState]!,
      'lastSyncDate': instance.lastSyncDate?.toIso8601String(),
      'lastModifiedDate': instance.lastModifiedDate.toIso8601String(),
      'rating': instance.rating,
    };

const _$SyncStateEnumMap = {
  SyncState.synced: 'synced',
  SyncState.updated: 'updated',
  SyncState.deleted: 'deleted',
  SyncState.pending: 'pending',
};
