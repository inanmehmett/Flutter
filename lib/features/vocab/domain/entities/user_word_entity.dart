// UserWordEntity represents a vocabulary item saved by the user
import 'package:equatable/equatable.dart';

class UserWordEntity extends Equatable {
  final String id; // uuid
  final String word;
  final String meaningTr;
  final String? example;
  final String? partOfSpeech; // noun/verb/adj
  final String? cefr; // A1..C2
  final int progress; // 0 new, 1 learning, 2 learned
  final DateTime addedAt;
  final String? sourceBookId;
  final String? sourceChapter;
  final List<String> tags;
  final String? description; // backend Vocabulary.Description
  final String? audioUrl; // backend Vocabulary.AudioUrl
  final String? imageUrl; // backend Vocabulary.ImageUrl
  final String? category; // backend Vocabulary.Category (as string)
  final List<String> synonyms; // WordSynonym.Text list
  final List<String> antonyms; // WordAntonym.Text list

  const UserWordEntity({
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

  UserWordEntity copyWith({
    String? id,
    String? word,
    String? meaningTr,
    String? example,
    String? partOfSpeech,
    String? cefr,
    int? progress,
    DateTime? addedAt,
    String? sourceBookId,
    String? sourceChapter,
    List<String>? tags,
    String? description,
    String? audioUrl,
    String? imageUrl,
    String? category,
    List<String>? synonyms,
    List<String>? antonyms,
  }) {
    return UserWordEntity(
      id: id ?? this.id,
      word: word ?? this.word,
      meaningTr: meaningTr ?? this.meaningTr,
      example: example ?? this.example,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      cefr: cefr ?? this.cefr,
      progress: progress ?? this.progress,
      addedAt: addedAt ?? this.addedAt,
      sourceBookId: sourceBookId ?? this.sourceBookId,
      sourceChapter: sourceChapter ?? this.sourceChapter,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      synonyms: synonyms ?? this.synonyms,
      antonyms: antonyms ?? this.antonyms,
    );
  }

  @override
  List<Object?> get props => [id, word, meaningTr, example, partOfSpeech, cefr, progress, addedAt, sourceBookId, sourceChapter, tags, description, audioUrl, imageUrl, category, synonyms, antonyms];
}
