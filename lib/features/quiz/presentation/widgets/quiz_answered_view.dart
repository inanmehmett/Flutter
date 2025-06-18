import 'package:flutter/material.dart';
import '../../domain/entities/quiz_models.dart';

class QuizAnsweredView extends StatelessWidget {
  final QuizQuestion question;
  final QuizOption selectedOption;
  final AnswerResult result;
  final VoidCallback onNext;

  const QuizAnsweredView({
    super.key,
    required this.question,
    required this.selectedOption,
    required this.result,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              question.text,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                context,
                icon: Icons.tag,
                label: question.category,
                color: Colors.blue,
              ),
              const Spacer(),
              _buildInfoChip(
                context,
                icon: Icons.star,
                label: question.difficulty,
                color: Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: question.options.length,
            itemBuilder: (context, index) {
              final option = question.options[index];
              return _buildOptionButton(context, option);
            },
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: result.isCorrect ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: result.isCorrect ? Colors.green : Colors.red,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.isCorrect ? 'Doğru!' : 'Yanlış!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: result.isCorrect ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (!result.isCorrect) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Doğru cevap: ${result.correctAnswer}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.green[700],
                        ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  result.explanation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Sonraki Soru',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, QuizOption option) {
    final isSelected = option.id == selectedOption.id;
    final isCorrect = option.isCorrect;
    Color backgroundColor;
    Color textColor;

    if (isCorrect) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
    } else if (isSelected) {
      backgroundColor = Colors.red;
      textColor = Colors.white;
    } else {
      backgroundColor = Colors.grey[100]!;
      textColor = Colors.black87;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        option.text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
