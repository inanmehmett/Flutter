import 'package:flutter/material.dart';
import '../../domain/entities/vocabulary_quiz_models.dart';

class VocabularyQuizProgressWidget extends StatefulWidget {
  final VocabularyQuizProgress progress;
  final int currentQuestionIndex;
  final int totalQuestions;

  const VocabularyQuizProgressWidget({
    super.key,
    required this.progress,
    required this.currentQuestionIndex,
    required this.totalQuestions,
  });

  @override
  State<VocabularyQuizProgressWidget> createState() => _VocabularyQuizProgressWidgetState();
}

class _VocabularyQuizProgressWidgetState extends State<VocabularyQuizProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.currentQuestionIndex / widget.totalQuestions,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    _progressController.forward();
  }

  @override
  void didUpdateWidget(VocabularyQuizProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentQuestionIndex != widget.currentQuestionIndex) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.currentQuestionIndex / oldWidget.totalQuestions,
        end: widget.currentQuestionIndex / widget.totalQuestions,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ));
      _progressController.reset();
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress bar
          _buildModernProgressBar(),
        ],
      ),
    );
  }

  Widget _buildModernProgressBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        const SizedBox(height: 20),
        
        // Modern progress bar
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Column(
              children: [
                // Progress percentage
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'İlerleme',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(_progressAnimation.value * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _getProgressColor(_progressAnimation.value),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Progress bar with question numbers
                Row(
                  children: [
                    // Current question number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getProgressColor(_progressAnimation.value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getProgressColor(_progressAnimation.value).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.currentQuestionIndex}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Progress bar container
                    Expanded(
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.grey.shade200,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Stack(
                            children: [
                              // Background
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey.shade200,
                              ),
                              // Progress fill
                              FractionallySizedBox(
                                widthFactor: _progressAnimation.value,
                                child: Container(
                                  height: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _getProgressGradient(_progressAnimation.value),
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getProgressColor(_progressAnimation.value).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Total questions number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${widget.totalQuestions}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }


  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red.shade500;
    if (progress < 0.7) return Colors.orange.shade500;
    return Colors.green.shade500;
  }

  List<Color> _getProgressGradient(double progress) {
    if (progress < 0.3) {
      return [Colors.red.shade400, Colors.red.shade600];
    } else if (progress < 0.7) {
      return [Colors.orange.shade400, Colors.orange.shade600];
    } else {
      return [Colors.green.shade400, Colors.green.shade600];
    }
  }

}
