## DailyEnglish Mobile Geliştirme Planı

### Amaç ve kapsam

- Mobil–backend entegrasyonunu temiz, sürdürülebilir ve hatasız hale getirmek
- Auth akışını standartlaştırmak ve sağlamlaştırmak
- Temel ekranları stabil çalışır kılmak ve ardından özellik kapsamını genişletmek

---

### Faz 1 — Konfigürasyon ve altyapı (temizlik)

- Config standartlaştırma
  - `AppConfig.apiBaseUrl`: yalnızca `--dart-define API_BASE_URL=...` ile yönetilir. [DURUM: TAMAMLANDI]
  - iOS (Debug): ATS istisnası ile HTTP (127.0.0.1) erişimi aktif. [DURUM: TAMAMLANDI]
  - Prod: HTTPS zorunlu. [DURUM: TODO]
  - Android (Debug): cleartext izin (network_security_config). [DURUM: TODO]
- Network katmanı tekilleştirme
  - Tek bir `Dio` örneği: `NetworkManager`. [DURUM: TAMAMLANDI]
  - Interceptor’lar: Auth, Logging, Cache burada toplanır. [DURUM: TAMAMLANDI]
  - Client tarafında CORS header’ları kaldırılır (CORS sunucu sorumluluğudur). [DURUM: TAMAMLANDI]
- Kabul ölçütü
  - Tüm istekler tek `Dio` üzerinden, Debug’da HTTP çalışır, Prod’da HTTPS gerekir

### Faz 2 — Auth akışı düzeltme

- Endpoint hizalama
  - Login/Refresh: `POST /connect/token` (grant_type=password | refresh_token)
  - Register: `POST /connect/register`
  - Logout: `GET /connect/logout`
  - UserInfo: `GET /connect/userinfo`
- Kod düzeltmeleri
  - `validateStatus`: 401’in error’a düşmesi için `< 400` veya 401’i `onResponse` içerisinde ele al. [DURUM: TAMAMLANDI]
  - `AuthInterceptor`: 401 → refresh akışı → token güncelle → orijinal isteği retry. [DURUM: TAMAMLANDI]
  - `SecureStorageService`: `token_expires_at` (mutlak zaman) sakla; `expires_in` yerine bunu doğrula. [DURUM: TAMAMLANDI]
  - Tek bir `AuthServiceProtocol` kullan; duplike auth servislerini kaldır. [DURUM: TODO]
- Kabul ölçütü
  - Token süresi bittiğinde otomatik refresh+retry, yanlış kimlikte tutarlı 401

### Faz 3 — Profil ve temel veri entegrasyonu

- Profil
  - `GET/PUT /api/ApiUserProfile`
  - `GET /api/ApiUserProfile/activities`
- Reading
  - `GET /api/ReadingTexts`
  - `GET /api/ReadingTexts/{id}`
  - `GET /api/ApiReadingTexts/{id}/manifest?voiceId=default&sourceLang=EN&targetLang=TR`
  - Gelişmiş Okuyucu: cümleye dokun → çeviri + veritabanı ses dosyasıyla oynat; sayfa içi cümle highlight; Play ile sırayla çalma; sayfalar arası auto-advance. [DURUM: TAMAMLANDI]
  - DB’de çeviri/ses bulunmazsa: DeepL ile çeviri + ElevenLabs ile mp3 üretimi ve DB’ye kalıcı kaydetme (manifest’te Translation/AudioUrl dolu döner). [DURUM: TAMAMLANDI]
- Mobil optimize endpoint’ler (opsiyonel)
  - `GET /api/mobile/dashboard`
  - `GET /api/mobile/reading-texts?page=1&pageSize=10`
- Kabul ölçütü
  - Login sonrası profil çekimi ve reading akışları sorunsuz

### Faz 4 — Ekran/State düzeni

- State standardizasyonu: tek yaklaşım belirle (örn. UI state=Provider, iş akışları=Bloc) [DURUM: DEVAM EDİYOR]
- Logging: `kDebugMode` koşullu log, token asla loglanmaz
  - Kabul ölçütü: Tek tip state, gereksiz log yok

### Faz 5 — Test ve kalite

- Smoke test scriptleri (curl)
  - Register → Login → UserInfo → Profile GET/PUT → 401 simülasyonu → Refresh → Retry → Logout
- Entegrasyon testleri: Auth ve profil için minimal testler
- CI (ileride): Lint + format + smoke
  - flutter analyze uyarılarını kademeli temizleme (özellikle withOpacity deprecation, print→Logger dönüşümleri). [DURUM: DEVAM EDİYOR]
- Kabul ölçütü: Smoke akışı yeşil, lint hatası yok

### Faz 6 — Özellik genişletme (opsiyonel)

- Gamification, Quiz, Sentence TTS/Translate, offline cache/sync iyileştirmeleri
  - Ses manifest prefetch ve sayfa geçişinden önce önbellekleme. [DURUM: PLAN]
  - Çevrimdışı çalma: ses dosyalarını local cache’te saklama. [DURUM: PLAN]
  - Otomatik oynatma sırasında isteğe bağlı sayfa kaydırmayı kilitleme. [DURUM: PLAN]
  - Cümle highlight’ını kullanıcı ayarına bağlama (aç/kapat). [DURUM: PLAN]

---

### Düzeltilecek noktalar (uygulanacak değişiklikler)

- Network
  - `validateStatus` mantığı düzeltilecek [DURUM: TAMAMLANDI]
  - Client CORS header’ları kaldırılacak
- Auth
  - Tek `AuthService` üzerinden `/connect/*` + `/api/ApiUserProfile`
  - `AuthInterceptor` 401 → refresh+retry; token content-type: `application/x-www-form-urlencoded`
  - `SecureStorageService` alanları: `access_token`, `refresh_token`, `token_expires_at`
- Endpoints
  - `QuizService` ve diğerleri: `AppConfig.apiBaseUrl` kullanımı
  - Kalan servislerde endpoint hizalaması
- Platform

  - iOS ATS debug izinleri (ekli); Android debug cleartext izni (eklendi)

- UI/UX ve Kod Kalitesi
  - `withOpacity` kullanımını `.withValues()` ile değiştir. [DURUM: TODO]
  - `print` → `Logger` dönüşümleri ve gereksiz logların temizlenmesi. [DURUM: DEVAM EDİYOR]
  - Home sayfası dikey overflow durumlarının giderilmesi (giderildi, tekrar gözlemle). [DURUM: TAMAMLANDI]

---

## Şu ana kadar tamamlananlar (özet)

- Okuyucu deneyimi:
  - Cümleye dokun → çeviri + veritabanı ses dosyası öncelikli çalma, yoksa TTS fallback.
  - Cümle highlight (tap ve autoplay sırasında) ve haptik geri bildirim.
  - Play ile sayfadaki cümlelerin ardışık çalınması ve sayfalar arası otomatik ilerleme.
  - Oynatma hızı ayarı (TTS ve audioplayers için): varsayılan hız 0.5 (Normal). Hız önayarları: Yavaş (0.45), Normal (0.50), Orta-Hızlı (0.65), Hızlı (0.80).
  - Varsayılan yazı boyutu 27.0; ayarlardan değiştirilebilir.
  - SnackBar iyileştirmeleri (floating, süre artırımı).
- Altyapı:
  - `API_BASE_URL` `--dart-define` ile yönetim; iOS Debug ATS istisnası aktif.
  - `NetworkManager` + Interceptor’lar entegre; `TranslationService` ve manifest entegrasyonu tamam.

## English Learning (Reading/Words/Quiz)

- Reading
  - Tap-to-translate + DB audio first; TTS fallback; sentence highlight; sequential play; auto-advance; auto-scroll. [TAMAMLANDI]
- Words (Plan)
  - SRS tabanlı tekrar; favori sözlük; telaffuz ve örnek cümle.
- Quiz (Plan)
  - Okuma metinlerine bağlı soru setleri ve XP ödülü.

## Gamification

- XP & Levels
  - Etkinlik tabanlı XP (okuma/quiz/kelime); seviye barı ve CEFR hizalaması. [PLAN]
- Achievements & Badges
  - Dönüm noktası rozetleri ve claim akışı. [PLAN]
- Streak & Goals
  - Günlük/haftalık hedefler ve streak takibi. [PLAN]
- Leaderboards (Opsiyonel)
  - Haftalık/toplam XP sıralaması. [PLAN]
- Teknik
  - Event logging ve offline sync; mevcut backend Gamification servisleri ile hizalama. [DEVAM]

---

## Mobil API Dokümantasyonu (çekirdek)

### Auth

- POST `/connect/token`
  - Content-Type: `application/x-www-form-urlencoded`
  - Body (login): `grant_type=password&username={emailOrUser}&password={pwd}`
  - Body (refresh): `grant_type=refresh_token&refresh_token={token}`
  - Response (200):
    ```json
    {
      "access_token": "...",
      "refresh_token": "...",
      "expires_in": 3600,
      "token_type": "Bearer"
    }
    ```
- POST `/connect/register`
  - Body (JSON):
    ```json
    { "Email": "a@b.com", "UserName": "mehmet", "Password": "Test1234!" }
    ```
- GET `/connect/logout`
  - Header: `Authorization: Bearer {access_token}`
- GET `/connect/userinfo`
  - Header: `Authorization: Bearer {access_token}`

### User Profile

- GET `/api/ApiUserProfile`
  - Header: `Authorization: Bearer {access_token}`
- PUT `/api/ApiUserProfile`
  - Header: `Authorization: Bearer {access_token}`
  - Body: kullanıcı profil JSON’u
- GET `/api/ApiUserProfile/activities`
  - Header: `Authorization: Bearer {access_token}`

### Reading

- GET `/api/ReadingTexts`
- GET `/api/ReadingTexts/{id}`
- GET `/api/ApiReadingTexts/{id}/manifest?voiceId=default&sourceLang=EN&targetLang=TR`

### Mobil dashboard (opsiyonel)

- GET `/api/mobile/dashboard`
- GET `/api/mobile/reading-texts?page=1&pageSize=10`

---

## Test Planı

- iOS simülatör: base URL `http://127.0.0.1:5001`
- Android emülatör: base URL `http://10.0.2.2:5001`
- Akışlar
  - Register → Login → UserInfo → Profile GET/PUT → 401 simülasyonu → Refresh → Retry → Logout
  - Reading list → detail → manifest

### Hızlı komutlar

- iOS (Debug):
  ```bash
  flutter run -d ios --dart-define API_BASE_URL=http://127.0.0.1:5001
  ```
- Android (Debug):
  ```bash
  flutter run -d android --dart-define API_BASE_URL=http://10.0.2.2:5001
  ```

---

## Durum Notları

- iOS ATS istisnası eklendi (Debug için). Prod’da HTTPS zorunlu tutulmalıdır.
- Backend `http://localhost:5001` dinlemede; mobil için iOS’ta `127.0.0.1`, Android emülatörde `10.0.2.2` kullanılır.

---

## Backend API Notları (Mobile için XP/Level/Stats/Badges)

- ApiUserProfile

  - GET `api/ApiUserProfile`
    - Döner: `cefrLevel`, `subLevel`, `levelName`, `levelDisplay`, `experiencePoints`, `preferredLanguage` vb.

- ApiGamification

  - GET `api/ApiGamification/level`
    - Döner: `currentLevel`, `currentXP`, `xpForNextLevel`, `progressPercentage`, `nextLevel`, `levelColor`
  - POST `api/ApiGamification/xp/earn` (Body: `xpAmount`, `activityType`)
  - GET `api/ApiGamification/leaderboard`
  - GET `api/ApiGamification/level/history`
  - (Eksik) Badges: Önerilen endpoint `GET api/ApiGamification/badges` (uygulamada bu yola bağlanıldı; backend eklenmeli)

- ApiProgressStats
  - GET `api/ApiProgressStats/detailed`
  - GET `api/ApiProgressStats/analytics?startDate&endDate`
  - GET `api/ApiProgressStats/goals`
  - GET `api/ApiProgressStats/performance`
  - GET `api/ApiProgressStats/comparison?compareWith=average`
  - GET `api/ApiProgressStats/export?startDate&endDate`
  - GET `api/ApiProgressStats/charts/xp-trend?period=weekly|monthly`
  - GET `api/ApiProgressStats/charts/activity-distribution`
  - GET `api/ApiProgressStats/charts/hourly-pattern`
  - GET `api/ApiProgressStats/summary` (özet: xp, performance, goals, ranking)

Kullanım (Flutter Profile sayfası)

- Level/XP: `GET api/ApiGamification/level`
- Streak/Goals: `GET api/ApiProgressStats/goals`
- Progress dağılımı: `GET api/ApiProgressStats/detailed`
- Badges: `GET api/ApiGamification/badges` (backend eklenmeli; yoksa uygulama boş liste gösterir)

---

## UI/UX ve Özellik İyileştirmeleri (Backlog)

1. Okuyucu: eşzamanlı cümle içi highlight (sentence-level yerine segment-level)

- Problem: Şu an cümle seslendirildiğinde tüm cümle blok olarak aydınlatılıyor.
- Aksiyon: Ses çalma sırasında, oynatılan segmenti (kelime/ifade) gerçek zamanlı vurgulamak. Manifest/tts zaman damgaları varsa bunları kullan; yoksa cümleyi hece/kelime bazlı tahmini aralıklara böl.
- Kabul ölçütü:
  - Oynatma devam ederken highlight, segment ile senkron akmalı; durdur/geri sar ileri sar durumlarında highlight doğru güncellenmeli.
  - Kullanıcı bir kelimeye dokunduğunda mevcut davranış korunur: tam cümle seçimi ve çeviri görünür.

2. Oynat/Duraklat ikon titremesi (transition jitter) azaltma

- Problem: Cümleler arası geçişte Play/Pause görünümü anlık değişip dikkat dağıtıyor.
- Aksiyon: Transport state’i stabilize et; cümle geçişlerinde ikon değişimini 150–250 ms debounce ile yumuşat veya tekil yükleme göstergesi kullan.
- Kabul ölçütü:
  - Cümle geçişinde ikon titremesi/flash hissi olmamalı; erişilebilirlik için durum değişimleri hâlâ net olmalı.

3. Books sayfası yerleşimi

- Problem: Kitap kartları sayfaya dağınık yerleşiyor.
- Aksiyon: Duyarlı grid (ör. iPhone: 2 sütun, iPad: 3–4), sabit aspect ratio, tutarlı padding/gap; tek satır başlık + çok satır özet kırpma.
- Kabul ölçütü:
  - Farklı ekran boyutlarında simetrik grid, taşma/overflow olmadan kaydırma.

4. Anasayfada kitap kapaklarının görünmemesi

- Problem: Kapak/ikon görselleri render olmuyor.
- Aksiyon: `iconUrl`/kapak alanı için görüntü yükleme; hata/fallback placeholder (ör. kitap simgesi). Cache ve düşük çözünürlük önizleme ekle.
- Kabul ölçütü:
  - Geçerli URL’lerde kapaklar görünür; hatalı URL’de anlaşılır placeholder.

5. Kitap kartında "sesli" (audio available) göstergesi

- Problem: Kitabın ses desteği olup olmadığı anlaşılmıyor.
- Aksiyon: Seviye/metadata alanının yanına kulaklık/önizleme dalgası ikonu; Voice-over açıklamasıyla erişilebilirlik desteği.
- Kabul ölçütü:
  - Sesli kitaplar tutarlı biçimde işaretlenmiş; ikon, koyu/açık temada net görünüyor.

6. Profil: "Profile Details" bölümü (e‑posta, kullanıcı adı, şifre güncelleme)

- Aksiyon: Profil detay ekranı ekle; e‑posta ve kullanıcı adı güncelleme için `GET/PUT /api/ApiUserProfile` bağla; şifre güncelleme için uygun endpoint mevcutsa bağla (yoksa backend çalışma maddesi oluştur).
- Kabul ölçütü:
  - Form doğrulama, başarı/başarısızlık geri bildirimi; kaydetmeden çıkarken uyarı; erişilebilir etiketler.

7. Learning progress, user stats ve XP streak

- Problem: Bölümler boş gösteriliyor.
- Aksiyon: İlgili servisleri bağla (ör. Gamification/ProgressStats). Uygun endpoint yoksa backend’de mobil dostu endpoint’ler tanımla.
- Kabul ölçütü:
  - Veriler gerçek zamanlı/yenilemeyle güncellenir; boş/başarısız durumlar için boş durum ekranı ve hata geri bildirimi vardır.
