import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../../data/repositories/vocabulary_repository_impl.dart';
import '../../domain/entities/vocabulary_word.dart';
import '../bloc/vocabulary_bloc.dart';
import '../bloc/vocabulary_event.dart';

class VocabularyWordDetailPage extends StatefulWidget {
  final int vocabWordId;
  final VocabularyWord? initialWord;
  const VocabularyWordDetailPage({super.key, required this.vocabWordId, this.initialWord});

  @override
  State<VocabularyWordDetailPage> createState() => _VocabularyWordDetailPageState();
}

class _VocabularyWordDetailPageState extends State<VocabularyWordDetailPage> {
  VocabularyWord? _word;
  bool _loading = true;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    // Use initial word if provided for immediate render
    if (widget.initialWord != null) {
      _word = widget.initialWord;
      _loading = false;
    }
    // Fetch latest in background
    _load();
  }

  Future<void> _load() async {
    try {
      final repository = getIt<VocabularyRepositoryImpl>();
      final word = await repository.getWordById(widget.vocabWordId);
      if (!mounted) return;
      setState(() {
        _word = word ?? _word; // keep existing if null
        _loading = _word == null; // still loading only if nothing to show
      });
      if (word == null && mounted) {
        // Show error message if word not found
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kelime bulunamadı'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Keep existing word if we already have one (e.g., initialWord)
        _word = _word;
      });
      
      // Show error message with more details
      final errorMsg = e.toString().contains('Kelime yüklenemedi')
          ? e.toString()
          : 'Kelime yüklenirken bir hata oluştu: ${e.toString()}';
      
      if (_word == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Tekrar Dene',
                  onPressed: () => _load(),
                ),
              ),
            );
          }
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} gün';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} saat';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} dakika';
    }
    return 'Şimdi';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Henüz yok';
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.isNegative) {
      return 'Geçmiş';
    }
    if (diff.inDays == 0) {
      return 'Bugün';
    } else if (diff.inDays == 1) {
      return 'Yarın';
    } else {
      return '${diff.inDays} gün sonra';
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
              : (_word == null)
                  ? const Center(child: Text('Kelime bulunamadı'))
                  : _buildContent(context, _word!),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, VocabularyWord word) {
    final tts = getIt<FlutterTts>();
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
                            tag: 'vocab_word_${word.id}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                word.word,
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
                            word.meaning,
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
                                await tts.speak(word.word);
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
                            await Clipboard.setData(ClipboardData(text: '${word.word} — ${word.meaning}'));
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
                            await Share.share('${word.word} — ${word.meaning}${(word.exampleSentence ?? '').isNotEmpty ? '\n\n"${word.exampleSentence}"' : ''}');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                if ((word.exampleSentence ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onLongPress: () async {
                      await Clipboard.setData(ClipboardData(text: word.exampleSentence!));
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Örnek cümle kopyalandı'))
                      );
                    },
                    child: _pill(context, label: '"${word.exampleSentence}"', subtle: true),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(context, label: word.status.displayName),
                    if (word.personalNote != null && word.personalNote!.isNotEmpty)
                      _pill(context, label: 'Not: ${word.personalNote}'),
                  ],
                ),
              ],
            ),
          ),

          // Sözlük Bilgisi (Açıklama, Eş/Zıt Anlamlılar)
          if ((word.description != null && word.description!.isNotEmpty) ||
              (word.synonyms.isNotEmpty) ||
              (word.antonyms.isNotEmpty)) ...[
            const SizedBox(height: 16),
            _glassCard(
              context,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sözlük Bilgisi',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  if (word.description != null && word.description!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      word.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                  if (word.synonyms.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Eş Anlamlılar',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: word.synonyms
                          .map((s) => _pill(context, label: s))
                          .toList(),
                    ),
                  ],
                  if (word.antonyms.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Zıt Anlamlılar',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: word.antonyms
                          .map((a) => _pill(context, label: a, subtle: true))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // SRS İstatistikleri
          const SizedBox(height: 16),
          _glassCard(
            context,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Öğrenme İstatistikleri',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Yeni kelime - henüz çalışılmadıysa özel UI göster
                if (word.reviewCount == 0) ...[
                  _buildNewWordPrompt(context),
                ] else ...[
                  // İstatistik verileri
                  _buildStatRow(
                    context,
                    'Toplam Tekrar',
                    '${word.reviewCount}',
                    Icons.repeat_rounded,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    context,
                    'Doğru Cevap',
                    '${word.correctCount}',
                    Icons.check_circle_rounded,
                    Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    context,
                    'Başarı Oranı',
                    '${(word.accuracyRate * 100).toStringAsFixed(1)}%',
                    Icons.trending_up_rounded,
                    Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    context,
                    'Ardışık Doğru',
                    '${word.consecutiveCorrectCount}',
                    Icons.stars_rounded,
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),
                  _buildStatRow(
                    context,
                    'Zorluk Seviyesi',
                    _getDifficultyLabel(word.difficultyLevel),
                    Icons.speed_rounded,
                    _getDifficultyColor(word.difficultyLevel),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    context,
                    'Son Tekrar',
                    word.lastReviewedAt != null
                        ? _formatDateTime(word.lastReviewedAt!)
                        : 'Henüz yapılmadı',
                    Icons.schedule_rounded,
                    Colors.teal,
                  ),
                  const SizedBox(height: 12),
                  _buildNextReviewInfo(context, word),
                ],
              ],
            ),
          ),

          // Öğrenme Durumu
          const SizedBox(height: 16),
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
                _buildStatusCard(context, word),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewWordPrompt(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch_rounded,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Yeni Kelime!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu kelimeyi henüz çalışmadınız.\nÇalışmaya başlamak için Kelime Defterim sayfasındaki çalışma bölümüne gidin.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // Kelime Defteri çalışma sayfasına yönlendir
              Navigator.pop(context);
            },
            icon: const Icon(Icons.school_rounded),
            label: const Text('Çalışmaya Başla'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextReviewInfo(BuildContext context, VocabularyWord word) {
    final isOverdue = word.isOverdue;
    final isDue = word.needsReview;
    final color = isOverdue ? Colors.red : (isDue ? Colors.orange : Colors.blue);
    final icon = isOverdue ? Icons.warning_rounded : (isDue ? Icons.notification_important_rounded : Icons.calendar_today_rounded);
    
    String message;
    if (word.nextReviewAt == null) {
      message = 'Hemen çalışılabilir';
    } else if (isOverdue) {
      message = 'Gecikmiş! ${_formatDateTime(word.nextReviewAt!)}';
    } else if (isDue) {
      message = 'Çalışma zamanı! ${_formatDateTime(word.nextReviewAt!)}';
    } else {
      message = '${_formatDateTime(word.nextReviewAt!)} (${_formatDuration(word.timeUntilNextReview)})';
    }
    
    return Column(
      children: [
        _buildStatRow(
          context,
          'Sonraki Tekrar',
          message,
          icon,
          color,
        ),
        if (isDue || isOverdue) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isOverdue 
                        ? 'Bu kelime tekrarı geçmiş! En kısa sürede çalışmanız önerilir.'
                        : 'Bu kelime bugün çalışılmaya hazır.',
                    style: TextStyle(
                      fontSize: 13,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getDifficultyLabel(double difficulty) {
    if (difficulty < 0.3) return 'Kolay';
    if (difficulty < 0.7) return 'Orta';
    return 'Zor';
  }

  Color _getDifficultyColor(double difficulty) {
    if (difficulty < 0.3) return Colors.green;
    if (difficulty < 0.7) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dk önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, VocabularyWord word) {
    final statusData = {
      VocabularyStatus.new_: {'label': 'Yeni', 'icon': Icons.fiber_new, 'color': Colors.blue, 'description': 'Henüz öğrenilmeye başlanmadı', 'progress': 0.0},
      VocabularyStatus.learning: {'label': 'Öğreniliyor', 'icon': Icons.school, 'color': Colors.orange, 'description': 'Aktif olarak öğreniliyor', 'progress': 0.33},
      VocabularyStatus.known: {'label': 'Biliyorum', 'icon': Icons.check_circle, 'color': Colors.green, 'description': 'Başarıyla öğrenildi', 'progress': 0.66},
      VocabularyStatus.mastered: {'label': 'Uzman', 'icon': Icons.star, 'color': Colors.purple, 'description': 'Mükemmel seviyede', 'progress': 1.0},
    };

    final currentData = statusData[word.status]!;
    final color = currentData['color'] as Color;
    final progress = currentData['progress'] as double;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
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
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  currentData['icon'] as IconData,
                  size: 24,
                  color: color,
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
                        color: color,
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
            ],
          ),
          const SizedBox(height: 16),
          // Progress indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Öğrenme İlerlemesi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 8),
              // Status progression
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProgressStep('Yeni', VocabularyStatus.new_, word.status, Colors.blue),
                  _buildProgressArrow(),
                  _buildProgressStep('Öğreniyorum', VocabularyStatus.learning, word.status, Colors.orange),
                  _buildProgressArrow(),
                  _buildProgressStep('Biliyorum', VocabularyStatus.known, word.status, Colors.green),
                  _buildProgressArrow(),
                  _buildProgressStep('Uzman', VocabularyStatus.mastered, word.status, Colors.purple),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String label, VocabularyStatus targetStatus, VocabularyStatus currentStatus, Color color) {
    final isActive = currentStatus.index >= targetStatus.index;
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? color : color.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? color : color.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressArrow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Icon(
        Icons.arrow_forward_rounded,
        size: 12,
        color: Colors.grey.withOpacity(0.5),
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

  Future<void> _delete() async {
    final word = _word;
    if (word == null) return;
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
                    '"${word.word}" kelimesini defterinizden silmek istediğinizden emin misiniz?',
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
      context.read<VocabularyBloc>().add(DeleteWord(wordId: word.id));
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }
}
