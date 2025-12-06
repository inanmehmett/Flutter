# 🔥 Firebase Manuel Setup - Adım Adım

## 📍 Şu An: Flutter App Ekleme Ekranı

Firebase Console'da Flutter app ekleme ekranındasın.

---

## 🎯 Manuel Yapılandırma (Daha Hızlı)

### **Adım 1: Android App Ekle**

1. Firebase Console'da **"Select a platform"** ekranında:
   - **Android** ikonuna tıkla (yeşil Android robotu)

2. **Android app bilgileri:**
   - **Android package name:** `com.example.daily_english`
   - **App nickname (optional):** `DailyEnglish Android`
   - **Register app** butonuna tıkla

3. **"Download google-services.json"** butonuna tıkla
   - Dosya indirilecek (Downloads klasörüne gider)

4. **Dosyayı kopyala:**
   - İndirdiğin `google-services.json` dosyasını şu konuma kopyala:
   ```
   /Users/mehmetinan/Documents/mehmetinan/Flutter/android/app/google-services.json
   ```

---

### **Adım 2: iOS App Ekle (Opsiyonel)**

1. **"Add app"** → **iOS** ikonuna tıkla
2. **iOS bundle ID:** `com.example.dailyEnglish`
3. **Register app** tıkla
4. **"Download GoogleService-Info.plist"** tıkla
5. Dosyayı şu konuma kopyala:
   ```
   /Users/mehmetinan/Documents/mehmetinan/Flutter/ios/Runner/GoogleService-Info.plist
   ```

---

### **Adım 3: firebase_options.dart Oluştur**

Manuel olarak oluşturmamız gerekiyor. Ben senin için hazırlayacağım.

---

## 📝 Şu An Yapılacaklar

1. **Android ikonuna tıkla** (yeşil Android robotu)
2. **Package name gir:** `com.example.daily_english`
3. **Register app** tıkla
4. **google-services.json** dosyasını indir
5. Dosyayı doğru konuma kopyala

**Hangi adımdasın? Android app ekleme ekranına geldin mi?**

