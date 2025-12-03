import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../../word_exercises/domain/entities/user_word_entity.dart';
import '../../../word_exercises/domain/services/vocab_learning_service.dart';

class VocabQuizPage extends StatefulWidget {
  const VocabQuizPage({super.key});

  @override
  State<VocabQuizPage> createState() => _VocabQuizPageState();
}

class _VocabQuizPageState extends State<VocabQuizPage> {
  late Future<List<UserWordEntity>> _future;
  int _index = 0;
  int _correct = 0;
  List<String> _options = [];
  int? _selected;

  @override
  void initState() {
    super.initState();
    _future = getIt<VocabLearningService>().listWords();
  }

  void _buildOptions(List<UserWordEntity> list) {
    final rng = Random();
    final current = list[_index];
    final set = <String>{current.meaningTr};
    while (set.length < 4 && list.isNotEmpty) {
      set.add(list[rng.nextInt(list.length)].meaningTr);
    }
    final arr = set.toList()..shuffle();
    setState(() { _options = arr; _selected = null; });
  }

  void _answer(List<UserWordEntity> list, int choice) async {
    setState(() { _selected = choice; });
    await Future.delayed(const Duration(milliseconds: 350));
    final current = list[_index];
    final ok = _options[choice] == current.meaningTr;
    if (ok) {
      _correct++;
      await getIt<VocabLearningService>().updateProgress(current.id, 2);
    } else {
      await getIt<VocabLearningService>().updateProgress(current.id, 1);
    }
    if (_index < list.length - 1) {
      setState(() { _index++; });
      _buildOptions(list);
    } else {
      _showResult(list.length);
    }
  }

  void _showResult(int total) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quiz Result'),
        content: Text('$_correct / $total correct'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vocab Quiz')),
      body: FutureBuilder<List<UserWordEntity>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = (snap.data ?? []).where((e) => e.word.isNotEmpty && e.meaningTr.isNotEmpty).toList();
          if (list.length < 4) return const Center(child: Text('Not enough words (min 4)'));
          if (_options.isEmpty) WidgetsBinding.instance.addPostFrameCallback((_) => _buildOptions(list));
          final item = list[_index];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(item.word, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                for (var i = 0; i < _options.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected == null
                            ? null
                            : (i == _selected && _options[i] == item.meaningTr)
                                ? Colors.green
                                : (i == _selected ? Colors.red : null),
                      ),
                      onPressed: _selected == null ? () => _answer(list, i) : null,
                      child: Text(_options[i]),
                    ),
                  ),
                ],
                const Spacer(),
                Text('Question ${_index + 1} / ${list.length}', textAlign: TextAlign.center),
              ],
            ),
          );
        },
      ),
    );
  }
}


