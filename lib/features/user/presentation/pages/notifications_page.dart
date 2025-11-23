import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/network_manager.dart';
import '../../../../core/services/notification_service.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../models/notification_settings.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  NotificationSettings _settings = const NotificationSettings();
  bool _loading = true;
  bool _saving = false;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _loading = true);
    try {
      final settings = await NotificationSettings.load();
      
      // Always set local settings first (fallback if backend fails)
      _settings = settings;
      
      // Backend'den email notifications'ı yükle
      final state = context.read<AuthBloc>().state;
      if (state is AuthAuthenticated) {
        // Backend'den profil bilgisini çek (eğer varsa)
        try {
          final client = getIt<NetworkManager>();
          final response = await client.get('/api/ApiUserProfile');
          if (response.statusCode == 200 && response.data != null) {
            final emailNotifications = response.data['notificationsEnabled'] as bool? ?? true;
            // Update settings with backend emailNotifications if available
            _settings = settings.copyWith(emailNotifications: emailNotifications);
          }
        } catch (e) {
          // Backend'den yüklenemezse local ayarları kullan (zaten _settings = settings yapıldı)
        }
      }
      
      _selectedTime = TimeOfDay(
        hour: _settings.dailyReminderHour ?? 9,
        minute: _settings.dailyReminderMinute ?? 0,
      );
      
      setState(() => _loading = false);
    } catch (e) {
      // Even if local load fails, ensure _loading is set to false
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    HapticFeedback.lightImpact();
    
    try {
      // Local ayarları kaydet
      await _settings.save();
      
      // Backend'e email notifications'ı gönder
      try {
        final client = getIt<NetworkManager>();
        await client.put('/api/ApiUserProfile', data: {
          'emailNotifications': _settings.emailNotifications,
        });
      } catch (e) {
        // Backend hatası kritik değil, local ayarlar kaydedildi
      }
      
      // Bildirim servisini güncelle
      final notificationService = getIt<NotificationService>();
      await notificationService.updateSettings(_settings);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ayarlar kaydedildi')),
      );
      
      // Auth state'i yenile
      context.read<AuthBloc>().add(CheckAuthStatus());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydedilemedi')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _settings = _settings.copyWith(
          dailyReminderHour: picked.hour,
          dailyReminderMinute: picked.minute,
        );
      });
    }
  }

  Future<void> _testNotification() async {
    try {
      final notificationService = getIt<NotificationService>();
      
      // İzin kontrolü yap
      final hasPermission = await notificationService.areNotificationsEnabled();
      if (!hasPermission) {
        // İzin iste
        final granted = await notificationService.requestPermissions();
        if (!granted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bildirim izni verilmedi. Lütfen ayarlardan izin verin.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      }
      
      await notificationService.showNotification(
        id: 9999,
        title: 'Test Bildirimi',
        body: 'Bildirimler çalışıyor! 🎉',
        payload: 'test',
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test bildirimi gönderildi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bildirim gönderilemedi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bildirimler')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test Bildirimi',
            onPressed: _testNotification,
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Email Bildirimleri
            Card(
              child: SwitchListTile(
                value: _settings.emailNotifications,
                title: const Text('E‑posta bildirimleri'),
                subtitle: const Text('İlerleme, rozet ve duyuru bildirimleri'),
                onChanged: (v) => setState(() {
                  _settings = _settings.copyWith(emailNotifications: v);
                }),
              ),
            ),
            const SizedBox(height: 16),
            
            // Push Bildirimleri Ana Ayarı
            Card(
              child: SwitchListTile(
                value: _settings.pushNotificationsEnabled,
                title: const Text('Push bildirimleri'),
                subtitle: const Text('Uygulama içi bildirimleri aç/kapat'),
                onChanged: (v) => setState(() {
                  _settings = _settings.copyWith(pushNotificationsEnabled: v);
                }),
              ),
            ),
            const SizedBox(height: 8),
            
            // Bildirim Türleri (Push açıkken görünür)
            if (_settings.pushNotificationsEnabled) ...[
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _settings.progressNotifications,
                      title: const Text('İlerleme bildirimleri'),
                      subtitle: const Text('XP kazanma ve seviye atlama'),
                      onChanged: (v) => setState(() {
                        _settings = _settings.copyWith(progressNotifications: v);
                      }),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _settings.badgeNotifications,
                      title: const Text('Rozet bildirimleri'),
                      subtitle: const Text('Yeni rozet kazanıldığında'),
                      onChanged: (v) => setState(() {
                        _settings = _settings.copyWith(badgeNotifications: v);
                      }),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _settings.streakReminders,
                      title: const Text('Streak hatırlatmaları'),
                      subtitle: const Text('Günlük seri hatırlatmaları'),
                      onChanged: (v) => setState(() {
                        _settings = _settings.copyWith(streakReminders: v);
                      }),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _settings.dailyGoalReminders,
                      title: const Text('Günlük hedef hatırlatmaları'),
                      subtitle: const Text('Günlük okuma hedefi hatırlatmaları'),
                      onChanged: (v) => setState(() {
                        _settings = _settings.copyWith(dailyGoalReminders: v);
                      }),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _settings.quizResultNotifications,
                      title: const Text('Quiz sonuç bildirimleri'),
                      subtitle: const Text('Quiz tamamlandığında'),
                      onChanged: (v) => setState(() {
                        _settings = _settings.copyWith(quizResultNotifications: v);
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Günlük Hatırlatma Saati
              if (_settings.dailyGoalReminders) ...[
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Hatırlatma saati'),
                    subtitle: Text(
                      _selectedTime != null
                          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                          : '09:00',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _selectTime,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
            
            // Kaydet Butonu
            ElevatedButton.icon(
              onPressed: _saving ? null : _saveSettings,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
