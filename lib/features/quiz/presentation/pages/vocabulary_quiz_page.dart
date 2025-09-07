import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/vocabulary_quiz_cubit.dart';
import '../widgets/vocabulary_quiz_card.dart';
import '../widgets/vocabulary_quiz_progress.dart';
import '../widgets/vocabulary_quiz_result.dart';

class VocabularyQuizPage extends StatelessWidget {
  const VocabularyQuizPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.quiz,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Kelime Quiz\'i',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: BlocConsumer<VocabularyQuizCubit, VocabularyQuizState>(
        listener: (context, state) {
          if (state is VocabularyQuizError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Tekrar Dene',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<VocabularyQuizCubit>().startQuiz();
                  },
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is VocabularyQuizInitial) {
            // Auto-start quiz when page loads
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<VocabularyQuizCubit>().startQuiz();
            });
            return _buildLoadingView();
          } else if (state is VocabularyQuizLoading) {
            return _buildLoadingView();
          } else if (state is VocabularyQuizStarted) {
            return _buildQuizView(context, state);
          } else if (state is VocabularyQuizQuestionAnswered) {
            return _buildAnsweredView(context, state);
          } else if (state is VocabularyQuizCompleted) {
            return VocabularyQuizResultWidget(
              result: state.result,
              allAnswers: state.allAnswers,
              onRestart: () {
                context.read<VocabularyQuizCubit>().restartQuiz();
              },
              onClose: () {
                Navigator.of(context).pop();
              },
            );
          } else if (state is VocabularyQuizError) {
            return _buildErrorView(context, state);
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildStartView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Quiz icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade400,
                    Colors.purple.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.quiz,
                size: 60,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Title
            Text(
              'Kelime Quiz\'i',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'İngilizce kelimelerin Türkçe karşılıklarını test edin!\n10 soru ile bilginizi ölçün. Her soru için 10 saniye süreniz var.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // Features
            _buildFeaturesList(),
            
            const SizedBox(height: 40),
            
            // Start button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  context.read<VocabularyQuizCubit>().startQuiz();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text(
                      'Quiz\'i Başlat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': Icons.timer, 'text': '10 saniye süre'},
      {'icon': Icons.stars, 'text': 'XP kazanın'},
      {'icon': Icons.trending_up, 'text': 'Seviye atlayın'},
      {'icon': Icons.local_fire_department, 'text': 'Streak oluşturun'},
    ];

    return Column(
      children: features.map((feature) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              feature['icon'] as IconData,
              color: Colors.blue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              feature['text'] as String,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Quiz hazırlanıyor...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizView(BuildContext context, VocabularyQuizStarted state) {
    return Column(
      children: [
        // Progress bar
        VocabularyQuizProgressWidget(
          progress: state.progress,
          currentQuestionIndex: state.currentQuestionIndex + 1,
          totalQuestions: state.questions.length,
        ),
        
        // Quiz card
        Expanded(
          child: VocabularyQuizCard(
            question: state.currentQuestion,
            onAnswerSelected: (answer) {
              context.read<VocabularyQuizCubit>().answerQuestion(answer);
            },
            timeRemaining: state.timeRemaining,
            onNextQuestion: null,
            isLastQuestion: false,
          ),
        ),
      ],
    );
  }

  Widget _buildAnsweredView(BuildContext context, VocabularyQuizQuestionAnswered state) {
    return Column(
      children: [
        // Progress bar
        VocabularyQuizProgressWidget(
          progress: state.progress,
          currentQuestionIndex: state.currentQuestionIndex + 1,
          totalQuestions: state.questions.length,
        ),
        
        // Quiz card with answer feedback and next button
        Expanded(
          child: VocabularyQuizCard(
            question: state.currentQuestion,
            onAnswerSelected: (answer) {
              // Answer already selected
            },
            isAnswered: true,
            selectedAnswer: state.lastAnswer.userAnswer,
            isCorrect: state.isCorrect,
            timeRemaining: state.timeRemaining,
            onNextQuestion: () {
              context.read<VocabularyQuizCubit>().nextQuestion();
            },
            isLastQuestion: state.currentQuestionIndex + 1 >= state.questions.length,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, VocabularyQuizError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir Hata Oluştu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  context.read<VocabularyQuizCubit>().startQuiz();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Tekrar Dene',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Nasıl Oynanır?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Her soru için 10 saniye süreniz var'),
            SizedBox(height: 8),
            Text('2. İngilizce kelimenin Türkçe karşılığını seçin'),
            SizedBox(height: 8),
            Text('3. Doğru cevap için XP kazanın'),
            SizedBox(height: 8),
            Text('4. %70 ve üzeri başarı ile quiz\'i geçin'),
            SizedBox(height: 8),
            Text('5. Streak oluşturun ve seviye atlayın'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
