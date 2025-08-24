import 'package:flutter/material.dart';
import '../../domain/entities/reading_quiz_models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';

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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.diamond, color: Colors.purple.shade600, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Premium Avantajları',
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Reklamsız quiz deneyimi\n• Detaylı performans analizi\n• Özel ipuçları ve açıklamalar\n• Sınırsız quiz çözme',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // Premium satın alma
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.purple.shade600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Premium\'a Geç',
                style: TextStyle(color: Colors.purple.shade600),
              ),
            ),
          ),
        ],
      ),
    );
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
  final VoidCallback? onPreviousQuestion;

  const ReadingQuizQuestionView({
    Key? key,
    required this.quizData,
    required this.currentQuestion,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.progress,
    required this.remainingTime,
    required this.onAnswerSelected,
    this.onPreviousQuestion,
  }) : super(key: key);

  @override
  State<ReadingQuizQuestionView> createState() => _ReadingQuizQuestionViewState();
}

class _ReadingQuizQuestionViewState extends State<ReadingQuizQuestionView>
    with TickerProviderStateMixin {
  int? selectedAnswerId;
  late AnimationController _timerController;
  late AnimationController _questionController;
  late Animation<double> _questionAnimation;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      duration: Duration(seconds: widget.remainingTime),
      vsync: this,
    );
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _questionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _questionController, curve: Curves.easeInOut),
    );
    _questionController.forward();
    _startTimer();
  }

  void _startTimer() {
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Zaman doldu, otomatik cevap gönder
        _submitAnswer();
      }
    });
  }

  void _submitAnswer() {
    if (selectedAnswerId != null) {
      Logger.debug('UI submit answer questionId=${widget.currentQuestion.id} selected=$selectedAnswerId');
      widget.onAnswerSelected(
        widget.currentQuestion.id,
        selectedAnswerId,
        null,
      );
    }
  }

  @override
  void dispose() {
    _timerController.dispose();
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
                
                // Aksiyon Butonları
                _buildActionButtons(context),
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
        // Progress Bar
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: widget.progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${widget.currentQuestionIndex + 1}/$widget.totalQuestions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Timer
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer, color: Colors.orange.shade600, size: 20),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                final remainingSeconds = (widget.remainingTime * _timerController.value).round();
                final minutes = remainingSeconds ~/ 60;
                final seconds = remainingSeconds % 60;
                
                return Text(
                  '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: remainingSeconds < 30 ? Colors.red.shade600 : Colors.orange.shade600,
                  ),
                );
              },
            ),
          ],
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
                  'Soru ${widget.currentQuestionIndex + 1}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                
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
                      
                      return _buildAnswerOption(
                        context,
                        answer,
                        isSelected,
                        () {
                          Logger.debug('UI select answer questionId=${widget.currentQuestion.id} answerId=${answer.id}');
                          setState(() {
                            selectedAnswerId = answer.id;
                          });
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
    VoidCallback onTap,
  ) {
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
              color: isSelected 
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected 
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  ),
                  child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    answer.answerText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected 
                        ? Theme.of(context).primaryColor
                        : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Önceki Soru Butonu
        if (widget.onPreviousQuestion != null) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: widget.onPreviousQuestion,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, size: 20),
                  const SizedBox(width: 8),
                  Text('Önceki'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
        
        // Cevabı Gönder Butonu
        Expanded(
          flex: widget.onPreviousQuestion != null ? 1 : 2,
          child: ElevatedButton(
            onPressed: selectedAnswerId != null ? _submitAnswer : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: selectedAnswerId != null ? 4 : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.currentQuestionIndex == widget.totalQuestions - 1 
                    ? 'Bitir' 
                    : 'Sonraki',
                ),
              ],
            ),
          ),
        ),
      ],
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
class ReadingQuizResultView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isPassed = result.isPassed;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isPassed 
              ? [Colors.green.shade50, Colors.white]
              : [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Header - Başarı/Kutlama
                _buildHeader(context, isPassed),
                const SizedBox(height: 32),
                
                // Ana Sonuç Kartı
                _buildMainResultCard(context),
                const SizedBox(height: 24),
                
                // Detaylı İstatistikler
                _buildDetailedStats(context),
                const SizedBox(height: 24),
                
                // XP ve Seviye Bilgileri
                _buildXPAndLevelInfo(context),
                const SizedBox(height: 24),
                
                // Premium Özellikler (Monetization)
                _buildPremiumFeatures(context),
                const SizedBox(height: 32),
                
                // Aksiyon Butonları
                _buildActionButtons(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isPassed) {
    final theme = Theme.of(context);
    return Column(
      children: [
        // Ana İkon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPassed ? Colors.green.shade100 : Colors.orange.shade100,
            boxShadow: [
              BoxShadow(
                color: (isPassed ? Colors.green : Colors.orange).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            isPassed ? Icons.celebration : Icons.sentiment_satisfied,
            size: 60,
            color: isPassed ? Colors.green.shade600 : Colors.orange.shade600,
          ),
        ),
        const SizedBox(height: 24),
        
        // Başlık
        Text(
          isPassed ? 'Tebrikler!' : 'İyi Çaba!',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isPassed ? Colors.green.shade700 : Colors.orange.shade700,
          ),
        ),
        const SizedBox(height: 8),
        
        // Alt başlık
        Text(
          isPassed 
            ? 'Quiz\'i başarıyla tamamladınız!'
            : 'Biraz daha çalışarak başarabilirsiniz.',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainResultCard(BuildContext context) {
    final theme = Theme.of(context);
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
          // Puan
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber.shade600, size: 32),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  '${result.score} Puan',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Yüzde
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: result.percentage >= 70 ? Colors.green.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${result.percentage.toStringAsFixed(1)}%',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: result.percentage >= 70 ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Doğru',
            '${result.correctAnswers}/3',
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Yanlış',
            '${result.wrongAnswers}/3',
            Icons.cancel,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            context,
            'Süre',
            '${(result.timeSpent / 60).round()}dk',
            Icons.timer,
            Colors.blue,
          ),
        ),
      ],
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
                      '+${result.xpEarned} XP',
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
          
          if (result.levelUp) ...[
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
                        if (result.newLevel != null)
                          Text(
                            result.newLevel!,
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
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.blue.shade50],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.diamond, color: Colors.purple.shade600, size: 24),
              const SizedBox(width: 8),
              Text(
                'Premium Özellikler',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Reklamsız deneyim\n• Detaylı analitikler\n• Özel ipuçları\n• Sınırsız quiz',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Premium satın alma
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Premium\'a Geç'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onRetakeQuiz,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Tekrar Çöz',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: onBackToBook,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Kitaba Dön',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
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
