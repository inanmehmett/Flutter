# 🔥 Firebase Setup Guide - DailyEnglish

## ✅ Kod Entegrasyonu Tamamlandı

1. ✅ Firebase Crashlytics entegre edildi
2. ✅ Firebase Analytics entegre edildi
3. ✅ Tüm event'ler loglanıyor
4. ✅ User tracking aktif

---

## 📋 Firebase Console Setup (Yapılması Gerekenler)

### **Adım 1: Firebase Console'a Giriş**

1. Tarayıcıda şu adrese git:
   ```
   https://console.firebase.google.com/
   ```

2. Google hesabınla giriş yap

3. **"Add project"** butonuna tıkla

---

### **Adım 2: Proje Oluştur**

1. **Project name:** `DailyEnglish` (veya istediğin isim)
2. **Google Analytics:** ✅ Etkinleştir (önerilir)
3. **Analytics account:** Yeni hesap oluştur veya mevcut hesabı seç
4. **Create project** tıkla
5. Birkaç saniye bekle (proje oluşturuluyor)

---

### **Adım 3: Android App Ekle**

1. Proje oluşturulduktan sonra **"Continue"** tıkla
2. **Android** ikonuna tıkla (veya **Add app** → **Android**)
3. **Android package name:** `com.example.daily_english`
   - ⚠️ **ÖNEMLİ:** Bu package name'i `android/app/build.gradle.kts` dosyasındaki `applicationId` ile eşleşmeli
4. **App nickname (optional):** `DailyEnglish Android`
5. **Register app** tıkla

---

### **Adım 4: google-services.json İndir**

1. **"Download google-services.json"** butonuna tıkla
2. Dosya indirilecek
3. Dosyayı şu konuma kopyala:
   ```
   /Users/mehmetinan/Documents/mehmetinan/Flutter/android/app/google-services.json
   ```

---

### **Adım 5: iOS App Ekle (Opsiyonel)**

1. **Add app** → **iOS**
2. **iOS bundle ID:** `com.example.dailyEnglish`
3. **Register app** tıkla
4. **"Download GoogleService-Info.plist"** butonuna tıkla
5. Dosyayı şu konuma kopyala:
   ```
   /Users/mehmetinan/Documents/mehmetinan/Flutter/ios/Runner/GoogleService-Info.plist
   ```

---

### **Adım 6: Test Et**

1. Flutter uygulamasını çalıştır:
   ```bash
   flutter run
   ```

2. Birkaç işlem yap:
   - Login ol
   - Quiz yap
   - Vocabulary study başlat

3. Firebase Console'da kontrol et:
   - **Analytics** → **Events** → Event'ler görünmeli
   - **Crashlytics** → Crash'ler görünmeli (eğer crash olduysa)

---

## 📊 Firebase Console'da Nerede Ne Var?

### **Crashlytics (Hata Takibi)**
- **Yer:** Firebase Console → **Crashlytics** sekmesi
- **Ne görürsün:**
  - Crash'lerin listesi
  - Stack trace'ler
  - Hangi cihazlarda olduğu
  - Kaç kullanıcıyı etkilediği
  - Custom keys (user_name, user_email)

### **Analytics (Kullanıcı Analizi)**
- **Yer:** Firebase Console → **Analytics** sekmesi
- **Ne görürsün:**
  - **Events** → Tüm event'ler (app_open, user_login, quiz_complete, vb.)
  - **User properties** → Kullanıcı özellikleri (user_name, user_level)
  - **Funnels** → Kullanıcı akışları (register → login → quiz)
  - **Retention** → Kullanıcı tutma oranları

---

## 🎯 Loglanan Event'ler

### **Otomatik Event'ler:**
- ✅ `app_open` - Uygulama açılışı

### **Auth Event'leri:**
- ✅ `user_login` - Kullanıcı girişi (email/google)
- ✅ `user_register` - Kullanıcı kaydı

### **Study Event'leri:**
- ✅ `vocabulary_study_start` - Kelime çalışması başlat
- ✅ `vocabulary_study_complete` - Kelime çalışması tamamla
- ✅ `quiz_complete` - Quiz tamamlama

### **Gamification Event'leri:**
- ✅ `level_up` - Seviye atlama
- ✅ `badge_earned` - Rozet kazanma
- ✅ `streak_milestone` - Streak kilometre taşları (3, 7, 30, 100 gün)

---

## 🚨 Önemli Notlar

1. **google-services.json** ve **GoogleService-Info.plist** dosyaları **ASLA** Git'e commit edilmemeli
2. `.gitignore`'a zaten eklendi ✅
3. Development ve Production için farklı Firebase projeleri kullan (önerilir)

---

## 📚 Kaynaklar

- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Crashlytics Docs](https://firebase.flutter.dev/docs/crashlytics/overview)
- [Firebase Analytics Docs](https://firebase.flutter.dev/docs/analytics/overview)

---

**Son Güncelleme:** 4 Aralık 2025  
**Durum:** ✅ Kod entegrasyonu tamamlandı, Firebase Console setup bekleniyor

