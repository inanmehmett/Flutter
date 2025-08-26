import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/reading_quiz_cubit.dart';
import '../widgets/reading_quiz_widgets.dart';
import '../../domain/entities/reading_quiz_models.dart';
import '../../../../core/theme/app_colors.dart';

class ReadingQuizPage extends StatelessWidget {
  final int readingTextId;
  final String bookTitle;

  const ReadingQuizPage({
    Key? key,
    required this.readingTextId,
    required this.bookTitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz: $bookTitle'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<ReadingQuizCubit, ReadingQuizState>(
        builder: (context, state) {
          if (state is ReadingQuizInitial) {
            return ReadingQuizStartView(
              bookTitle: bookTitle,
              onStartQuiz: () {
                context.read<ReadingQuizCubit>().startQuiz(readingTextId);
              },
            );
          } else if (state is ReadingQuizLoading) {
            return const ReadingQuizLoadingView();
          } else if (state is ReadingQuizStarted) {
            return ReadingQuizQuestionView(
              quizData: state.quizData,
              currentQuestion: state.quizData.questions[state.currentQuestionIndex],
              currentQuestionIndex: state.currentQuestionIndex,
              totalQuestions: state.quizData.questions.length,
              progress: context.read<ReadingQuizCubit>().getProgress(),
              remainingTime: context.read<ReadingQuizCubit>().getRemainingTime(),
              onAnswerSelected: (questionId, selectedAnswerId, userAnswerText) {
                context.read<ReadingQuizCubit>().answerQuestion(
                  questionId,
                  selectedAnswerId,
                  userAnswerText,
                );
              },
              onPreviousQuestion: state.currentQuestionIndex > 0 
                ? () => context.read<ReadingQuizCubit>().goToPreviousQuestion()
                : null,
            );
          } else if (state is ReadingQuizCompleted) {
            // Ara ekrana gerek yok; otomatik gönderim yapılır, burada yükleniyor göster
            return const ReadingQuizSubmittingView();
          } else if (state is ReadingQuizSubmitting) {
            return const ReadingQuizSubmittingView();
          } else if (state is ReadingQuizFinished) {
            return ReadingQuizResultView(
              result: state.result,
              onRetakeQuiz: () {
                context.read<ReadingQuizCubit>().resetQuiz();
                context.read<ReadingQuizCubit>().startQuiz(readingTextId);
              },
              onBackToBook: () {
                Navigator.of(context).pop();
              },
            );
          } else if (state is ReadingQuizError) {
            return ReadingQuizErrorView(
              message: state.message,
              onRetry: () {
                context.read<ReadingQuizCubit>().resetQuiz();
                context.read<ReadingQuizCubit>().startQuiz(readingTextId);
              },
              onBack: () {
                Navigator.of(context).pop();
              },
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class ReadingQuizRoute {
  static const String name = '/reading-quiz';
  
  static Route<void> route({
    required int readingTextId,
    required String bookTitle,
  }) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: name),
      builder: (context) => ReadingQuizPage(
        readingTextId: readingTextId,
        bookTitle: bookTitle,
      ),
    );
  }
}
