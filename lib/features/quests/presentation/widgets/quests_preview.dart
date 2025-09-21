import 'package:flutter/material.dart';
import '../../../../core/widgets/toasts.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../quests/data/services/quests_service.dart';
import '../../../quests/data/models/daily_task.dart';

class QuestsPreview extends StatefulWidget {
  const QuestsPreview({super.key});

  @override
  State<QuestsPreview> createState() => _QuestsPreviewState();
}

class _QuestsPreviewState extends State<QuestsPreview> {
  late final QuestsService _service;
  late Future<List<DailyTaskModel>> _future;
  bool _claiming = false;

  @override
  void initState() {
    super.initState();
    _service = QuestsService(getIt<ApiClient>(), getIt<CacheManager>());
    _future = _service.fetchDailyTasks();
  }

  Future<void> _reload({bool force = false}) async {
    setState(() => _future = _service.fetchDailyTasks(forceRefresh: force));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DailyTaskModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _skeleton();
        }
        if (snapshot.hasError) {
          return _error('Görevler yüklenemedi');
        }
        final tasks = snapshot.data ?? const <DailyTaskModel>[];
        if (tasks.isEmpty) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.flag_outlined, color: Colors.teal),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Bugün için görev bulunmuyor', style: TextStyle(fontWeight: FontWeight.w600))),
                  TextButton(onPressed: _reload, child: const Text('Yenile')),
                ],
              ),
            ),
          );
        }
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag, color: Colors.teal),
                    const SizedBox(width: 8),
                    const Text('Günlük Görevler', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(onPressed: _reload, icon: const Icon(Icons.refresh, size: 18)),
                  ],
                ),
                const SizedBox(height: 8),
                ...tasks.take(3).map(_taskTile).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _taskTile(DailyTaskModel t) {
    final progress = t.requiredCount == 0 ? 0.0 : (t.completedCount / t.requiredCount).clamp(0.0, 1.0);
    final completed = t.isCompleted || progress >= 1.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: progress, minHeight: 6),
                const SizedBox(height: 4),
                Text('${t.completedCount}/${t.requiredCount} • +${t.xpReward} XP', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: (!completed && !_claiming) ? () => _claim(t.id) : null,
            icon: const Icon(Icons.card_giftcard, size: 16),
            label: Text(completed ? 'Tamam' : 'Claim'),
          ),
        ],
      ),
    );
  }

  Future<void> _claim(int taskId) async {
    setState(() => _claiming = true);
    try {
      final data = await _service.claimTask(taskId);
      final xp = (data['xpEarned'] ?? 0) as int;
      if (!mounted) return;
      ToastOverlay.show(context, XpToast(xp), channel: 'xp');
      await _reload(force: true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim başarısız')));
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Widget _skeleton() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 14, width: 140, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            ...List.generate(3, (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Container(height: 12, color: Colors.grey.shade200)),
                const SizedBox(width: 12),
                Container(width: 80, height: 32, color: Colors.grey.shade200),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _error(String message) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
          TextButton(onPressed: _reload, child: const Text('Tekrar dene')),
        ]),
      ),
    );
  }
}
