import 'package:hive/hive.dart';

part 'user_word.g.dart';

@HiveType(typeId: 41)
class UserWordModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String word;
  @HiveField(2)
  String meaningTr;
  @HiveField(3)
  String? example;
  @HiveField(4)
  String? partOfSpeech;
  @HiveField(5)
  String? cefr;
  @HiveField(6)
  int progress; // 0..2
  @HiveField(7)
  DateTime addedAt;
  @HiveField(8)
  String? sourceBookId;
  @HiveField(9)
  String? sourceChapter;
  @HiveField(10)
  List<String> tags;
  @HiveField(11)
  String? description;
  @HiveField(12)
  String? audioUrl;
  @HiveField(13)
  String? imageUrl;
  @HiveField(14)
  String? category;
  @HiveField(15)
  List<String> synonyms;
  @HiveField(16)
  List<String> antonyms;

  UserWordModel({
    required this.id,
    required this.word,
    required this.meaningTr,
    this.example,
    this.partOfSpeech,
    this.cefr,
    this.progress = 0,
    required this.addedAt,
    this.sourceBookId,
    this.sourceChapter,
    this.tags = const [],
    this.description,
    this.audioUrl,
    this.imageUrl,
    this.category,
    this.synonyms = const [],
    this.antonyms = const [],
  });
}
