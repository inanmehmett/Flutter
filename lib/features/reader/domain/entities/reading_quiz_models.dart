import 'package:equatable/equatable.dart';

/// Reading quiz başlatma response modeli
class ReadingQuizStartResponse extends Equatable {
  final bool success;
  final String message;
  final ReadingQuizData? data;

  const ReadingQuizStartResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ReadingQuizStartResponse.fromJson(Map<String, dynamic> json) {
    return ReadingQuizStartResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null 
          ? ReadingQuizData.fromJson(json['data']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Reading quiz data modeli
class ReadingQuizData extends Equatable {
  final int quizId;
  final int readingTextId;
  final String title;
  final String description;
  final int questionCount;
  final int timeLimitMinutes;
  final int passingScore;
  final List<ReadingQuizQuestion> questions;

  const ReadingQuizData({
    required this.quizId,
    required this.readingTextId,
    required this.title,
    required this.description,
    required this.questionCount,
    required this.timeLimitMinutes,
    required this.passingScore,
    required this.questions,
  });

  factory ReadingQuizData.fromJson(Map<String, dynamic> json) {
    return ReadingQuizData(
      quizId: json['quizId'] as int,
      readingTextId: json['readingTextId'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      questionCount: json['questionCount'] as int,
      timeLimitMinutes: json['timeLimitMinutes'] as int,
      passingScore: json['passingScore'] as int,
      questions: (json['questions'] as List)
          .map((q) => ReadingQuizQuestion.fromJson(q))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [
        quizId,
        readingTextId,
        title,
        description,
        questionCount,
        timeLimitMinutes,
        passingScore,
        questions,
      ];
}

/// Reading quiz soru modeli
class ReadingQuizQuestion extends Equatable {
  final int id;
  final String questionText;
  final String type;
  final int points;
  final List<ReadingQuizAnswer> answers;

  const ReadingQuizQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.points,
    required this.answers,
  });

  factory ReadingQuizQuestion.fromJson(Map<String, dynamic> json) {
    return ReadingQuizQuestion(
      id: json['id'] as int,
      questionText: json['questionText'] as String,
      type: json['type'] as String,
      points: json['points'] as int,
      answers: (json['answers'] as List)
          .map((a) => ReadingQuizAnswer.fromJson(a))
          .toList(),
    );
  }

  ReadingQuizAnswer? get correctAnswer {
    try {
      return answers.firstWhere((answer) => answer.isCorrect);
    } catch (e) {
      return null;
    }
  }

  bool get isMultipleChoice => type == 'MultipleChoice';
  bool get isTrueFalse => type == 'TrueFalse';
  bool get isFillInTheBlank => type == 'FillInTheBlank';

  @override
  List<Object?> get props => [id, questionText, type, points, answers];
}

/// Reading quiz cevap modeli
class ReadingQuizAnswer extends Equatable {
  final int id;
  final String answerText;
  final bool isCorrect;

  const ReadingQuizAnswer({
    required this.id,
    required this.answerText,
    required this.isCorrect,
  });

  factory ReadingQuizAnswer.fromJson(Map<String, dynamic> json) {
    return ReadingQuizAnswer(
      id: json['id'] as int,
      answerText: json['answerText'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  @override
  List<Object?> get props => [id, answerText, isCorrect];
}

/// Kullanıcının verdiği cevap modeli (API'ye gönderilir)
class ReadingQuizUserAnswer extends Equatable {
  final int questionId;
  final int? selectedAnswerId;
  final String? userAnswerText;
  final int timeSpentSeconds;

  const ReadingQuizUserAnswer({
    required this.questionId,
    this.selectedAnswerId,
    this.userAnswerText,
    required this.timeSpentSeconds,
  });

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'selectedAnswerId': selectedAnswerId,
      'userAnswerText': userAnswerText,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  @override
  List<Object?> get props => [questionId, selectedAnswerId, userAnswerText, timeSpentSeconds];
}

/// Quiz tamamlama request modeli
class ReadingQuizCompleteRequest extends Equatable {
  final int quizId;
  final DateTime startedAt;
  final List<ReadingQuizUserAnswer> answers;

  const ReadingQuizCompleteRequest({
    required this.quizId,
    required this.startedAt,
    required this.answers,
  });

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'startedAt': startedAt.toIso8601String(),
      'answers': answers.map((a) => a.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [quizId, startedAt, answers];
}

/// Quiz tamamlama response modeli
class ReadingQuizCompleteResponse extends Equatable {
  final bool success;
  final String message;
  final ReadingQuizResult? data;

  const ReadingQuizCompleteResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ReadingQuizCompleteResponse.fromJson(Map<String, dynamic> json) {
    return ReadingQuizCompleteResponse(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: json['data'] != null 
          ? ReadingQuizResult.fromJson(json['data']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [success, message, data];
}

/// Quiz sonuç modeli
class ReadingQuizResult extends Equatable {
  final int resultId;
  final int score;
  final int correctAnswers;
  final int wrongAnswers; // Eksik field eklendi
  final double percentage;
  final bool isPassed;
  final int xpEarned;
  final int timeSpent;
  final bool levelUp;
  final String? newLevel;
  final int newTotalXP;
  final List<dynamic> rewards;
  final ReadingQuizStreak streak;

  const ReadingQuizResult({
    required this.resultId,
    required this.score,
    required this.correctAnswers,
    required this.wrongAnswers, // Eksik field eklendi
    required this.percentage,
    required this.isPassed,
    required this.xpEarned,
    required this.timeSpent,
    required this.levelUp,
    this.newLevel,
    required this.newTotalXP,
    required this.rewards,
    required this.streak,
  });

  factory ReadingQuizResult.fromJson(Map<String, dynamic> json) {
    return ReadingQuizResult(
      resultId: json['resultId'] as int,
      score: json['score'] as int,
      correctAnswers: json['correctAnswers'] as int,
      wrongAnswers: json['wrongAnswers'] as int? ?? 0, // Default değer eklendi
      percentage: (json['percentage'] as num).toDouble(),
      isPassed: json['isPassed'] as bool,
      xpEarned: json['xpEarned'] as int,
      timeSpent: json['timeSpent'] as int,
      levelUp: json['levelUp'] as bool,
      newLevel: json['newLevel'] as String?,
      newTotalXP: json['newTotalXP'] as int,
      rewards: json['rewards'] as List<dynamic>? ?? [],
      streak: ReadingQuizStreak.fromJson(json['streak'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resultId': resultId,
      'score': score,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'percentage': percentage,
      'isPassed': isPassed,
      'xpEarned': xpEarned,
      'timeSpent': timeSpent,
      'levelUp': levelUp,
      'newLevel': newLevel,
      'newTotalXP': newTotalXP,
      'rewards': rewards,
      'streak': streak.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        resultId,
        score,
        correctAnswers,
        wrongAnswers,
        percentage,
        isPassed,
        xpEarned,
        timeSpent,
        levelUp,
        newLevel,
        newTotalXP,
        rewards,
        streak,
      ];
}

/// Streak modeli
class ReadingQuizStreak extends Equatable {
  final int currentStreak;
  final int longestStreak;
  final int streakBonus;

  const ReadingQuizStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.streakBonus,
  });

  factory ReadingQuizStreak.fromJson(Map<String, dynamic> json) {
    return ReadingQuizStreak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      streakBonus: json['streakBonus'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'streakBonus': streakBonus,
    };
  }

  @override
  List<Object?> get props => [currentStreak, longestStreak, streakBonus];
}

/// Quiz geçmişi modeli
class ReadingQuizHistory extends Equatable {
  final int id;
  final String quizTitle;
  final String readingTextTitle;
  final int score;
  final double percentage;
  final bool isPassed;
  final int xpEarned;
  final int timeSpent;
  final DateTime completedAt;

  const ReadingQuizHistory({
    required this.id,
    required this.quizTitle,
    required this.readingTextTitle,
    required this.score,
    required this.percentage,
    required this.isPassed,
    required this.xpEarned,
    required this.timeSpent,
    required this.completedAt,
  });

  factory ReadingQuizHistory.fromJson(Map<String, dynamic> json) {
    return ReadingQuizHistory(
      id: json['id'] as int,
      quizTitle: json['quizTitle'] as String,
      readingTextTitle: json['readingTextTitle'] as String,
      score: json['score'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      isPassed: json['isPassed'] as bool,
      xpEarned: json['xpEarned'] as int,
      timeSpent: json['timeSpent'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        quizTitle,
        readingTextTitle,
        score,
        percentage,
        isPassed,
        xpEarned,
        timeSpent,
        completedAt,
      ];
}

/// Quiz istatistikleri modeli
class ReadingQuizStats extends Equatable {
  final int totalQuizzes;
  final double averageScore;
  final int totalXPEarned;
  final int passedQuizzes;
  final int totalTimeSpent;
  final double averagePercentage;
  final int bestScore;
  final int fastestQuiz;

  const ReadingQuizStats({
    required this.totalQuizzes,
    required this.averageScore,
    required this.totalXPEarned,
    required this.passedQuizzes,
    required this.totalTimeSpent,
    required this.averagePercentage,
    required this.bestScore,
    required this.fastestQuiz,
  });

  factory ReadingQuizStats.fromJson(Map<String, dynamic> json) {
    return ReadingQuizStats(
      totalQuizzes: json['totalQuizzes'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      totalXPEarned: json['totalXPEarned'] as int,
      passedQuizzes: json['passedQuizzes'] as int,
      totalTimeSpent: json['totalTimeSpent'] as int,
      averagePercentage: (json['averagePercentage'] as num).toDouble(),
      bestScore: json['bestScore'] as int,
      fastestQuiz: json['fastestQuiz'] as int,
    );
  }

  @override
  List<Object?> get props => [
        totalQuizzes,
        averageScore,
        totalXPEarned,
        passedQuizzes,
        totalTimeSpent,
        averagePercentage,
        bestScore,
        fastestQuiz,
      ];
}
