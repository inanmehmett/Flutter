import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/di/injection.dart';
import '../../../vocab/domain/services/vocab_learning_service.dart';
import '../../../vocab/domain/entities/user_word_entity.dart';

class LearningListPage extends StatefulWidget {
  const LearningListPage({super.key});

  @override
  State<LearningListPage> createState() => _LearningListPageState();
}

class _LearningListPageState extends State<LearningListPage> {
  String _query = '';
  int? _progressFilter;
  String? _cefrFilter;
  late Future<List<UserWordEntity>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UserWordEntity>> _load() {
    final svc = getIt<VocabLearningService>();
    return svc.listWords(query: _query, cefr: _cefrFilter, progress: _progressFilter);
  }

  Future<void> _refresh() async {
    setState(() { _future = _load(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenme Listem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search word or meaning'),
                    onChanged: (v) { setState(() { _query = v; _future = _load(); }); },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String?>(
                  value: _cefrFilter,
                  hint: const Text('CEFR'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 'A1', child: Text('A1')),
                    DropdownMenuItem(value: 'A2', child: Text('A2')),
                    DropdownMenuItem(value: 'B1', child: Text('B1')),
                    DropdownMenuItem(value: 'B2', child: Text('B2')),
                    DropdownMenuItem(value: 'C1', child: Text('C1')),
                    DropdownMenuItem(value: 'C2', child: Text('C2')),
                  ],
                  onChanged: (v) { setState(() { _cefrFilter = v; _future = _load(); }); },
                ),
                const SizedBox(width: 8),
                DropdownButton<int?>(
                  value: _progressFilter,
                  hint: const Text('Progress'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All')),
                    DropdownMenuItem(value: 0, child: Text('New')),
                    DropdownMenuItem(value: 1, child: Text('Learning')),
                    DropdownMenuItem(value: 2, child: Text('Learned')),
                  ],
                  onChanged: (v) { setState(() { _progressFilter = v; _future = _load(); }); },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<UserWordEntity>>(
              future: _future,
              builder: (context, snap) {
                final list = snap.data ?? [];
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (list.isEmpty) {
                  return const Center(child: Text('No words yet'));
                }
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final w = list[index];
                    return ListTile(
                      title: Text(w.word, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(w.meaningTr),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _progressPill(w.progress),
                          PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'delete') {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Silinsin mi?'),
                                    content: Text('"${w.word}" listesinden kaldırılacak.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
                                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await getIt<VocabLearningService>().removeWord(w.id);
                                  _refresh();
                                }
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'delete', child: Text('Sil')),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up),
                            onPressed: () async {
                              try {
                                final tts = getIt<FlutterTts>();
                                await tts.stop();
                                await tts.setLanguage('en-US');
                                await tts.speak(w.word);
                              } catch (_) {}
                            },
                          ),
                        ],
                      ),
                      onTap: () async {
                        final svc = getIt<VocabLearningService>();
                        final next = (w.progress + 1).clamp(0, 2);
                        await svc.updateProgress(w.id, next);
                        _refresh();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/study/flashcards');
                },
                icon: const Icon(Icons.psychology_alt),
                label: const Text('Study All'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/study/quiz');
                },
                icon: const Icon(Icons.quiz),
                label: const Text('Quiz Mode'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressPill(int progress) {
    final label = switch (progress) { 0 => 'New', 1 => 'Learning', _ => 'Learned' };
    final color = switch (progress) { 0 => Colors.blue, 1 => Colors.orange, _ => Colors.green };
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999), border: Border.all(color: color.withOpacity(0.24))),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
