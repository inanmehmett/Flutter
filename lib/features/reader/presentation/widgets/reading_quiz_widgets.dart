import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/reading_quiz_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/toasts.dart';

/// Quiz başlangıç ekranı - Production kalitesinde modern tasarım
class ReadingQuizStartView extends StatelessWidget {
  final String bookTitle;
  final VoidCallback onStartQuiz;

  const ReadingQuizStartView({
    Key? key,
    required this.bookTitle,
    required this.onStartQuiz,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  
                  // Quiz Bilgi Kartı
                  _buildQuizInfoCard(context),
                  const SizedBox(height: 24),
                  
                  // Quiz Kuralları
                  _buildQuizRules(context),
                  const SizedBox(height: 32),
                  
                  // Başla Butonu
                  _buildStartButton(context),
                  const SizedBox(height: 24),
                  
                  // Premium Özellikler
                  _buildPremiumFeatures(context),
                  const SizedBox(height: 24),
                  
                  // Alt Bilgi
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Quiz İkonu
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.quiz,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        Text(
          'Quiz Zamanı!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        
        Text(
          'Kitabınızı ne kadar iyi anladığınızı test edin',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuizInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Kitap Başlığı
          Row(
            children: [
              Icon(Icons.book, color: Colors.blue.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bookTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Quiz Detayları
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  Icons.question_answer,
                  '3 Soru',
                  'Çoktan seçmeli',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  Icons.timer,
                  '10 Dakika',
                  'Zaman sınırı',
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  Icons.emoji_events,
                  '60% Geçiş',
                  'Minimum puan',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 24),
        const SizedBox(height: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuizRules(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Quiz Kuralları',
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Her soru için 1 doğru cevap seçin\n• Zaman sınırı içinde tamamlayın\n• Doğru cevaplar için XP kazanın\n• Seviye atlayarak ilerleyin',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onStartQuiz,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, size: 24),
            const SizedBox(width: 8),
            Text(
              'Quiz\'i Başlat',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeatures(BuildContext context) {
    // Premium alanı kaldırıldı
    return const SizedBox.shrink();
  }

  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Text(
          'Başarılar dileriz! 🚀',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Her quiz ile İngilizce seviyenizi geliştirin',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Quiz yükleniyor ekranı
class ReadingQuizLoadingView extends StatelessWidget {
  const ReadingQuizLoadingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Quiz hazırlanıyor...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// Quiz soru ekranı - Production kalitesinde modern tasarım
class ReadingQuizQuestionView extends StatefulWidget {
  final ReadingQuizData quizData;
  final ReadingQuizQuestion currentQuestion;
  final int currentQuestionIndex;
  final int totalQuestions;
  final double progress;
  final int remainingTime;
  final Function(int, int?, String?) onAnswerSelected;

  const ReadingQuizQuestionView({
    Key? key,
    required this.quizData,
    required this.currentQuestion,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.progress,
    required this.remainingTime,
    required this.onAnswerSelected,
  }) : super(key: key);

  @override
  State<ReadingQuizQuestionView> createState() => _ReadingQuizQuestionViewState();
}

class _ReadingQuizQuestionViewState extends State<ReadingQuizQuestionView>
    with TickerProviderStateMixin {
  int? selectedAnswerId;
  late AnimationController _questionController;
  late Animation<double> _questionAnimation;

  @override
  void initState() {
    super.initState();
    selectedAnswerId = null; // Her yeni soru için seçimi sıfırla
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _questionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeInOut),
    );
    _questionController.forward();
  }

  @override
  void didUpdateWidget(ReadingQuizQuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Soru değiştiğinde seçimi sıfırla
    if (oldWidget.currentQuestion.id != widget.currentQuestion.id) {
      selectedAnswerId = null;
      _questionController.reset();
      _questionController.forward();
    }
  }


  void _submitAnswer() {
    if (selectedAnswerId != null) {
      Logger.debug('UI submit answer questionId=${widget.currentQuestion.id} selected=$selectedAnswerId');
      
      // 0.5 saniye bekle, sonra otomatik geç
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          widget.onAnswerSelected(
            widget.currentQuestion.id,
            selectedAnswerId,
            null,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Header - Progress ve Timer
                _buildHeader(context),
                const SizedBox(height: 24),
                
                // Soru Kartı
                Expanded(
                  child: _buildQuestionCard(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Modern Progress Section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Progress Steps
              Row(
                children: List.generate(widget.totalQuestions, (index) {
                  final isCompleted = index < widget.currentQuestionIndex;
                  final isCurrent = index == widget.currentQuestionIndex;
                  
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index < widget.totalQuestions - 1 ? 8 : 0),
                      height: 8,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent 
                          ? Colors.green 
                          : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              
              // Progress Percentage
              Center(
                child: Text(
                  '${(widget.progress * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(BuildContext context) {
    return AnimatedBuilder(
      animation: _questionAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _questionAnimation.value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Soru Metni
                Text(
                  widget.currentQuestion.questionText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Cevap Seçenekleri
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.currentQuestion.answers.length,
                    itemBuilder: (context, index) {
                      final answer = widget.currentQuestion.answers[index];
                      final isSelected = selectedAnswerId == answer.id;
                      final bool showResult = selectedAnswerId != null;
                      final bool selectedIsCorrect = selectedAnswerId == null
                          ? false
                          : (widget.currentQuestion.answers.firstWhere((a) => a.id == selectedAnswerId!, orElse: () => ReadingQuizAnswer(id: -1, answerText: '', isCorrect: false)).isCorrect);
                      final bool highlightCorrect = showResult && answer.isCorrect && !selectedIsCorrect;
                      
                      return _buildAnswerOption(
                        context,
                        answer,
                        isSelected,
                        showResult,
                        highlightCorrect,
                        () {
                          Logger.debug('UI select answer questionId=${widget.currentQuestion.id} answerId=${answer.id}');
                          setState(() {
                            selectedAnswerId = answer.id;
                          });
                          // Seçim yapıldıktan sonra otomatik gönder
                          _submitAnswer();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnswerOption(
    BuildContext context,
    ReadingQuizAnswer answer,
    bool isSelected,
    bool showResult,
    bool highlightCorrect,
    VoidCallback onTap,
  ) {
    // Renk mantığı
    Color backgroundColor = Colors.grey.shade50;
    Color borderColor = Colors.grey.shade200;
    Color indicatorColor = Colors.grey.shade300;
    Color textColor = Colors.grey.shade700;
    IconData? indicatorIcon;
    Color? indicatorIconColor;

    if (showResult) {
      if (isSelected && answer.isCorrect) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
        indicatorColor = Colors.green;
        textColor = Colors.green.shade800;
        indicatorIcon = Icons.check;
        indicatorIconColor = Colors.white;
      } else if (isSelected && !answer.isCorrect) {
        backgroundColor = Colors.red.shade50;
        borderColor = Colors.red;
        indicatorColor = Colors.red;
        textColor = Colors.red.shade700;
        indicatorIcon = Icons.close;
        indicatorIconColor = Colors.white;
      } else if (highlightCorrect) {
        backgroundColor = Colors.green.shade50;
        borderColor = Colors.green;
        indicatorColor = Colors.green;
        textColor = Colors.green.shade800;
        indicatorIcon = Icons.check;
        indicatorIconColor = Colors.white;
      }
    } else {
      if (isSelected) {
        backgroundColor = Theme.of(context).primaryColor.withOpacity(0.1);
        borderColor = Theme.of(context).primaryColor;
        indicatorColor = Theme.of(context).primaryColor;
        textColor = Theme.of(context).primaryColor;
        indicatorIcon = Icons.check;
        indicatorIconColor = Colors.white;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: (showResult && (isSelected || highlightCorrect)) || (!showResult && isSelected) ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: indicatorColor,
                  ),
                  child: (isSelected || highlightCorrect)
                    ? Icon(indicatorIcon ?? Icons.check, color: indicatorIconColor ?? Colors.white, size: 16)
                    : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    answer.answerText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: (isSelected || highlightCorrect) ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

/// Quiz tamamlandı ekranı
class ReadingQuizCompletedView extends StatelessWidget {
  final ReadingQuizData quizData;
  final List<ReadingQuizUserAnswer> userAnswers;
  final VoidCallback onSubmitQuiz;

  const ReadingQuizCompletedView({
    Key? key,
    required this.quizData,
    required this.userAnswers,
    required this.onSubmitQuiz,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppColors.success,
          ),
          const SizedBox(height: 24),
          Text(
            'Quiz Tamamlandı!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tüm soruları cevapladınız. Sonuçlarınızı görmek için quiz\'i gönderin.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmitQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Sonuçları Gör',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quiz gönderiliyor ekranı
class ReadingQuizSubmittingView extends StatelessWidget {
  const ReadingQuizSubmittingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Quiz değerlendiriliyor...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// Quiz sonuç ekranı - Production kalitesinde modern tasarım
class ReadingQuizResultView extends StatefulWidget {
  final ReadingQuizResult result;
  final VoidCallback onRetakeQuiz;
  final VoidCallback onBackToBook;

  const ReadingQuizResultView({
    Key? key,
    required this.result,
    required this.onRetakeQuiz,
    required this.onBackToBook,
  }) : super(key: key);
  @override
  State<ReadingQuizResultView> createState() => _ReadingQuizResultViewState();
}

class _ReadingQuizResultViewState extends State<ReadingQuizResultView> {
  bool _toastsShown = false;
  int _countdown = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _toastsShown) return;
      _toastsShown = true;
      // Toastlar SignalR tarafından gerçek zamanlı tetikleniyor.
      // Buradaki manuel toasts kaldırıldı ki çift gösterim olmasın.
      HapticFeedback.selectionClick();
      
      // Geri sayım başlat
      _startCountdown();
    });
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _countdown--;
        });
        if (_countdown > 0) {
          _startCountdown();
        } else {
          widget.onBackToBook();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPassed = widget.result.isPassed;
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header - iOS tarzı minimal
              _buildIOSHeader(context, isPassed),
              const SizedBox(height: 40),
              
              // Ana Sonuç - iOS tarzı büyük kart
              _buildIOSMainResult(context, isPassed),
              const SizedBox(height: 32),
              
              // İstatistik - iOS tarzı kompakt
              _buildIOSStats(context),
              const SizedBox(height: 40),
              
              // Geri sayım ve butonlar - iOS tarzı
              _buildIOSActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSHeader(BuildContext context, bool isPassed) {
    return Column(
      children: [
        // iOS tarzı büyük ikon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPassed ? Colors.green.shade100 : Colors.orange.shade100,
          ),
          child: Icon(
            isPassed ? Icons.check_circle : Icons.refresh,
            size: 40,
            color: isPassed ? Colors.green.shade600 : Colors.orange.shade600,
          ),
        ),
        const SizedBox(height: 24),
        
        // iOS tarzı başlık
        Text(
          isPassed ? 'Tebrikler!' : 'Tekrar Deneyin',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
        // iOS tarzı alt başlık
        Text(
          isPassed 
            ? 'Quiz\'i başarıyla tamamladınız'
            : 'Biraz daha çalışarak başarabilirsiniz',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIOSMainResult(BuildContext context, bool isPassed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // iOS tarzı büyük yüzde
          Text(
            '${widget.result.percentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: isPassed ? Colors.green.shade600 : Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 8),
          
          // iOS tarzı durum
          Text(
            isPassed ? 'Başarılı' : 'Gelişim Gerekli',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSStats(BuildContext context) {
    final total = widget.result.correctAnswers + widget.result.wrongAnswers;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Doğru cevaplar
          Column(
            children: [
              Text(
                '${widget.result.correctAnswers}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Doğru',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          // Ayırıcı çizgi
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
          ),
          
          // Toplam sorular
          Column(
            children: [
              Text(
                '$total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toplam',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXPAndLevelInfo(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // XP Kazanılan
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.orange.shade600, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP Kazandınız',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '+${widget.result.xpEarned} XP',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (widget.result.levelUp) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Seviye Atlama
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.purple.shade600, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Seviye Atladınız!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade600,
                          ),
                        ),
                        if (widget.result.newLevel != null)
                          Text(
                            widget.result.newLevel!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.purple.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPremiumFeatures(BuildContext context) {
    // Sonuç sayfasında premium alanı kaldırıldı
    return const SizedBox.shrink();
  }

  Widget _buildIOSActions(BuildContext context) {
    return Column(
      children: [
        // Geri sayım göstergesi - iOS tarzı
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$_countdown',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // iOS tarzı butonlar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                child: OutlinedButton(
                  onPressed: widget.onRetakeQuiz,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Tekrar Çöz',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 50,
                child: ElevatedButton(
                  onPressed: widget.onBackToBook,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Kapat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Quiz hata ekranı
class ReadingQuizErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const ReadingQuizErrorView({
    Key? key,
    required this.message,
    required this.onRetry,
    required this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Hata Oluştu',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Geri Dön'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Tekrar Dene'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
