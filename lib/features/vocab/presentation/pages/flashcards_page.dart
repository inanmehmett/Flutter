import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../vocab/domain/entities/user_word_entity.dart';
import '../../../vocab/domain/services/vocab_learning_service.dart';

class FlashcardsPage extends StatefulWidget {
  const FlashcardsPage({super.key});

  @override
  State<FlashcardsPage> createState() => _FlashcardsPageState();
}

class _FlashcardsPageState extends State<FlashcardsPage> {
  late Future<List<UserWordEntity>> _future;
  int _index = 0;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _future = getIt<VocabLearningService>().listWords();
  }

  void _next(int? progress) async {
    final list = await _future;
    if (progress != null && _index < list.length) {
      await getIt<VocabLearningService>().updateProgress(list[_index].id, progress);
    }
    setState(() {
      _index = (_index + 1).clamp(0, (list.length - 1).clamp(0, list.length));
      _showBack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: FutureBuilder<List<UserWordEntity>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) return const Center(child: Text('No words to study'));
          final item = list[_index];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showBack = !_showBack),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [Theme.of(context).colorScheme.primary.withValues(alpha: 0.12), Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _showBack ? item.meaningTr : item.word,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _next(1),
                        icon: const Icon(Icons.help_outline),
                        label: const Text("Emin değilim"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _next(2),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Biliyorum'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
