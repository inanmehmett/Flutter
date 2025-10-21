import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import '../../../../core/di/injection.dart';
import '../../../vocab/domain/services/vocab_learning_service.dart';
import '../../../vocab/domain/entities/user_word_entity.dart' as ue;
import '../../../../core/network/network_manager.dart';

class VocabularyWordDetailPage extends StatefulWidget {
  final int vocabWordId; // Notebook VocabularyWord.id (hash of ue.UserWordEntity.id)
  const VocabularyWordDetailPage({super.key, required this.vocabWordId});

  @override
  State<VocabularyWordDetailPage> createState() => _VocabularyWordDetailPageState();
}

class _VocabularyWordDetailPageState extends State<VocabularyWordDetailPage> {
  ue.UserWordEntity? _entity;
  bool _loading = true;
  bool _descExpanded = false;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = getIt<VocabLearningService>();
    final list = await svc.listWords();
    int _stableId(String input) {
      BigInt hash = BigInt.parse('1469598103934665603');
      final BigInt prime = BigInt.parse('1099511628211');
      final BigInt mask = BigInt.parse('18446744073709551615');
      for (int i = 0; i < input.length; i++) {
        hash = (hash ^ BigInt.from(input.codeUnitAt(i))) & mask;
        hash = (hash * prime) & mask;
      }
      final BigInt signedMask = BigInt.parse('9223372036854775807');
      return (hash & signedMask).toInt();
    }
    final idx = list.indexWhere((e) => _stableId(e.id) == widget.vocabWordId);
    if (!mounted) return;
    setState(() {
      _entity = idx != -1 ? list[idx] : null;
      _loading = false;
    });

    // Enrich from backend if critical fields are missing
    if (_entity != null && ((_entity!.description == null || _entity!.description!.isEmpty) || (_entity!.synonyms.isEmpty && _entity!.antonyms.isEmpty))) {
      await _enrichFromBackend(_entity!);
    }
  }

  Future<void> _enrichFromBackend(ue.UserWordEntity e) async {
    try {
      final nm = getIt<NetworkManager>();
      // Fetch all vocabulary (or optimize later with a search endpoint)
      final resp = await nm.get('/api/ApiVocabulary');
      final root = resp.data is Map<String, dynamic> ? resp.data as Map<String, dynamic> : {};
      final list = (root['data'] as List<dynamic>? ?? []);
      final lower = e.word.toLowerCase();
      Map<String, dynamic>? match;
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        final ow = (m['originalWord'] ?? m['OriginalWord'] ?? '').toString().toLowerCase();
        if (ow == lower) { match = m; break; }
      }
      if (match == null) return;
      final desc = (match['description'] ?? match['Description'])?.toString();
      final ex = (match['exampleSentence'] ?? match['ExampleSentence'])?.toString();
      final audioUrl = (match['audioUrl'] ?? match['AudioUrl'])?.toString();
      final imageUrl = (match['imageUrl'] ?? match['ImageUrl'])?.toString();
      final category = (match['category'] ?? match['Category'])?.toString();
      final syns = ((match['synonyms'] ?? match['Synonyms']) as List<dynamic>?)?.map((x) {
        if (x is String) return x; if (x is Map<String, dynamic>) return (x['text'] ?? x['Text'] ?? x['word'] ?? '').toString(); return x.toString();
      }).where((s) => s.toString().isNotEmpty).cast<String>().toList() ?? <String>[];
      final ants = ((match['antonyms'] ?? match['Antonyms']) as List<dynamic>?)?.map((x) {
        if (x is String) return x; if (x is Map<String, dynamic>) return (x['text'] ?? x['Text'] ?? x['word'] ?? '').toString(); return x.toString();
      }).where((s) => s.toString().isNotEmpty).cast<String>().toList() ?? <String>[];

      // Map backend numeric wordLevel to CEFR if local empty
      String? cefr = _entity?.cefr;
      if (cefr == null || cefr.isEmpty) {
        final dynamic wl = match['wordLevel'] ?? match['WordLevel'];
        if (wl != null) {
          int? lvlNum;
          if (wl is num) lvlNum = wl.toInt();
          if (wl is String) lvlNum = int.tryParse(wl);
          if (lvlNum != null) {
            cefr = switch (lvlNum) { 1 => 'A1', 2 => 'A2', 3 => 'B1', 4 => 'B2', 5 => 'C1', 6 => 'C2', _ => '' };
          }
        }
      }

      await getIt<VocabLearningService>().updateDetails(e.id,
        description: desc,
        example: ex,
        audioUrl: audioUrl,
        imageUrl: imageUrl,
        category: category,
        synonyms: syns,
        antonyms: ants,
        cefr: cefr,
      );

      if (!mounted) return;
      // Reload local entity after update
      final svc = getIt<VocabLearningService>();
      final fresh = await svc.listWords();
      final idx = fresh.indexWhere((x) => x.id == e.id);
      if (idx != -1) {
        setState(() { _entity = fresh[idx]; });
      }
    } catch (_) {}
  }

  Future<void> _updateProgress(int p) async {
    final ent = _entity;
    if (ent == null) return;
    await getIt<VocabLearningService>().updateProgress(ent.id, p);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Öğrenme durumu güncellendi')));
  }

  Future<void> _delete() async {
    final ent = _entity;
    if (ent == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: Text('"${ent.word}" defterden kaldırılacak'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok == true) {
      await getIt<VocabLearningService>().removeWord(ent.id);
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final double clampedScale = math.min(mq.textScaleFactor, 1.2);
    return MediaQuery(
      data: mq.copyWith(textScaleFactor: clampedScale),
      child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text('Kelime Detayı'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.background,
            ],
          ),
        ),
        child: _loading
            ? _buildSkeleton(context)
            : (_entity == null)
                ? const Center(child: Text('Kelime bulunamadı'))
                : _buildContent(context, _entity!),
      ),
      bottomNavigationBar: _entity == null
          ? null
          : _bottomBar(context, selectedIndex: _entity!.progress.clamp(0, 2)),
    ));
  }

  Widget _buildContent(BuildContext context, ue.UserWordEntity e) {
    final tts = getIt<FlutterTts>();
    final int selectedIndex = e.progress.clamp(0, 2);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _glassCard(
            context,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.word, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                          const SizedBox(height: 6),
                          Text(e.meaningTr, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                        ],
                      ),
                    ),
                    Row(children: [
                      _circularIconButton(
                        context,
                        icon: Icons.volume_up,
                        onTap: () async {
                          try {
                          if (_speaking) {
                            await tts.stop();
                            if (!mounted) return; setState(() { _speaking = false; });
                          } else {
                            await tts.setLanguage('en-US');
                            // Optionally: await tts.awaitSpeakCompletion(true);
                            await tts.speak(e.word);
                            if (!mounted) return; setState(() { _speaking = true; });
                            Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() { _speaking = false; }); });
                          }
                        } catch (_) { if (mounted) setState(() { _speaking = false; }); }
                        },
                      active: _speaking,
                    ),
                      const SizedBox(width: 8),
                      _circularIconButton(
                        context,
                        icon: Icons.copy_all_rounded,
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: '${e.word} — ${e.meaningTr}'));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kopyalandı')));
                        },
                      ),
                      const SizedBox(width: 8),
                      _circularIconButton(
                        context,
                        icon: Icons.ios_share,
                        onTap: () async {
                          await Share.share('${e.word} — ${e.meaningTr}${(e.example??'').isNotEmpty ? '\n\n"${e.example}"' : ''}');
                        },
                      ),
                    ]),
                  ],
                ),
                if ((e.imageUrl ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      e.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                if ((e.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _descriptionBlock(context, e.description!),
                ],
                if ((e.example ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onLongPress: () async {
                      await Clipboard.setData(ClipboardData(text: e.example!));
                      if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Örnek cümle kopyalandı')));
                    },
                    child: _pill(context, label: '"${e.example}"', subtle: true),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((e.partOfSpeech ?? '').isNotEmpty) _pill(context, label: e.partOfSpeech!),
                    if ((e.cefr ?? '').isNotEmpty) _pill(context, label: 'CEFR: ${e.cefr!}'),
                    if ((e.category ?? '').isNotEmpty) _pill(context, label: e.category!),
                    _pill(context, label: _progressLabel(e.progress)),
                    for (final t in e.tags) _pill(context, label: t),
                  ],
                ),
              ],
            ),
          ),

          if (e.synonyms.isNotEmpty) ...[
            const SizedBox(height: 16),
            _glassCard(
              context,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Eş Anlamlılar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: e.synonyms.map((s) => _pill(context, label: s)).toList()),
                ],
              ),
            ),
          ],
          if (e.antonyms.isNotEmpty) ...[
            const SizedBox(height: 16),
            _glassCard(
              context,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Zıt Anlamlılar', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: e.antonyms.map((s) => _pill(context, label: s)).toList()),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          _glassCard(
            context,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Öğrenme Durumu', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _segmentedProgress(context, selectedIndex: selectedIndex),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard(BuildContext context, {required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(12)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.6)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _circularIconButton(BuildContext context, {required IconData icon, required VoidCallback onTap, bool active = false}) {
    return Material(
      color: active ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.white.withOpacity(0.6),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: active ? Theme.of(context).colorScheme.primary : Colors.black87),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, {required String label, bool subtle = false}) {
    final Color base = subtle ? Colors.black : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: base.withOpacity(subtle ? 0.06 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withOpacity(subtle ? 0.10 : 0.20)),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtle ? Colors.black87 : base)),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, kToolbarHeight + 16, 16, 24),
      child: Column(
        children: [
          _glassCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 24, width: 160, color: Colors.white.withOpacity(0.4)),
                const SizedBox(height: 8),
                Container(height: 16, width: 220, color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 12),
                Container(height: 14, width: double.infinity, color: Colors.white.withOpacity(0.3)),
                const SizedBox(height: 6),
                Container(height: 14, width: double.infinity, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionBlock(BuildContext context, String text) {
    final int maxLines = _descExpanded ? 999 : 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: maxLines,
          overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[800], height: 1.35),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _descExpanded = !_descExpanded),
          child: Text(_descExpanded ? 'Daha az' : 'Daha fazla', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
        )
      ],
    );
  }

  Widget _segmentedProgress(BuildContext context, {required int selectedIndex}) {
    final List<bool> isSelected = [selectedIndex == 0, selectedIndex == 1, selectedIndex == 2];
    return ToggleButtons(
      isSelected: isSelected,
      onPressed: (idx) {
        _updateProgress(idx);
      },
      borderRadius: BorderRadius.circular(12),
      borderColor: Colors.black.withOpacity(0.12),
      selectedBorderColor: Theme.of(context).colorScheme.primary,
      fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
      selectedColor: Theme.of(context).colorScheme.primary,
      color: Colors.black87,
      constraints: const BoxConstraints(minHeight: 40, minWidth: 90),
      children: const [
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Yeni')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Öğreniliyor')),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('Öğrenildi')),
      ],
    );
  }

  Widget _bottomBar(BuildContext context, {required int selectedIndex}) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateProgress(math.max(0, selectedIndex - 1)),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Geri'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _updateProgress(math.min(2, selectedIndex + 1)),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('İlerle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip({required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.withOpacity(0.24)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  String _progressLabel(int p) {
    if (p <= 0) return 'Yeni';
    if (p == 1) return 'Öğreniliyor';
    return 'Öğrenildi';
  }
}


