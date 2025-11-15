import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/data/models/user_profile.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/network_manager.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/widgets/badge_icon.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/cache/cache_manager.dart';
import '../../../auth/data/services/auth_service.dart' as auth;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<_LevelGoalData> _levelGoalFuture;
  late Future<List<_BadgeItem>> _badgesFuture;
  // Son başarılı değerleri tutarak geçici hatalarda UI'nin sıfırlanmasını önler
  UserProfile? _lastProfile;
  _LevelGoalData? _lastLevelGoal;
  _ProgressData? _lastProgress;
  List<_BadgeItem>? _lastBadges;
  int? _readingFinishedCount;
  int? _readingValidatedCount;
  final ImagePicker _imagePicker = ImagePicker();
  bool _wasAuthenticated = false; // Logout sonrası yönlendirme için kullanılır

  @override
  void initState() {
    super.initState();
    // Mevcut auth durumunu kaydet (logout kontrolü için)
    _wasAuthenticated = context.read<AuthBloc>().state is AuthAuthenticated;
    
    _levelGoalFuture = _fetchLevelAndGoals();
    _badgesFuture = _fetchBadges();

    // Prefetch reading counts (finished + validated) - sadece authenticated durumda
    if (_wasAuthenticated) {
      Future.microtask(() async {
        try {
          final api = getIt<ApiClient>();
          final respFinished = await api.getMeReadingCount(mode: 'finished');
          final respValidated = await api.getMeReadingCount(mode: 'validated');
          if (mounted) {
            setState(() {
              _readingFinishedCount = _extractCount(respFinished.data);
              _readingValidatedCount = _extractCount(respValidated.data);
            });
          }
        } catch (_) {}
      });
    }
  }

  /// Logout işlemini yönetir - tüm state'leri temizler ve home'a yönlendirir
  void _handleLogout() {
    if (!mounted) return;
    
    // Tüm state'leri temizle (setState çağırmadan - gereksiz yenilenmeyi önlemek için)
    _lastProfile = null;
    _lastLevelGoal = null;
    _lastProgress = null;
    _lastBadges = null;
    _readingFinishedCount = null;
    _readingValidatedCount = null;
    _wasAuthenticated = false;
    
    // Future'ları olduğu gibi bırak (late oldukları için null yapamayız)
    // Sayfa zaten kapanacak, gereksiz API çağrıları olmayacak
    
    // Kullanıcıyı bilgilendir
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Çıkış yapıldı'),
        duration: Duration(seconds: 1),
      ),
    );
    
    // Home'a yönlendir (login sayfasına değil - misafir modu için)
    // Delay'i kaldırdık - hemen yönlendir (gereksiz yenilenmeyi önlemek için)
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: const [],
      ),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // Login olduğunda - profil verilerini güncelle
            if (state is AuthAuthenticated) {
              _wasAuthenticated = true;
              _lastProfile = state.user;
              setState(() {
                _levelGoalFuture = _fetchLevelAndGoals();
                _badgesFuture = _fetchBadges();
              });
            } 
            // Logout olduğunda - state'i temizle ve yönlendir
            else if (state is AuthUnauthenticated) {
              // Eğer daha önce authenticated idiyse, bu bir logout işlemidir
              if (_wasAuthenticated) {
                _handleLogout();
              }
              // Eğer hiç authenticated olmamışsa, bu sayfaya erişim izni yoktur
              // BlocBuilder'da zaten login'e yönlendirme yapılacak
            } 
            // Auth hatası durumunda kullanıcıyı bilgilendir
            else if (state is AuthErrorState) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
            // Auth kontrolü - sadece authenticated kullanıcılar profil sayfasını görebilir
            
            // Loading/Checking durumunda loading göster
            if (state is AuthChecking || state is AuthLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            // Unauthenticated durumunda login sayfasına yönlendir
            if (state is AuthUnauthenticated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              });
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            // Sadece AuthAuthenticated durumunda profil sayfasını göster
            if (state is! AuthAuthenticated) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            // AuthAuthenticated durumunda - profil bilgilerini güncelle ve göster
            final authenticatedUser = state.user;
            _lastProfile = authenticatedUser;
            
            // Profil bilgisi yoksa loading göster (bu durum olmamalı ama güvenlik için)
            if (_lastProfile == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            
            final UserProfile profile = _lastProfile!;

            return FutureBuilder<_LevelGoalData>(
              future: _levelGoalFuture,
              builder: (context, snapshot) {
                final _LevelGoalData? levelInfo = snapshot.data ?? _lastLevelGoal;
                if (snapshot.hasData && snapshot.data != null) {
                  _lastLevelGoal = snapshot.data;
                }
                final int profileXP = profile.experiencePoints ?? 0;
                final int apiXP = levelInfo?.currentXP ?? 0;
                // API 0 döndüyse veya veri yoksa ekranda 0'a düşme; mevcut/profil değerini koru
                final int displayedXP = apiXP > 0 ? apiXP : profileXP;
                final double xpProgress = levelInfo?.xpProgress ?? _fallbackProgress(displayedXP);
                
                // Level bilgilerini hazırla - hem numeric hem de label
                final String levelDisplayText = _lastProfile?.levelDisplay
                    ?? _lastProfile?.levelName
                    ?? levelInfo?.levelLabel
                    ?? '—';
                
                // Streak bilgilerini hazırla - robust fallback ile
                final int? streakDaysVal = levelInfo?.streakDays ?? _lastLevelGoal?.streakDays ?? profile.currentStreak;
                final int? longestStreakVal = levelInfo?.longestStreak ?? _lastLevelGoal?.longestStreak ?? profile.longestStreak;
                final String streakLabel = _formatStreakDisplay(streakDaysVal, longestStreakVal);
                
                // Streak progress hesapla - _StatsStrip widget'ında hesaplanıyor

                final String xpValue = displayedXP.toString();

                final booksCount = _readingValidatedCount ?? _readingFinishedCount ?? (profile.totalReadBooks ?? 0);
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                        Theme.of(context).colorScheme.background,
                      ],
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Hero(
                                  tag: 'avatar_${profile.id}',
                                  child: CircleAvatar(
                                    radius: 56,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 52,
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      backgroundImage: profile.profileImageUrl != null
                                          ? NetworkImage(profile.profileImageUrl!)
                                          : null,
                                      child: profile.profileImageUrl == null
                                          ? Text(
                                              profile.userName.isNotEmpty ? profile.userName[0] : 'U',
                                              style: TextStyle(
                                                fontSize: 28,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Material(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => _onChangePhotoTap(),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6.0),
                                        child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            profile.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Builder(
                          builder: (context) {
                            final String display = profile.displayName.trim();
                            final String username = profile.userName.trim();
                            final String email = profile.email.trim();
                            final bool isSameName = display.isNotEmpty && username.isNotEmpty && display.toLowerCase() == username.toLowerCase();
                            // Priority: show email if available; otherwise show @username only if it's different from display name
                            if (email.isNotEmpty) {
                              return Center(
                                child: Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              );
                            } else if (username.isNotEmpty && !isSameName) {
                              return Center(
                                child: Text(
                                  '@$username',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Joined: ${_formatJoined(profile.createdAt)}',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _StatsStrip(
                          levelLabel: levelDisplayText,
                          xp: xpValue,
                          books: booksCount.toString(),
                          streak: streakLabel,
                          streakProgress: 0,
                          streakDays: streakDaysVal,
                          longestStreak: longestStreakVal,
                        ),
                        const SizedBox(height: 20),
                        _LevelProgressBar(
                          progress: xpProgress,
                          currentXP: displayedXP,
                          xpForNextLevel: levelInfo?.xpForNextLevel ?? 1000,
                        ),
                        const SizedBox(height: 24),
                        const Text('Rozetler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        FutureBuilder<List<_BadgeItem>>(
                          future: _badgesFuture,
                          builder: (context, badgeSnap) {
                            final items = badgeSnap.data ?? _lastBadges ?? [];
                            if (badgeSnap.hasData && (badgeSnap.data?.isNotEmpty ?? false)) {
                              _lastBadges = badgeSnap.data;
                            }
                            if (items.isEmpty) {
                              return _buildBadgesPlaceholder(context);
                            }
                            final preview = items.take(6).toList();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: preview.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1,
                                  ),
                                  itemBuilder: (context, index) {
                                    final b = preview[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 36,
                                              height: 36,
                                              child: BadgeIcon(
                                                name: b.name,
                                                imageUrl: b.imageUrl,
                                                earned: b.isEarned,
                                                size: 36,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              b.name,
                                              style: const TextStyle(fontSize: 12, height: 1.2, fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.pushNamed(context, '/badges'),
                                    child: const Text('Tüm rozetleri gör'),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile-details'),
                          child: _settingsTile(context, Icons.person_outline, 'Profile Details'),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/notifications'),
                          child: _settingsTile(context, Icons.notifications_outlined, 'Notifications'),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/privacy'),
                          child: _settingsTile(context, Icons.privacy_tip_outlined, 'Privacy'),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/learning-list'),
                          child: _settingsTile(context, Icons.book_outlined, 'Learning List'),
                        ),
                        const SizedBox(height: 12),
                        _buildStatRow(context, booksCount, profile),
                        const SizedBox(height: 24),
                        // Çıkış yap butonu - authenticated durumda gösterilir (zaten burada authenticated olmalıyız)
                        SafeArea(
                          top: false,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: SizedBox(
                              height: 52,
                              child: CupertinoTheme(
                                data: CupertinoTheme.of(context).copyWith(
                                  primaryColor: CupertinoColors.systemRed,
                                ),
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  color: CupertinoColors.systemRed,
                                  borderRadius: BorderRadius.circular(14),
                                  onPressed: () {
                                    // Logout işlemini başlat
                                    context.read<AuthBloc>().add(LogoutRequested());
                                  },
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(CupertinoIcons.power, color: CupertinoColors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Çıkış Yap',
                                        style: TextStyle(
                                          color: CupertinoColors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ),
    );
  }

  Future<void> _onChangePhotoTap() async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeriden seç'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUpload(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Kamera ile çek'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _pickAndUpload(ImageSource.camera);
                },
              ),
              if (_lastProfile?.profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.remove_red_eye_outlined),
                  title: const Text('Fotoğrafı görüntüle'),
                  onTap: () {
                    Navigator.pop(ctx);
                    final url = _lastProfile!.profileImageUrl!;
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        opaque: false,
                        pageBuilder: (_, __, ___) => GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            color: Colors.black.withValues(alpha: 0.9),
                            child: Center(
                              child: Hero(
                                tag: 'avatar_${_lastProfile?.id}',
                                child: Image.network(url),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(source: source, maxWidth: 1200, imageQuality: 85);
      if (picked == null) return;

      File file = File(picked.path);
      file = await _downscaleImage(file, maxWidth: 1200, quality: 85);

      final service = getIt<auth.AuthServiceProtocol>();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fotoğraf yükleniyor...')));
      await service.updateProfileImage(file);
      if (!mounted) return;
      // Refresh profile and caches
      try {
        final cacheManager = getIt<CacheManager>();
        cacheManager.removeData('user/profile');
      } catch (_) {}
      context.read<AuthBloc>().add(CheckAuthStatus());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil fotoğrafı güncellendi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fotoğraf yüklenemedi')));
    }
  }

  Future<File> _downscaleImage(File file, {int maxWidth = 1200, int quality = 85}) async {
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return file;
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return file;

      final int targetW = math.min(maxWidth, decoded.width);
      if (decoded.width <= targetW) {
        // Just re-encode to make sure it's JPEG with desired quality
        final encoded = img.encodeJpg(decoded, quality: quality);
        final dir = await getTemporaryDirectory();
        final out = File('${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await out.writeAsBytes(encoded, flush: true);
        return out;
      }

      final resized = img.copyResize(decoded, width: targetW);
      final encoded = img.encodeJpg(resized, quality: quality);
      final dir = await getTemporaryDirectory();
      final out = File('${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await out.writeAsBytes(encoded, flush: true);
      return out;
    } catch (_) {
      return file;
    }
  }

  int? _extractCount(dynamic data) {
    try {
      final root = data is Map<String, dynamic> ? data : <String, dynamic>{};
      final d = root['data'] is Map<String, dynamic> ? root['data'] as Map<String, dynamic> : {};
      final c = d['count'];
      if (c is num) return c.toInt();
      if (c is String) return int.tryParse(c);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<_LevelGoalData> _fetchLevelAndGoals() async {
    try {
      final client = getIt<NetworkManager>();
      final levelResp = await client.get('/api/ApiGamification/level');
      final goalsResp = await client.get('/api/ApiProgressStats/goals');
      
      // Streak bilgilerini yeni endpoint'ten al
      int? streakDays;
      int? longestStreak;
      try {
        final streakResp = await client.get('/api/ApiProgressStats/streak');
        final sroot = streakResp.data is Map<String, dynamic> ? streakResp.data as Map<String, dynamic> : {};
        final sdat = sroot['data'] is Map<String, dynamic> ? sroot['data'] as Map<String, dynamic> : {};
        streakDays = _asNum(sdat['currentStreak'] ?? sdat['CurrentStreak'] ?? sdat['streak']).toInt();
        longestStreak = _asNum(sdat['longestStreak'] ?? sdat['LongestStreak']).toInt();
      } catch (_) {
        // Streak endpoint'i çalışmazsa goals'dan dene
        try {
          final groot = goalsResp.data is Map<String, dynamic> ? goalsResp.data as Map<String, dynamic> : {};
          final gdat = groot['data'] is Map<String, dynamic> ? groot['data'] as Map<String, dynamic> : {};
          streakDays = _asNum(gdat['streakDays'] ?? gdat['currentStreak'] ?? gdat['streak']).toInt();
          longestStreak = _asNum(gdat['longestStreak'] ?? gdat['LongestStreak']).toInt();
        } catch (_) {}
      }

      double xpProgress = 0;
      String? levelLabel;
      int? currentXP;
      int? currentLevel;

      final lroot = levelResp.data is Map<String, dynamic> ? levelResp.data as Map<String, dynamic> : {};
      final ldat = lroot['data'] is Map<String, dynamic> ? lroot['data'] as Map<String, dynamic> : {};
      
      // XP bilgilerini al
      final dynamic currentXPRaw = ldat['currentXP'] ?? ldat['CurrentXP'] ?? ldat['totalXP'] ?? ldat['TotalXP'];
      final currentXPd = _asNum(currentXPRaw).toDouble();
      final dynamic xpForNextRaw = ldat['xpForNextLevel'] ?? ldat['XPForNextLevel'] ?? 1000;
      // Treat API value as remaining XP to next level; derive target XP
      final double xpRemaining = _asNum(xpForNextRaw, 1000).toDouble();
      final dynamic progressRaw = ldat['progressPercentage'] ?? ldat['ProgressPercentage'];
      // Normalize progress: accept either 0..1 or 0..100 and clamp to 0..1
      double xpProgressCandidate;
      if (progressRaw != null) {
        final double pv = _asNum(progressRaw).toDouble();
        final double normalized = pv > 1 ? (pv / 100.0) : pv; // if 37 -> 0.37
        xpProgressCandidate = normalized.clamp(0.0, 1.0).toDouble();
      } else {
        xpProgressCandidate = -1; // force fallback
      }
      
      // Compute target XP and progress if API progress missing
      final double xpTargetD = (currentXPd + xpRemaining).clamp(1, double.infinity);
      xpProgress = (xpProgressCandidate > 0)
          ? xpProgressCandidate
          : ((xpTargetD > 0) ? (currentXPd / xpTargetD).clamp(0, 1).toDouble() : 0);
      currentXP = currentXPd.toInt();
      
      // Level bilgilerini al - hem label hem de numeric değer
      levelLabel = (ldat['currentLevelEnglish'] ?? ldat['CurrentLevelEnglish'] ?? ldat['currentLevel'] ?? ldat['CurrentLevel'] ?? 'Level').toString();
      
      // Numeric level değerini hesapla - XP'ye göre
      if (currentXP > 0) {
        // Basit level hesaplama: her 1000 XP = 1 level
        currentLevel = ((currentXP - 1) ~/ 1000) + 1;
      }

      final result = _LevelGoalData(
        levelLabel: levelLabel, 
        currentXP: currentXP, 
        xpProgress: xpProgress, 
        streakDays: streakDays,
        currentLevel: currentLevel,
        longestStreak: longestStreak,
        xpForNextLevel: xpTargetD.toInt(),
      );
      _lastLevelGoal = result;
      return result;
    } catch (_) {
      // Ağ/401 durumunda UI'yı sıfırlamamak için son bilinen profilden türet
      if (_lastLevelGoal != null) return _lastLevelGoal!;
      final xp = _lastProfile?.experiencePoints ?? 0;
      final level = xp > 0 ? ((xp - 1) ~/ 1000) + 1 : 1;
      return _LevelGoalData(
        levelLabel: 'Level $level',
        currentXP: xp,
        xpProgress: _fallbackProgress(xp),
        streakDays: null,
        currentLevel: level,
        longestStreak: null,
        xpForNextLevel: 1000,
      );
    }
  }

  num _asNum(dynamic value, [num fallback = 0]) {
    if (value == null) return fallback;
    if (value is num) return value;
    if (value is String) {
      final p = num.tryParse(value);
      if (p != null) return p;
    }
    return fallback;
  }

  Future<_ProgressData> _fetchProgress() async {
    try {
      final client = getIt<NetworkManager>();
      final resp = await client.get('/api/ApiProgressStats/detailed');
      final root = resp.data is Map<String, dynamic> ? resp.data as Map<String, dynamic> : {};
      final data = root['data'] is Map<String, dynamic> ? root['data'] as Map<String, dynamic> : {};
      final map = (data['activityTypeDistribution'] ?? data['ActivityTypeDistribution']) as Map<String, dynamic>?;
      if (map == null || map.isEmpty) {
        return const _ProgressData(reading: 0, listening: 0, speaking: 0);
      }
      double read = 0, listen = 0, speak = 0;
      map.forEach((k, v) {
        final key = k.toString().toLowerCase();
        final val = (v as num?)?.toDouble() ?? 0;
        if (key.contains('read')) read = val; else if (key.contains('listen')) listen = val; else if (key.contains('speak')) speak = val;
      });
      final total = (read + listen + speak);
      if (total <= 0) {
        return const _ProgressData(reading: 0, listening: 0, speaking: 0);
      }
      final result = _ProgressData(reading: read / total, listening: listen / total, speaking: speak / total);
      _lastProgress = result;
      return result;
    } catch (_) {
      return _lastProgress ?? const _ProgressData(reading: 0, listening: 0, speaking: 0);
    }
  }

  Future<List<_BadgeItem>> _fetchBadges() async {
    try {
      final client = getIt<NetworkManager>();
      // Backend'de doğrudan badges endpointi yok; önerilen yol: /api/ApiGamification/badges
      // Geçici: varsa kullan; yoksa boş liste dön
      final resp = await client.get('/api/ApiGamification/badges');
      final root = resp.data is Map<String, dynamic> ? resp.data as Map<String, dynamic> : {};
      final list = (root['data'] ?? root['Data']) as List<dynamic>?;
      if (list == null) return _lastBadges ?? [];
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return _BadgeItem(
          name: (m['name'] ?? m['Name'] ?? '') as String,
          imageUrl: _normalizeImageUrl((m['imageUrl'] ?? m['ImageUrl']) as String?),
          isEarned: ((m['isEarned'] ?? m['IsEarned']) as bool?) ?? false,
        );
      }).toList();
    } catch (_) {
      return _lastBadges ?? [];
    }
  }

  double _fallbackProgress(int xp) {
    const threshold = 1000.0;
    return ((xp % threshold) / threshold).clamp(0.0, 1.0);
  }

  String _formatJoined(DateTime dt) {
    final d = dt.toLocal();
    final yyyy = d.year.toString().padLeft(4, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$dd-$mm-$yyyy';
  }

  String _formatStreakDisplay(int? streakDays, int? longestStreak) {
    if (streakDays == null || streakDays == 0) return '—';
    if (streakDays == 1) return '1 gün';
    return '$streakDays gün';
  }

  Widget _buildStatRow(BuildContext context, int booksCount, UserProfile profile) {
    return Row(
      children: [
        _statCard(context, Icons.menu_book, 'Okunan', '$booksCount'),
        const SizedBox(width: 12),
        _statCard(context, Icons.quiz, 'Quiz Puanı', '${profile.totalQuizScore ?? 0}'),
        const SizedBox(width: 12),
        _statCard(context, Icons.trending_up, 'Toplam XP', '${profile.experiencePoints ?? 0}'),
      ],
    );
  }

  Widget _statCard(BuildContext context, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesPlaceholder(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 6),
                const Text('Badge', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }

  String? _normalizeImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('/')) return '${AppConfig.apiBaseUrl}$path';
    return '${AppConfig.apiBaseUrl}/$path';
  }

  Widget _settingsTile(BuildContext context, IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

class _LevelGoalData {
  final String? levelLabel;
  final int? currentXP;
  final double xpProgress;
  final int? streakDays;
  final int? currentLevel;
  final int? longestStreak;
  final int xpForNextLevel;

  _LevelGoalData({
    required this.levelLabel,
    required this.currentXP,
    required this.xpProgress,
    required this.streakDays,
    required this.currentLevel,
    this.longestStreak,
    this.xpForNextLevel = 1000,
  });
}

class _ProgressData {
  final double reading;
  final double listening;
  final double speaking;
  const _ProgressData({required this.reading, required this.listening, required this.speaking});
}

class _BadgeItem {
  final String name;
  final String? imageUrl;
  final bool isEarned;
  _BadgeItem({required this.name, required this.imageUrl, required this.isEarned});
}

class _StatsStrip extends StatelessWidget {
  final String levelLabel;
  final String xp;
  final String books;
  final String streak;
  final double streakProgress;
  final int? streakDays;
  final int? longestStreak;

  const _StatsStrip({
    required this.levelLabel,
    required this.xp,
    required this.books,
    required this.streak,
    required this.streakProgress,
    required this.streakDays,
    required this.longestStreak,
  });

  String _getStreakMotivation(int? streakDays) {
    if (streakDays == null || streakDays == 0) return 'İlk adımı at!';
    if (streakDays == 1) return 'Harika başlangıç!';
    if (streakDays < 7) return 'Devam et!';
    if (streakDays < 14) return '1 hafta tamamlandı!';
    if (streakDays < 30) return '2 hafta tamamlandı!';
    if (streakDays < 100) return '1 ay tamamlandı!';
    return 'Efsanevi streak!';
  }

  static double calculateProgress(int? streakDays, int? longestStreak) {
    if (streakDays == null || streakDays == 0) return 0.0;
    if (longestStreak == null || longestStreak == 0) return 1.0; // Streak yoksa tamamlandı

    final double currentStreakProgress = (streakDays / longestStreak).clamp(0.0, 1.0);
    return currentStreakProgress;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _stat(context, Icons.stairs, levelLabel, 'Level'),
              const SizedBox(width: 12),
              _stat(context, Icons.star, xp, 'XP'),
              const SizedBox(width: 12),
              _stat(context, Icons.menu_book, books, 'Books'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            streak,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (longestStreak != null && longestStreak! > 0) ...[
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(color: Colors.grey[600])),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'en uzun ${longestStreak} gün',
                              style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (streakProgress > 0) ...[
            // Bars removed per UX request
          ],
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, IconData icon, String value, String label, {bool isLarge = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: isLarge ? 24 : 20),
          const SizedBox(height: 6),
          Text(
            value, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: isLarge ? 22 : 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: isLarge ? 14 : 12)),
        ],
      ),
    );
  }
}

class _LearningProgressCard extends StatelessWidget {
  final double reading;
  final double listening;
  final double speaking;

  const _LearningProgressCard({
    required this.reading,
    required this.listening,
    required this.speaking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Learning Progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _ring(context, reading, 'Reading'),
              const SizedBox(width: 12),
              _ring(context, listening, 'Listening'),
              const SizedBox(width: 12),
              _ring(context, speaking, 'Speaking'),
            ],
          )
        ],
      ),
    );
  }

  Widget _ring(BuildContext context, double value, String label) {
    final clamped = value.clamp(0.0, 1.0).toDouble();
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: clamped,
                  strokeWidth: 8,
                  backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                ),
                Text('${(clamped * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}



class _LearningProgressSkeleton extends StatelessWidget {
  const _LearningProgressSkeleton();

  @override
  Widget build(BuildContext context) {
    Color shimmerBase = Theme.of(context).colorScheme.surface;
    Color shimmerHighlight = Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 20, width: 160, decoration: BoxDecoration(color: shimmerHighlight, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 60, decoration: BoxDecoration(color: shimmerHighlight, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 60, decoration: BoxDecoration(color: shimmerHighlight, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: shimmerBase,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(height: 14, width: 60, decoration: BoxDecoration(color: shimmerHighlight, borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LevelProgressBar extends StatelessWidget {
  final double progress; // 0..1
  final int currentXP;
  final int xpForNextLevel;

  const _LevelProgressBar({
    required this.progress,
    required this.currentXP,
    required this.xpForNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final int percent = (progress.clamp(0, 1) * 100).round();
    final int xpRemaining = (xpForNextLevel - currentXP).clamp(0, xpForNextLevel);
    
    // Motivational message based on progress
    String motivationMessage;
    String emoji;
    if (percent >= 90) {
      motivationMessage = 'Neredeyse bir sonraki seviyeye ulaşacaksın! 🎉';
      emoji = '🔥';
    } else if (percent >= 70) {
      motivationMessage = 'Harika gidiyorsun! Devam et 💪';
      emoji = '⭐';
    } else if (percent >= 50) {
      motivationMessage = 'Yarı yoldasın! İlerlemen süper 🚀';
      emoji = '📈';
    } else if (percent >= 25) {
      motivationMessage = 'İyi bir başlangıç yaptın! 👏';
      emoji = '🎯';
    } else {
      motivationMessage = 'Yeni seviyeye doğru yolculuk başladı!';
      emoji = '🌟';
    }
    
    // Estimated time to next level (assuming 50 XP per day average)
    final int daysToNextLevel = (xpRemaining / 50).ceil();
    final String timeEstimate = daysToNextLevel == 0 
        ? 'Bugün tamamla!' 
        : daysToNextLevel == 1
          ? '~1 gün'
          : '~$daysToNextLevel gün';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Bir Sonraki Seviye',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '%$percent',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            motivationMessage,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0, 1),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$currentXP',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    ' / $xpForNextLevel XP',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (xpRemaining > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeEstimate,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (xpRemaining > 0 && xpRemaining <= 100) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sadece $xpRemaining XP kaldı! Hemen bir quiz çöz!',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
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
}
