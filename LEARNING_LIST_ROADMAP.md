## Vocabulary Learning System – Implementation Roadmap (Flutter + ASP.NET)

### 0) Amaç ve Kullanıcı Akışı

- Okuyucu metinde kelimeye dokunur → Türkçe anlam pop-up görünür → “Favorilere ekle”
- Favoriler “Learning List” sayfasında birikir → Çalışma modları: Flashcards, Quiz, Matching, Cloze, Listening
- İlerleme durumuna göre (0 Yeni, 1 Öğreniliyor, 2 Öğrenildi) tekrarlama ve gamification

### 1) Mimari ve Modüller (Clean Architecture uyumlu)

- features/vocab/
  - data/
    - models/`user_word.dart`
    - datasources/`user_word_local_data_source.dart` (Hive)
    - datasources/`user_word_remote_data_source.dart` (opsiyonel, ASP.NET API)
    - repositories/`user_word_repository_impl.dart`
  - domain/
    - entities/`user_word_entity.dart`
    - repositories/`user_word_repository.dart`
    - services/`vocab_learning_service.dart`
  - presentation/
    - pages/`learning_list_page.dart` (liste + arama + istatistik)
    - pages/`flashcards_page.dart`, `quiz_page.dart` (çalışma modları)
    - cubit/`vocab_cubit.dart` (liste ve progress yönetimi)

### 2) Veri Modeli

Flutter (Entity/Model)

```dart
class UserWordEntity {
  final String id;            // uuid
  final String word;          // english
  final String meaningTr;     // turkish
  final String? example;      // example sentence
  final String? partOfSpeech; // noun/verb/adj
  final String? cefr;         // A1..C2
  final int progress;         // 0 new, 1 learning, 2 learned
  final DateTime addedAt;     // timestamp
  final String? sourceBookId;
  final String? sourceChapter;
  final List<String> tags;    // topic tags
  const UserWordEntity({...});
}
```

Lokal depolama (Hive box: `user_words`)

- Adapter kaydı: `UserWordEntityAdapter`
- Migration notu: varsa `favorites` box → `user_words` içine taşınabilir (word-only → meaning lookup ya da boş geç)

ASP.NET tablosu (opsiyonel senkronizasyon)

- Table: `UserWordList` (UserId, Word, Meaning, Level, ExampleSentence, Progress, AddedDate)

### 3) Servisler ve DI

`lib/core/di/injection.dart`

- Hive box açılışına `user_words` ekle
- `VocabLearningService` register: `getIt.registerLazySingleton<VocabLearningService>(() => VocabLearningService(...))`

VocabLearningService API (Flutter)

```dart
abstract class VocabLearningServiceProtocol {
  Future<void> addWord({required String word, required String meaningTr, String? example, String? partOfSpeech, String? cefr, String? sourceBookId, String? sourceChapter, List<String> tags = const []});
  Future<List<UserWordEntity>> listWords({String? query, String? cefr, int? progress, List<String>? tags});
  Future<void> updateProgress(String id, int progress);
  Future<void> removeWord(String id);
}
```

Uygulama içi TTS

- Mevcut `FlutterTts` (zaten DI’da mevcut): `speak(word)` helper’ı servis içinde sağlanabilir

### 4) Okuyucu Entegrasyonu

`advanced_reader_page.dart`

- Var olan çeviri overlay’ine ek buton: `_iconAction(icon: Icons.star, label: 'Favorilere ekle', onTap: _onAddToLearningList)`
- Handler:

```dart
Future<void> _onAddToLearningList() async {
  final word = _selectedWord?.trim();
  final meaning = _wordTranslation?.trim();
  if (word == null || word.isEmpty || meaning == null || meaning.isEmpty) return;
  final svc = getIt<VocabLearningService>();
  await svc.addWord(word: word, meaningTr: meaning, sourceBookId: _currentBookId, sourceChapter: _currentChapterId);
  ToastOverlay.show(context, const XpToast(5), channel: 'vocab_add'); // küçük ödül/geri bildirim
}
```

### 5) Learning List Ekranı

`features/vocab/presentation/pages/learning_list_page.dart`

- AppBar: search, küçük stats (toplam, öğrenildi, tekrar gereken)
- List item: word, meaning, progress pill, tts button, overflow: edit/remove
- Filters: CEFR, progress, tag/topic
- Bottom actions: [Study All] [Quiz Mode]

Cubit Akışı

- `VocabState { List<UserWordEntity> words; String query; int? progress; String? cefr; bool loading; }`
- `load()`, `search(q)`, `filter(...)`, `updateProgress(id, p)`, `remove(id)`

### 6) Çalışma Modları (MVP)

Flashcards

- `PageView` ile kart; ön yüzde English, tap ile arka yüzde Turkish (glassmorphism + gradient)
- Aksiyonlar: “Biliyorum / Emin değilim” → progress güncelle

Quiz (4 şıklı)

- Soru: İngilizce kelime → 4 Türkçe şık; doğru şık random pozisyon
- 10 soru bitince sonuç: doğru/yanlış sayısı, öneri listesi

Listening

- TTS ile kelimeyi oku → 4 seçenekten doğru kelimeyi seç

Matching (sonraki iterasyon)

- 6×2 kart eşleştirme (word ↔ meaning)

### 7) Gamification & Analytics

- Başarı/ödül: `GameService` ile küçük XP (örn. addWord=+5, learned=+15)
- Toast/celebration: mevcut `ToastOverlay`, `BadgeCelebration` kullan
- Olay kaydı: `EventService.track('vocab_add', {...})`

### 8) Rotalar ve Navigasyon

- `main.dart` ya da mevcut route sistemine ekleyin:
  - `/learning-list` → `LearningListPage`
  - `/study/flashcards` → `FlashcardsPage`
  - `/study/quiz` → `QuizPage`
- Profil veya Home’dan hızlı erişim kısayolu ekleyin (ikon + badge)

### 9) Performans ve Erişilebilirlik

- Liste sanallaştırma (ListView.builder)
- TTS konuşma hızı/ton ayarı
- Büyük font desteği (textScaleFactor clamp ≤ 1.2 sadece kartlarda)

### 10) Backend API (opsiyonel senkronizasyon)

- GET `/api/userwords?progress=&query=&cefr=`
- POST `/api/userwords/add` { word, meaning, example, cefr, pos, tags }
- PUT `/api/userwords/progress/{id}` { progress }
- DELETE `/api/userwords/{id}`
- Sync stratejisi: local-first → çevrimdışı kayıt, online olduğunda delta sync

### 11) Kabul Kriterleri (MVP)

- [ ] Okuyucuda kelimeyi favorilere ekleyebiliyorum
- [ ] Learning List’te favoriler filtrelenebiliyor ve aranabiliyor
- [ ] Flashcards ve Quiz modları çalışıyor, progress güncelleniyor
- [ ] Basit XP/Toast geri bildirimi var
- [ ] Uygulama yeniden açıldığında liste korunuyor (Hive)

### 12) Görev Listesi (Uygulama)

1. Data model + Hive adapter: `UserWordEntity` (+ box açılışı `user_words`)
2. Local data source + repository + `VocabLearningService`
3. DI: `injection.dart` kayıtları
4. Reader entegrasyonu: “Favorilere ekle” butonu + handler
5. Learning List UI + `VocabCubit`
6. Flashcards ve Quiz MVP
7. Gamification/Toast entegrasyonu
8. (Opsiyonel) Backend endpointleri ve sync

### 13) Tasarım Notları

- Glassmorphism kartlar, gradient arka planlar, minimal ikonlar
- Seçilebilirlik: item slide actions (edit/remove)
- Confetti/celebration: kelime “öğrenildi” olduğunda mini kutlama
