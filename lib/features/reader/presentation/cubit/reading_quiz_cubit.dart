import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/reading_quiz_models.dart';
import '../../data/services/reading_quiz_service.dart';
import '../../../../core/analytics/event_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/services/xp_state_service.dart';

part 'reading_quiz_state.dart';

class ReadingQuizCubit extends Cubit<ReadingQuizState> {
  final ReadingQuizService _readingQuizService;

  ReadingQuizCubit(this._readingQuizService) : super(ReadingQuizInitial());

  /// Quiz başlatır
  Future<void> startQuiz(int readingTextId) async {
    try {
      Logger.info('ReadingQuizCubit.startQuiz readingTextId=$readingTextId');
      emit(ReadingQuizLoading());
      
      final response = await _readingQuizService.startQuiz(readingTextId);
      
      if (response.success && response.data != null) {
        Logger.info('ReadingQuizCubit.startQuiz success quizId=${response.data!.quizId}');
        emit(ReadingQuizStarted(
          quizData: response.data!,
          currentQuestionIndex: 0,
          userAnswers: [],
          startTime: DateTime.now(),
          questionStartTime: DateTime.now(),
        ));
      } else {
        Logger.warning('ReadingQuizCubit.startQuiz failed message=${response.message}');
        emit(ReadingQuizError(response.message));
      }
    } catch (e) {
      Logger.error('ReadingQuizCubit.startQuiz exception', e);
      emit(ReadingQuizError('Quiz başlatılamadı: $e'));
    }
  }

  /// Soruyu cevaplar
  Future<void> answerQuestion(int questionId, int? selectedAnswerId, String? userAnswerText) async {
    Logger.debug('ReadingQuizCubit.answerQuestion q=$questionId selected=$selectedAnswerId text=$userAnswerText');
    if (state is ReadingQuizStarted) {
      final currentState = state as ReadingQuizStarted;
      final questionStartTime = currentState.questionStartTime ?? DateTime.now();
      final timeSpent = DateTime.now().difference(questionStartTime).inSeconds;
      
      final userAnswer = ReadingQuizUserAnswer(
        questionId: questionId,
        selectedAnswerId: selectedAnswerId,
        userAnswerText: userAnswerText,
        timeSpentSeconds: timeSpent,
      );

      final updatedAnswers = List<ReadingQuizUserAnswer>.from(currentState.userAnswers)
        ..add(userAnswer);

      final nextQuestionIndex = currentState.currentQuestionIndex + 1;
      
      if (nextQuestionIndex >= currentState.quizData.questions.length) {
        // Quiz tamamlandı
        Logger.info('ReadingQuizCubit.answerQuestion -> completed with ${updatedAnswers.length} answers');
        emit(ReadingQuizCompleted(
          quizData: currentState.quizData,
          userAnswers: updatedAnswers,
          startTime: currentState.startTime,
        ));
        // Ara ekranı atla: otomatik olarak sonucu gönder ve sonuç sayfasına geç
        await submitQuiz();
      } else {
        // Sonraki soruya geç
        Logger.info('ReadingQuizCubit.answerQuestion -> nextQuestion index=$nextQuestionIndex');
        emit(ReadingQuizStarted(
          quizData: currentState.quizData,
          currentQuestionIndex: nextQuestionIndex,
          userAnswers: updatedAnswers,
          startTime: currentState.startTime,
          questionStartTime: DateTime.now(),
        ));
      }
    }
  }

  /// Quiz'i tamamlar ve sonucu sunucuya gönderir
  Future<void> submitQuiz() async {
    Logger.info('ReadingQuizCubit.submitQuiz state=${state.runtimeType}');
    if (state is ReadingQuizCompleted) {
      final currentState = state as ReadingQuizCompleted;
      
      try {
        emit(ReadingQuizSubmitting());
        
        final request = ReadingQuizCompleteRequest(
          quizId: currentState.quizData.quizId,
          startedAt: currentState.startTime,
          answers: currentState.userAnswers,
        );

        Logger.network('ReadingQuizCubit.submitQuiz -> ${request.toJson()}');

        final response = await _readingQuizService.completeQuiz(request);
        
        if (response.success && response.data != null) {
          Logger.info('ReadingQuizCubit.submitQuiz success resultId=${response.data!.resultId}');
          
          // ✅ Update XP state immediately (optimistic update)
          final xpEarned = response.data!.xpEarned;
          if (xpEarned > 0) {
            try {
              final xpStateService = getIt<XPStateService>();
              await xpStateService.incrementDailyXP(xpEarned);
              await xpStateService.incrementTotalXP(xpEarned);
              Logger.info('✅ Updated XP state after quiz: +$xpEarned XP');
            } catch (e) {
              Logger.error('Failed to update XP state after quiz', e);
            }
          }
          
          emit(ReadingQuizFinished(response.data!));

          // Emit quiz_passed event if passed; include readingTextId when available
          try {
            final passed = response.data!.isPassed;
            final readingTextId = currentState.quizData.readingTextId;
            final score = response.data!.score;
            final percentage = response.data!.percentage;
            final eventSvc = getIt<EventService>();
            await eventSvc.sendEvents([
              {
                'eventType': 'quiz_completed',
                'occurredAt': DateTime.now().toUtc().toIso8601String(),
                'payload': {
                  'readingTextId': readingTextId,
                  'score': score,
                  'percentage': percentage,
                  'passed': passed,
                }
              },
              if (passed)
                {
                  'eventType': 'quiz_passed',
                  'occurredAt': DateTime.now().toUtc().toIso8601String(),
                  'payload': {
                    'readingTextId': readingTextId,
                    'score': score,
                    'percentage': percentage,
                  }
                },
            ]);
          } catch (_) {}
        } else {
          Logger.warning('ReadingQuizCubit.submitQuiz failed message=${response.message}');
          emit(ReadingQuizError(response.message));
        }
      } catch (e) {
        Logger.error('ReadingQuizCubit.submitQuiz exception', e);
        emit(ReadingQuizError('Quiz gönderilemedi: $e'));
      }
    } else {
      Logger.warning('ReadingQuizCubit.submitQuiz invalid state=${state.runtimeType}');
      emit(ReadingQuizError('Quiz durumu geçersiz: ${state.runtimeType}'));
    }
  }

  /// Quiz'i sıfırlar
  void resetQuiz() {
    Logger.info('ReadingQuizCubit.resetQuiz');
    emit(ReadingQuizInitial());
  }

  /// Önceki soruya dön
  void goToPreviousQuestion() {
    Logger.info('ReadingQuizCubit.goToPreviousQuestion');
    if (state is ReadingQuizStarted) {
      final currentState = state as ReadingQuizStarted;
      if (currentState.currentQuestionIndex > 0) {
        final previousIndex = currentState.currentQuestionIndex - 1;
        
        // Son cevabı kaldır
        final updatedAnswers = List<ReadingQuizUserAnswer>.from(currentState.userAnswers);
        if (updatedAnswers.isNotEmpty) {
          updatedAnswers.removeLast();
        }
        
        emit(ReadingQuizStarted(
          quizData: currentState.quizData,
          currentQuestionIndex: previousIndex,
          userAnswers: updatedAnswers,
          startTime: currentState.startTime,
          questionStartTime: DateTime.now(),
        ));
      }
    }
  }

  /// Mevcut soruyu al
  ReadingQuizQuestion? getCurrentQuestion() {
    if (state is ReadingQuizStarted) {
      final currentState = state as ReadingQuizStarted;
      if (currentState.currentQuestionIndex < currentState.quizData.questions.length) {
        return currentState.quizData.questions[currentState.currentQuestionIndex];
      }
    }
    return null;
  }

  /// İlerleme yüzdesini hesapla
  double getProgress() {
    if (state is ReadingQuizStarted) {
      final currentState = state as ReadingQuizStarted;
      return (currentState.currentQuestionIndex + 1) / currentState.quizData.questions.length;
    }
    return 0.0;
  }

  /// Kalan zamanı hesapla (saniye)
  int getRemainingTime() {
    if (state is ReadingQuizStarted) {
      final currentState = state as ReadingQuizStarted;
      final elapsed = DateTime.now().difference(currentState.startTime).inMinutes;
      final remaining = currentState.quizData.timeLimitMinutes - elapsed;
      return remaining > 0 ? remaining * 60 : 0;
    }
    return 0;
  }
}
