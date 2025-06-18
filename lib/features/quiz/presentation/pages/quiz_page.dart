import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/quiz_cubit.dart';
import '../cubit/quiz_state.dart' as state_;
import '../widgets/quiz_start_view.dart';
import '../widgets/quiz_question_view.dart';
import '../widgets/quiz_answered_view.dart';
import '../widgets/quiz_result_view.dart';
import '../widgets/quiz_error_view.dart';
import '../widgets/quiz_loading_view.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz App'),
        centerTitle: true,
      ),
      body: BlocBuilder<QuizCubit, state_.QuizState>(
        builder: (context, quizState) {
          if (quizState is state_.QuizInitial) {
            return const QuizStartView();
          } else if (quizState is state_.QuizLoading) {
            return const QuizLoadingView();
          } else if (quizState is state_.QuizQuestionState) {
            return QuizQuestionView(
              question: quizState.question,
              selectedOption: quizState.selectedOption,
              onOptionSelected: (option) {
                context.read<QuizCubit>().selectOption(option);
                context.read<QuizCubit>().checkAnswer();
              },
            );
          } else if (quizState is state_.QuizAnswered) {
            return QuizAnsweredView(
              question: quizState.question,
              selectedOption: quizState.selectedOption,
              result: quizState.result,
              onNext: () => context.read<QuizCubit>().nextQuestion(),
            );
          } else if (quizState is state_.QuizResultState) {
            return QuizResultView(
              result: quizState.result,
              onRestart: () => context.read<QuizCubit>().startQuiz(),
            );
          } else if (quizState is state_.QuizError) {
            return QuizErrorView(
              errorMessage: quizState.message,
              onRetry: () => context.read<QuizCubit>().startQuiz(),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
