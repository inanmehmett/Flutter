# 🚀 Flutter Proje Yol Haritası ve Kurallar

## 📋 TEMEL KURALLAR

### 1. **Clean Code Prensipleri**

- Fonksiyonlar tek sorumluluğa sahip olmalı
- Değişken ve fonksiyon isimleri açıklayıcı olmalı
- Magic number'lardan kaçının, constant kullanın
- Code review için her commit clean olmalı

### 2. **Minimalist Yaklaşım**

- Gereksiz package'lerden kaçının
- Her dependency'nin gerekliliğini sorgulayın
- Boilerplate code'u minimize edin
- "Less is more" prensibi

### 3. **Karmaşıklık Yönetimi**

- Over-engineering yapmayın
- Basit çözümler öncelikli
- Premature optimization'dan kaçının
- KISS (Keep It Simple, Stupid) prensibi

### 4. **Performance & Hız Kriterleri**

- `const` constructor'ları kullanın
- Lazy loading implementasyonu
- Gereksiz rebuild'lerden kaçının
- Memory leak kontrolü

### 5. **Dependency Management**

- Package versiyonlarını lock'layın
- Sadece güvenilir ve maintained package'ler
- Alternative package'leri araştırın
- Vendor lock-in'den kaçının

### 6. **Memory Management**

- Dispose pattern'ini doğru kullanın
- Stream subscription'ları temizleyin
- Image cache'i yönetin
- Timer ve listener'ları iptal edin

---

## 🏗️ PROJEDEKİ MİMARİ KARARLARI

### **State Management:** flutter_bloc (+ get_it/injectable DI)

```dart
// ✅ Doğru kullanım
final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  return UserNotifier();
});

// ❌ Yanlış - Gereksiz karmaşık
class ComplexBlocWithMultipleStates extends Bloc<Event, State> { ... }
```

### **Klasör Yapısı:**

```
lib/
├── core/
│   ├── constants/
│   ├── utils/
│   ├── errors/
│   └── extensions/
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── providers/
└── main.dart
```

### **Zorunlu Package'ler (güncel kullanım):**

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  flutter_bloc: ^8.x
  equatable: ^2.x
  get_it: ^7.x
  injectable: ^2.x
  dartz: ^0.10.x
  dio: ^5.x
  hive: ^2.x
  hive_flutter: ^1.x
  path_provider: ^2.x
  shared_preferences: ^2.x
  flutter_secure_storage: ^9.x
  json_annotation: ^4.x
  google_sign_in: ^6.x
  flutter_tts: ^3.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

---

## ⚠️ UYARI SİSTEMİ

### **🔴 Kritik Hatalar - Derhal Dur!**

1. **Memory Leak Indicators:**

   - Dispose edilmeyen controller'lar
   - Temizlenmeyen stream subscription'lar
   - Sonsuz döngü potansiyeli

2. **Performance Killers:**

   - Build method'da heavy computation
   - Gereksiz `setState()` çağrıları
   - Non-const widget'lar fazla kullanımı

3. **Architecture Violations:**
   - Business logic UI'da
   - Direct API call'lar widget'larda
   - Global state abuse'u

### **🟡 Uyarı Durumları**

1. **Code Quality Issues:**

   - 50+ satırlık fonksiyonlar
   - Nested if-else (3+ level)
   - Magic number kullanımı

2. **Dependency Concerns:**
   - Deprecated package kullanımı
   - Too many dependencies (15+)
   - Version conflict'ler

---

## 📝 MİGRASYON ADIMLARI

### **Faz 1: Proje Setup**

- [x] Flutter project init
- [x] Package configuration
- [x] Folder structure
- [x] Base classes ve interfaces

### **Faz 2: Core Infrastructure**

- [x] HTTP client setup (Dio)
- [x] Error handling system (NetworkError, interceptors)
- [x] Local storage setup (Hive + SecureStorage)
- [ ] Router configuration

### **Faz 3: Data Layer**

- [ ] API models
- [ ] Repository pattern implementation
- [ ] Caching strategy
- [ ] Offline storage

### **Faz 4: Business Logic**

- [x] State management (flutter_bloc)
- [ ] Use cases implementation
- [ ] Validation logic

### **Faz 5: UI Layer**

- [ ] Base widget'lar
- [ ] Screen'ler
- [ ] Custom widget'lar
- [ ] Theming

### **Faz 6: Platform Integration**

- [ ] Native iOS features (platform channels)
- [ ] Permissions handling
- [ ] Device-specific functionality

### **Faz 7: Testing & Optimization**

- [ ] Unit tests
- [ ] Widget tests
- [ ] Performance testing
- [ ] Memory profiling

---

## 🎯 HER ADIMDA KONTROL LİSTESİ

### **Kod Yazmadan Önce:**

- [ ] Bu feature gerçekten gerekli mi?
- [ ] En basit implementasyon nedir?
- [ ] Memory leak riski var mı?
- [ ] Performance impact'i nedir?

### **Kod Yazdıktan Sonra:**

- [ ] Kod clean ve readable mı?
- [ ] Error handling yapıldı mı?
- [ ] Test yazıldı mı?
- [ ] Documentation güncellendi mi?

---

## 🔧 SWIFT-FLUTTER CONVERSION NOTLARI

### **Swift Equivalent'ları:**

- `UIViewController` → `StatefulWidget`
- `UIView` → `Widget`
- `UserDefaults` → `SharedPreferences`
- `Keychain` → `FlutterSecureStorage`
- `URLSession` → `Dio`
- `NotificationCenter` → `Stream`/`Provider`

### **iOS Specific Features:**

- Platform channels kullanım rehberi
- Native kod integration
- iOS permission handling

---

**📞 UYARI SİSTEMİ AKTIF!**
Bu dosyada belirtilen kurallara aykırı davrandığınızda size uyarı vereceğim. Proje sağlığı için bu kuralları ciddiye alalım! 💪
