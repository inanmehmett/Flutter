// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_word.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserWordModelAdapter extends TypeAdapter<UserWordModel> {
  @override
  final int typeId = 41;

  @override
  UserWordModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserWordModel(
      id: fields[0] as String,
      word: fields[1] as String,
      meaningTr: fields[2] as String,
      example: fields[3] as String?,
      partOfSpeech: fields[4] as String?,
      cefr: fields[5] as String?,
      progress: fields[6] as int,
      addedAt: fields[7] as DateTime,
      sourceBookId: fields[8] as String?,
      sourceChapter: fields[9] as String?,
      tags: (fields[10] as List).cast<String>(),
      description: fields[11] as String?,
      audioUrl: fields[12] as String?,
      imageUrl: fields[13] as String?,
      category: fields[14] as String?,
      synonyms: (fields[15] as List).cast<String>(),
      antonyms: (fields[16] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserWordModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.word)
      ..writeByte(2)
      ..write(obj.meaningTr)
      ..writeByte(3)
      ..write(obj.example)
      ..writeByte(4)
      ..write(obj.partOfSpeech)
      ..writeByte(5)
      ..write(obj.cefr)
      ..writeByte(6)
      ..write(obj.progress)
      ..writeByte(7)
      ..write(obj.addedAt)
      ..writeByte(8)
      ..write(obj.sourceBookId)
      ..writeByte(9)
      ..write(obj.sourceChapter)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.description)
      ..writeByte(12)
      ..write(obj.audioUrl)
      ..writeByte(13)
      ..write(obj.imageUrl)
      ..writeByte(14)
      ..write(obj.category)
      ..writeByte(15)
      ..write(obj.synonyms)
      ..writeByte(16)
      ..write(obj.antonyms);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserWordModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
