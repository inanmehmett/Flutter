# 📊 Analytics & Crashlytics Kullanım Kılavuzu

## 🎯 Genel Bakış

Kendi Analytics + Crashlytics sistemimiz tamamen bağımsız çalışıyor. Firebase veya Sentry gibi external bağımlılıklar yok.

---

## 📱 AnalyticsService Kullanımı

### 1. Screen View Tracking (Otomatik)

**AnalyticsMixin ile:**

```dart
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AnalyticsMixin {
  @override
  String get screenName => 'home'; // Otomatik track edilir

  void _onButtonClick() {
    trackAction('button_clicked', parameters: {'button': 'start_reading'});
  }
}
```

**Manuel:**

```dart
final analytics = getIt<AnalyticsService>();
await analytics.trackScreenView('profile_page');
```

### 2. User Action Tracking

```dart
analytics.trackAction('book_opened', parameters: {
  'book_id': bookId,
  'book_title': bookTitle,
});
```

### 3. Feature Usage Tracking

```dart
analytics.trackFeatureUsage('vocabulary_study', parameters: {
  'mode': 'quiz',
  'word_count': 10,
});
```

### 4. Conversion Tracking

```dart
analytics.trackConversion('subscription_purchased', parameters: {
  'plan': 'premium_monthly',
  'price': 49.99,
});
```

### 5. Performance Metrics

```dart
analytics.trackPerformance('api_response_time', 250.5, unit: 'ms');
analytics.trackPerformance('image_load_time', 1.2, unit: 's');
```

### 6. Error Tracking (Non-Fatal)

```dart
try {
  await someOperation();
} catch (e) {
  analytics.trackError('NetworkError', e.toString(), context: {
    'endpoint': '/api/books',
    'method': 'GET',
  });
}
```

---

## 🛡️ CrashTrackingService Kullanımı

### 1. Breadcrumbs (Crash Öncesi Aksiyonlar)

```dart
final crashTracking = getIt<CrashTrackingService>();

// Kullanıcı aksiyonlarını track et
crashTracking.addBreadcrumb('User clicked login button');
crashTracking.addBreadcrumb('API call started', data: {'endpoint': '/api/login'});
crashTracking.addBreadcrumb('Response received', data: {'status': 200});

// Eğer crash olursa, breadcrumbs crash report'a dahil edilir
```

### 2. Custom Keys (Context)

```dart
crashTracking.setCustomKey('current_screen', 'book_reader');
crashTracking.setCustomKey('book_id', '123');
crashTracking.setCustomKey('user_level', 'B1');
```

### 3. Non-Fatal Errors

```dart
try {
  await someOperation();
} catch (e, stackTrace) {
  crashTracking.recordNonFatalError(
    e.toString(),
    stackTrace: stackTrace,
    priority: 'medium',
    context: {
      'operation': 'fetch_books',
      'retry_count': 3,
    },
  );
}
```

### 4. User Identification

```dart
// Login sonrası
crashTracking.setUserIdentifier(userId);

// Logout sonrası
crashTracking.setUserIdentifier(null);
crashTracking.clearAllCustomKeys();
```

---

## 🔄 EventService (Learning Events)

EventService öğrenme-specific event'ler için:

```dart
final eventService = getIt<EventService>();

// Reading events
await eventService.readingStarted(bookId);
await eventService.readingCompleted(bookId, totalMs: 120000);

// Quiz events
await eventService.quizCompleted(
  bookId,
  score: 8,
  percentage: 80.0,
  passed: true,
);
```

---

## 📊 Event Batching

Hem AnalyticsService hem EventService otomatik batching yapıyor:

- Maksimum 50 event biriktirilir
- 30 saniyede bir otomatik flush
- App kapanırken manuel flush

---

## 🎯 Best Practices

1. **Screen Tracking:** AnalyticsMixin kullan (otomatik)
2. **User Actions:** Önemli aksiyonları track et
3. **Errors:** Hem analytics hem crash tracking'e gönder
4. **Breadcrumbs:** Kritik işlemlerden önce ekle
5. **Performance:** Yavaş işlemleri track et
6. **Conversions:** Subscription, purchase gibi önemli event'leri track et

---

## 🔍 Backend Dashboard

Backend'de analytics dashboard'u geliştirilecek:

- `/api/events` - Event'leri görüntüle
- `/api/crash` - Crash'leri görüntüle
- Analytics hesaplamaları (placeholder'lar gerçek hesaplamalara çevrilecek)
