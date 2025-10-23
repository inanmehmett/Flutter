import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback;
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


  Future<void> _delete() async {
    final ent = _entity;
    if (ent == null) return;
    try { HapticFeedback.mediumImpact(); } catch (_) {}
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: Colors.red,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kelimeyi Sil',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${ent.word}" kelimesini defterinizden silmek istediğinizden emin misiniz?',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: () => Navigator.pop(context, true),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Text(
                  'Sil',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const Divider(height: 1),
            InkWell(
              onTap: () => Navigator.pop(context, false),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'İptal',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kelime Detayı',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: _delete,
            tooltip: 'Sil',
          ),
          const SizedBox(width: 8),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ana kelime ve anlamı
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'vocab_word_${widget.vocabWordId}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                e.word,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1.0,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            e.meaningTr,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.85),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Aksiyon butonları
                    Column(
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.volume_up_rounded,
                          label: 'Seslendir',
                          onTap: () async {
                            try {
                              if (_speaking) {
                                await tts.stop();
                                if (!mounted) return; 
                                setState(() { _speaking = false; });
                              } else {
                                await tts.setLanguage('en-US');
                                await tts.speak(e.word);
                                if (!mounted) return; 
                                setState(() { _speaking = true; });
                                Future.delayed(const Duration(seconds: 2), () { 
                                  if (mounted) setState(() { _speaking = false; }); 
                                });
                              }
                            } catch (_) { 
                              if (mounted) setState(() { _speaking = false; }); 
                            }
                          },
                          active: _speaking,
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          context,
                          icon: Icons.copy_all_rounded,
                          label: 'Kopyala',
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: '${e.word} — ${e.meaningTr}'));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kopyalandı'))
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          context,
                          icon: Icons.ios_share_rounded,
                          label: 'Paylaş',
                          onTap: () async {
                            await Share.share('${e.word} — ${e.meaningTr}${(e.example??'').isNotEmpty ? '\n\n"${e.example}"' : ''}');
                          },
                        ),
                      ],
                    ),
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

          const SizedBox(height: 20),
          _glassCard(
            context,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Öğrenme Durumu', 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                     const SizedBox(height: 16),
                     _buildProgressCard(context, selectedIndex),
                     const SizedBox(height: 16),
                     _segmentedProgress(context, selectedIndex: selectedIndex),
                     const SizedBox(height: 16),
                     _buildResetOptions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, int selectedIndex) {
    final progressData = [
      {'label': 'Yeni', 'icon': Icons.fiber_new, 'color': Colors.blue, 'description': 'Henüz öğrenilmeye başlanmadı'},
      {'label': 'Öğreniliyor', 'icon': Icons.school, 'color': Colors.orange, 'description': 'Aktif olarak öğreniliyor'},
      {'label': 'Öğrenildi', 'icon': Icons.check_circle, 'color': Colors.green, 'description': 'Başarıyla öğrenildi'},
    ];

    final currentData = progressData[selectedIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (currentData['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (currentData['color'] as Color).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: (currentData['color'] as Color).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  currentData['icon'] as IconData,
                  size: 24,
                  color: currentData['color'] as Color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentData['label'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: currentData['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentData['description'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress indicator
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (currentData['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    '${((selectedIndex + 1) / 3 * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: currentData['color'] as Color,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bilgilendirme metni
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Öğrenme durumu quiz sonuçlarına göre otomatik olarak güncellenir.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard(BuildContext context, {required Widget child, EdgeInsetsGeometry padding = const EdgeInsets.all(12)}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: () {
        try { HapticFeedback.selectionClick(); } catch (_) {}
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: active
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              blurRadius: active ? 12 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: active 
                  ? Colors.white 
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active 
                    ? Colors.white 
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circularIconButton(BuildContext context, {required IconData icon, required VoidCallback onTap, bool active = false}) {
    return Container(
      decoration: BoxDecoration(
        color: active
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: active
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Colors.black.withOpacity(0.06),
            blurRadius: active ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            try { HapticFeedback.selectionClick(); } catch (_) {}
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              icon,
              size: 22,
              color: active ? Colors.white : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, {required String label, bool subtle = false}) {
    final Color base = subtle ? Colors.black : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: base.withOpacity(subtle ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: subtle ? Colors.black87 : base,
          letterSpacing: 0.1,
        ),
      ),
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
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topLeft,
          child: Text(
            text,
            maxLines: maxLines,
            overflow: _descExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[800], height: 1.35),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            try { HapticFeedback.selectionClick(); } catch (_) {}
            setState(() => _descExpanded = !_descExpanded);
          },
          child: Text(_descExpanded ? 'Daha az' : 'Daha fazla', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
        )
      ],
    );
  }

  Widget _segmentedProgress(BuildContext context, {required int selectedIndex}) {
    final progressData = [
      {'label': 'Yeni', 'icon': Icons.fiber_new, 'color': Colors.blue},
      {'label': 'Öğreniliyor', 'icon': Icons.school, 'color': Colors.orange},
      {'label': 'Öğrenildi', 'icon': Icons.check_circle, 'color': Colors.green},
    ];

    return Row(
      children: progressData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final isSelected = selectedIndex == index;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < progressData.length - 1 ? 8 : 0,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? (data['color'] as Color).withOpacity(0.15)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? data['color'] as Color
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  data['icon'] as IconData,
                  size: 20,
                  color: isSelected
                      ? data['color'] as Color
                      : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
                const SizedBox(height: 6),
                Text(
                  data['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? data['color'] as Color
                        : Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Mevcut Durum',
                    style: TextStyle(
                      fontSize: 10,
                      color: data['color'] as Color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResetOptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Reset Seçenekleri',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Öğrenme durumunu sıfırlamak için aşağıdaki seçenekleri kullanabilirsiniz:',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildResetButton(
                  context,
                  icon: Icons.restart_alt_rounded,
                  label: 'Progress Sıfırla',
                  description: 'Öğrenme durumunu başa al',
                  onTap: () => _showResetConfirmation(context, 'progress'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildResetButton(
                  context,
                  icon: Icons.analytics_outlined,
                  label: 'İstatistikleri Sıfırla',
                  description: 'Tüm öğrenme verilerini temizle',
                  onTap: () => _showResetConfirmation(context, 'stats'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, String type) {
    final String title;
    final String message;
    
    switch (type) {
      case 'progress':
        title = 'Progress Sıfırla';
        message = 'Bu kelimenin öğrenme durumunu başa almak istediğinizden emin misiniz? Bu işlem geri alınamaz.';
        break;
      case 'stats':
        title = 'İstatistikleri Sıfırla';
        message = 'Bu kelimenin tüm öğrenme verilerini (quiz sonuçları, istatistikler) silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performReset(type);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  void _performReset(String type) {
    // TODO: Implement reset functionality
    // This would call the repository to reset the word's learning data
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${type == 'progress' ? 'Progress' : 'İstatistikler'} sıfırlandı'),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _progressLabel(int p) {
    if (p <= 0) return 'Yeni';
    if (p == 1) return 'Öğreniliyor';
    return 'Öğrenildi';
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
                onPressed: () {
                  try { HapticFeedback.lightImpact(); } catch (_) {}
                  // Manuel progress değişimi artık yok
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Bilgi'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  try { HapticFeedback.lightImpact(); } catch (_) {}
                  // Quiz'e yönlendir
                },
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Quiz Yap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}