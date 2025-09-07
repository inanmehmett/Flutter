import 'package:equatable/equatable.dart';

/// Vocabulary Quiz specific models for English-Turkish word quizzes
class VocabularyQuizQuestion extends Equatable {
  final int id;
  final String originalWord;
  final String translatedWord;
  final List<VocabularyQuizOption> options;
  final String difficulty;
  final String category;
  final int timeLimitSeconds;

  const VocabularyQuizQuestion({
    required this.id,
    required this.originalWord,
    required this.translatedWord,
    required this.options,
    required this.difficulty,
    required this.category,
    this.timeLimitSeconds = 10,
  });

  factory VocabularyQuizQuestion.fromJson(Map<String, dynamic> json) {
    return VocabularyQuizQuestion(
      id: json['id'] as int,
      originalWord: json['originalWord'] as String? ?? '',
      translatedWord: json['translatedWord'] as String? ?? '',
      options: (json['options'] as List)
          .map((option) => VocabularyQuizOption.fromJson(option))
          .toList(),
      difficulty: json['difficulty'] as String? ?? 'medium',
      category: json['category'] as String? ?? 'general',
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 10,
    );
  }

  factory VocabularyQuizQuestion.fromBackendJson(Map<String, dynamic> json) {
    // Backend'den gelen format: text field'ında soru, options'da şıklar
    final text = json['text'] as String;
    final originalWord = _extractOriginalWord(text);
    
    return VocabularyQuizQuestion(
      id: json['id'] as int,
      originalWord: originalWord,
      translatedWord: '', // Backend'de doğru cevap options içinde
      options: (json['options'] as List)
          .map((option) => VocabularyQuizOption.fromJson(option))
          .toList(),
      difficulty: json['difficulty'] as String? ?? 'medium',
      category: json['category'] as String? ?? 'general',
      timeLimitSeconds: 10,
    );
  }

  static String _extractOriginalWord(String text) {
    // "'hello' kelimesinin Türkçe karşılığı nedir?" -> "hello"
    final regex = RegExp(r"'([^']+)'");
    final match = regex.firstMatch(text);
    return match?.group(1) ?? '';
  }

  VocabularyQuizOption? get correctOption =>
      options.firstWhere((option) => option.isCorrect);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'originalWord': originalWord,
      'translatedWord': translatedWord,
      'options': options.map((option) => option.toJson()).toList(),
      'difficulty': difficulty,
      'category': category,
      'timeLimitSeconds': timeLimitSeconds,
    };
  }

  @override
  List<Object?> get props => [
        id,
        originalWord,
        translatedWord,
        options,
        difficulty,
        category,
        timeLimitSeconds,
      ];
}

class VocabularyQuizOption extends Equatable {
  final int id;
  final String text;
  final bool isCorrect;

  const VocabularyQuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory VocabularyQuizOption.fromJson(Map<String, dynamic> json) {
    return VocabularyQuizOption(
      id: json['id'] as int,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCorrect': isCorrect,
    };
  }

  @override
  List<Object?> get props => [id, text, isCorrect];
}

class VocabularyQuizAnswer extends Equatable {
  final int questionId;
  final String userAnswer;
  final bool isCorrect;
  final int timeSpentSeconds;
  final DateTime answeredAt;

  const VocabularyQuizAnswer({
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.timeSpentSeconds,
    required this.answeredAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'timeSpentSeconds': timeSpentSeconds,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        questionId,
        userAnswer,
        isCorrect,
        timeSpentSeconds,
        answeredAt,
      ];
}

class VocabularyQuizCompletionRequest extends Equatable {
  final int quizId;
  final List<VocabularyQuizAnswer> answers;
  final int completionTimeMinutes;
  final bool isFirstAttempt;
  final int vocabularyQuizScore;
  final int vocabularyCorrectAnswers;
  final int vocabularyTotalQuestions;

  const VocabularyQuizCompletionRequest({
    required this.quizId,
    required this.answers,
    required this.completionTimeMinutes,
    this.isFirstAttempt = true,
    required this.vocabularyQuizScore,
    required this.vocabularyCorrectAnswers,
    required this.vocabularyTotalQuestions,
  });

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'completionTimeMinutes': completionTimeMinutes,
      'isFirstAttempt': isFirstAttempt,
      'vocabularyQuizScore': vocabularyQuizScore,
      'vocabularyCorrectAnswers': vocabularyCorrectAnswers,
      'vocabularyTotalQuestions': vocabularyTotalQuestions,
    };
  }

  @override
  List<Object?> get props => [
        quizId,
        answers,
        completionTimeMinutes,
        isFirstAttempt,
        vocabularyQuizScore,
        vocabularyCorrectAnswers,
        vocabularyTotalQuestions,
      ];
}

class VocabularyQuizResult extends Equatable {
  final int quizScore;
  final bool isPassed;
  final int xpEarned;
  final int newTotalXP;
  final bool levelUp;
  final String? newLevel;
  final List<String> rewards;
  final VocabularyQuizStreak streak;

  const VocabularyQuizResult({
    required this.quizScore,
    required this.isPassed,
    required this.xpEarned,
    required this.newTotalXP,
    required this.levelUp,
    this.newLevel,
    required this.rewards,
    required this.streak,
  });

  factory VocabularyQuizResult.fromJson(Map<String, dynamic> json) {
    return VocabularyQuizResult(
      quizScore: json['quizScore'] as int,
      isPassed: json['isPassed'] as bool,
      xpEarned: json['xpEarned'] as int,
      newTotalXP: json['newTotalXP'] as int,
      levelUp: json['levelUp'] as bool,
      newLevel: json['newLevel'] as String?,
      rewards: (json['rewards'] as List?)?.cast<String>() ?? [],
      streak: VocabularyQuizStreak.fromJson(json['streak']),
    );
  }

  @override
  List<Object?> get props => [
        quizScore,
        isPassed,
        xpEarned,
        newTotalXP,
        levelUp,
        newLevel,
        rewards,
        streak,
      ];
}

class VocabularyQuizStreak extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final int streakBonus;

  const VocabularyQuizStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.streakBonus,
  });

  factory VocabularyQuizStreak.fromJson(Map<String, dynamic> json) {
    return VocabularyQuizStreak(
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      streakBonus: json['streakBonus'] as int,
    );
  }

  @override
  List<Object?> get props => [currentStreak, longestStreak, streakBonus];
}

class VocabularyQuizProgress extends Equatable {
  final int currentQuestion;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double percentage;
  final int timeSpent;

  const VocabularyQuizProgress({
    required this.currentQuestion,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.percentage,
    required this.timeSpent,
  });

  @override
  List<Object?> get props => [
        currentQuestion,
        totalQuestions,
        correctAnswers,
        wrongAnswers,
        percentage,
        timeSpent,
      ];
}
