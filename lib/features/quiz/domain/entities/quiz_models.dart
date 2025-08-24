import 'package:equatable/equatable.dart';

class QuizQuestion extends Equatable {
  final int id;
  final String text;
  final List<QuizOption> options;
  final String difficulty;
  final String category;

  const QuizQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.difficulty,
    required this.category,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as int,
      text: json['text'] as String,
      options: (json['options'] as List)
          .map((option) => QuizOption.fromJson(option))
          .toList(),
      difficulty: json['difficulty'] as String,
      category: json['category'] as String,
    );
  }

  factory QuizQuestion.fromReadingQuizJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as int,
      text: json['questionText'] as String, // Backend'de questionText olarak geliyor
      options: (json['answers'] as List) // Backend'de answers olarak geliyor
          .map((option) => QuizOption.fromReadingQuizJson(option))
          .toList(),
      difficulty: 'medium', // Reading quiz'de difficulty bilgisi yok
      category: 'reading', // Reading quiz kategorisi
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'options': options.map((option) => option.toJson()).toList(),
      'difficulty': difficulty,
      'category': category,
    };
  }

  QuizOption? get correctOption =>
      options.firstWhere((option) => option.isCorrect);

  @override
  List<Object?> get props => [id, text, options, difficulty, category];
}

class QuizOption extends Equatable {
  final int id;
  final String text;
  final bool isCorrect;

  const QuizOption({
    required this.id,
    required this.text,
    required this.isCorrect,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] as int,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool,
    );
  }

  factory QuizOption.fromReadingQuizJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] as int,
      text: json['answerText'] as String, // Backend'de answerText olarak geliyor
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

class AnswerResult extends Equatable {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;

  const AnswerResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    return AnswerResult(
      isCorrect: json['isCorrect'] as bool,
      correctAnswer: json['correctAnswer'] as String,
      explanation: json['explanation'] as String,
    );
  }

  @override
  List<Object?> get props => [isCorrect, correctAnswer, explanation];
}

class QuizResult extends Equatable {
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final double percentage;
  final List<QuestionResult> questionResults;

  const QuizResult({
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.percentage,
    required this.questionResults,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      correctAnswers: json['correctAnswers'] as int,
      wrongAnswers: json['wrongAnswers'] as int,
      percentage: (json['percentage'] as num).toDouble(),
      questionResults: (json['questionResults'] as List)
          .map((result) => QuestionResult.fromJson(result))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'percentage': percentage,
      'questionResults': questionResults.map((result) => result.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        score,
        totalQuestions,
        correctAnswers,
        wrongAnswers,
        percentage,
        questionResults,
      ];
}

class QuestionResult extends Equatable {
  final QuizQuestion question;
  final QuizOption selectedOption;
  final bool isCorrect;

  const QuestionResult({
    required this.question,
    required this.selectedOption,
    required this.isCorrect,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestionResult(
      question: QuizQuestion.fromJson(json['question']),
      selectedOption: QuizOption.fromJson(json['selectedOption']),
      isCorrect: json['isCorrect'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question.toJson(),
      'selectedOption': selectedOption.toJson(),
      'isCorrect': isCorrect,
    };
  }

  @override
  List<Object?> get props => [question, selectedOption, isCorrect];
}
