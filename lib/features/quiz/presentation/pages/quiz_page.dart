import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
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

  Widget _buildModernHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      color: AppColors.background,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.accent],
            ),
            borderRadius: BorderRadius.circular(AppRadius.cardRadius),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz',
                      style: AppTypography.title1.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.quiz_rounded,
                          size: 18,
                          color: AppColors.textQuaternary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'İngilizce bilginizi test edin',
                            style: AppTypography.subhead.copyWith(
                              color: AppColors.textQuaternary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuizCubit, state_.QuizState>(
      builder: (context, quizState) {
        if (quizState is state_.QuizInitial) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _buildModernHeader(),
                const Expanded(child: QuizStartView()),
              ],
            ),
          );
        } else if (quizState is state_.QuizLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _buildModernHeader(),
                const Expanded(child: QuizLoadingView()),
              ],
            ),
          );
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
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _buildModernHeader(),
                Expanded(
                  child: QuizAnsweredView(
                    question: quizState.question,
                    selectedOption: quizState.selectedOption,
                    result: quizState.result,
                    onNext: () => context.read<QuizCubit>().nextQuestion(),
                  ),
                ),
              ],
            ),
          );
        } else if (quizState is state_.QuizResultState) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _buildModernHeader(),
                Expanded(
                  child: QuizResultView(
                    result: quizState.result,
                    onRestart: () => context.read<QuizCubit>().restartQuiz(),
                  ),
                ),
              ],
            ),
          );
        } else if (quizState is state_.QuizError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _buildModernHeader(),
                Expanded(
                  child: QuizErrorView(
                    errorMessage: quizState.message,
                    onRetry: () => context.read<QuizCubit>().startQuiz(),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
