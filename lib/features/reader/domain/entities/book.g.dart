// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookAdapter extends TypeAdapter<Book> {
  @override
  final int typeId = 0;

  @override
  Book read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Book(
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
      rating: fields[19] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Book obj) {
    writer
      ..writeByte(20)
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
      ..write(obj.rating);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
