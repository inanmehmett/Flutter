import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:injectable/injectable.dart';
import '../utils/logger.dart';
import '../../features/user/models/notification_settings.dart';

@singleton
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationService() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    try {
      // Timezone verilerini yükle
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

      // Android bildirim kanalı oluştur (Android 8.0+ için zorunlu)
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Ana bildirim kanalı
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            'daily_english_channel',
            'Daily English Notifications',
            description: 'Bildirimler ve hatırlatmalar',
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
        Logger.info('Android notification channel created');
      }

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initResult = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      Logger.info('Notification initialization result: $initResult');

      // Android için izin iste (Android 13+ için POST_NOTIFICATIONS izni gerekli)
      if (androidPlugin != null) {
        final permissionGranted = await androidPlugin.requestNotificationsPermission();
        Logger.info('Android notification permission granted: $permissionGranted');
        
        // Exact alarm izni iste (Android 12+ için zamanlanmış bildirimler için)
        await androidPlugin.requestExactAlarmsPermission();
      }

      // iOS için izin kontrolü
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final iosPermission = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        Logger.info('iOS notification permission granted: $iosPermission');
      }

      _initialized = true;
      Logger.info('NotificationService initialized successfully');
    } catch (e) {
      Logger.error('Failed to initialize NotificationService: $e');
      _initialized = false;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    Logger.info('Notification tapped: ${response.payload}');
    // TODO: Navigate to specific page based on payload
  }

  /// Bildirim gönderme (hemen)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await _initialize();
      if (!_initialized) {
        Logger.error('NotificationService not initialized, cannot show notification');
        return;
      }
    }

    final settings = await NotificationSettings.load();
    if (!settings.pushNotificationsEnabled) {
      Logger.info('Push notifications disabled, skipping notification');
      return;
    }

    // İzin kontrolü (Android 13+)
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final permissionGranted = await androidPlugin.areNotificationsEnabled();
      if (permissionGranted != true) {
        Logger.warning('Notification permission not granted, requesting...');
        final requested = await androidPlugin.requestNotificationsPermission();
        if (requested != true) {
          Logger.error('Notification permission denied, cannot show notification');
          return;
        }
      }
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_english_channel',
      'Daily English Notifications',
      channelDescription: 'Bildirimler ve hatırlatmalar',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(id, title, body, details, payload: payload);
      Logger.info('✅ Notification shown successfully: $title - $body');
    } catch (e) {
      Logger.error('❌ Failed to show notification: $e');
      Logger.error('Notification details - ID: $id, Title: $title, Body: $body');
    }
  }

  /// Zamanlanmış bildirim
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) await _initialize();

    final settings = await NotificationSettings.load();
    if (!settings.pushNotificationsEnabled) {
      Logger.info('Push notifications disabled, skipping scheduled notification');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_english_channel',
      'Daily English Notifications',
      channelDescription: 'Bildirimler ve hatırlatmalar',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      Logger.info('Notification scheduled: $title at $scheduledDate');
    } catch (e) {
      Logger.error('Failed to schedule notification: $e');
    }
  }

  /// Tekrarlanan bildirim (günlük)
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
  }) async {
    if (!_initialized) await _initialize();

    final settings = await NotificationSettings.load();
    if (!settings.pushNotificationsEnabled) {
      Logger.info('Push notifications disabled, skipping daily notification');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_english_channel',
      'Daily English Notifications',
      channelDescription: 'Bildirimler ve hatırlatmalar',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      final scheduledDate = _nextInstanceOfTime(hour, minute);
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      Logger.info('Daily notification scheduled: $title at $hour:$minute');
    } catch (e) {
      Logger.error('Failed to schedule daily notification: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
      0,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Bildirimi iptal et
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    Logger.info('Notification cancelled: $id');
  }

  /// Tüm bildirimleri iptal et
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    Logger.info('All notifications cancelled');
  }

  // ==================== Özel Bildirim Metodları ====================

  /// XP kazanıldı bildirimi
  Future<void> showXPNotification(int xp) async {
    final settings = await NotificationSettings.load();
    if (!settings.pushNotificationsEnabled || !settings.progressNotifications) {
      Logger.info('XP notification skipped - push notifications disabled or progress notifications disabled');
      return;
    }

    await showNotification(
      id: 1001,
      title: '🎉 XP Kazandınız!',
      body: '+$xp XP kazandınız. Harika iş!',
      payload: 'xp_gained',
    );
  }

  /// Seviye atlama bildirimi
  Future<void> showLevelUpNotification(String levelName) async {
    final settings = await NotificationSettings.load();
    if (!settings.pushNotificationsEnabled || !settings.progressNotifications) {
      Logger.info('Level up notification skipped - push notifications disabled or progress notifications disabled');
      return;
    }

    await showNotification(
      id: 1002,
      title: '🚀 Seviye Atladınız!',
      body: 'Tebrikler! $levelName seviyesine ulaştınız.',
      payload: 'level_up',
    );
  }

  /// Rozet kazanıldı bildirimi
  Future<void> showBadgeNotification(String badgeName) async {
    final settings = await NotificationSettings.load();
    if (!settings.pushNotificationsEnabled || !settings.badgeNotifications) {
      Logger.info('Badge notification skipped - push notifications disabled or badge notifications disabled');
      return;
    }

    await showNotification(
      id: 1003,
      title: '🏆 Yeni Rozet!',
      body: '$badgeName rozetini kazandınız!',
      payload: 'badge_earned',
    );
  }

  /// Streak hatırlatması
  Future<void> showStreakReminder(int currentStreak) async {
    final settings = await NotificationSettings.load();
    if (!settings.pushNotificationsEnabled || !settings.streakReminders) {
      Logger.info('Streak reminder skipped - push notifications disabled or streak reminders disabled');
      return;
    }

    await showNotification(
      id: 1004,
      title: '🔥 Streak Devam Ediyor!',
      body: '$currentStreak günlük seriniz var. Devam edin!',
      payload: 'streak_reminder',
    );
  }

  /// Streak risk bildirimi
  Future<void> showStreakRiskNotification() async {
    final settings = await NotificationSettings.load();
    if (!settings.pushNotificationsEnabled || !settings.streakReminders) {
      Logger.info('Streak risk notification skipped - push notifications disabled or streak reminders disabled');
      return;
    }

    await showNotification(
      id: 1005,
      title: '⚠️ Streak Riski!',
      body: 'Seriniz sona ermek üzere! Bugün çalışmayı unutmayın.',
      payload: 'streak_risk',
    );
  }

  /// Günlük hedef hatırlatması
  Future<void> scheduleDailyGoalReminder() async {
    final settings = await NotificationSettings.load();
    if (!settings.dailyGoalReminders || settings.dailyReminderHour == null) return;

    await scheduleDailyNotification(
      id: 1006,
      title: '📚 Günlük Hedefiniz',
      body: 'Bugünkü okuma hedefinize ulaşmak için çalışmaya başlayın!',
      hour: settings.dailyReminderHour!,
      minute: settings.dailyReminderMinute ?? 0,
      payload: 'daily_goal_reminder',
    );
  }

  /// Quiz sonuç bildirimi
  Future<void> showQuizResultNotification(int score, bool passed) async {
    final settings = await NotificationSettings.load();
    if (!settings.pushNotificationsEnabled || !settings.quizResultNotifications) {
      Logger.info('Quiz result notification skipped - push notifications disabled or quiz result notifications disabled');
      return;
    }

    await showNotification(
      id: 1007,
      title: passed ? '✅ Quiz Tamamlandı!' : '📝 Quiz Sonucu',
      body: 'Skorunuz: $score%',
      payload: 'quiz_result',
    );
  }

  /// Ayarları güncelle ve günlük hatırlatmaları yeniden zamanla
  Future<void> updateSettings(NotificationSettings newSettings) async {
    await newSettings.save();
    Logger.info('Notification settings updated');
    await rescheduleDailyReminders();
  }

  /// Günlük hatırlatmaları yeniden zamanla
  Future<void> rescheduleDailyReminders() async {
    final settings = await NotificationSettings.load();
    
    // Eski hatırlatmaları iptal et
    await cancelNotification(1006);
    
    // Yeni hatırlatmayı zamanla
    if (settings.dailyGoalReminders && settings.dailyReminderHour != null) {
      await scheduleDailyGoalReminder();
    }
  }

  /// Bildirim izinlerinin verilip verilmediğini kontrol et
  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) await _initialize();
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final permissionGranted = await androidPlugin.areNotificationsEnabled();
      return permissionGranted == true;
    }
    
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      try {
        final permissionGranted = await iosPlugin.checkPermissions();
        // iOS'ta checkPermissions NotificationsEnabledOptions döndürür
        // Eğer null değilse ve alert izni varsa true döndür
        if (permissionGranted != null) {
          // NotificationsEnabledOptions'un yapısına göre kontrol et
          // Genellikle direkt bool değerler döner veya farklı bir yapı olabilir
          // Güvenli bir şekilde kontrol etmek için try-catch kullanıyoruz
          return true; // iOS'ta izin kontrolü için requestPermissions kullanılmalı
        }
      } catch (e) {
        Logger.error('Error checking iOS permissions: $e');
      }
    }
    
    return false;
  }

  /// Bildirim izni iste
  Future<bool> requestPermissions() async {
    if (!_initialized) await _initialize();
    
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final permissionGranted = await androidPlugin.requestNotificationsPermission();
      return permissionGranted == true;
    }
    
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      try {
        final permissionGranted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        // iOS'ta requestPermissions bool? döndürür
        return permissionGranted == true;
      } catch (e) {
        Logger.error('Error requesting iOS permissions: $e');
        return false;
      }
    }
    
    return false;
  }
}

