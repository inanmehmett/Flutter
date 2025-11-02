# 📊 Kelime Çalışma Sistemi - Komple Akış Şeması

## 🎯 Sistem Özeti

Kelime çalışma sistemi üç ana bileşenden oluşur:

1. **Backend (C# .NET)**: Veri kaydetme ve hesaplama
2. **Mobile (Flutter)**: Kullanıcı arayüzü ve yerel önbellekleme
3. **Database (PostgreSQL)**: Kalıcı veri saklama

---

## 🔄 Tam Veri Akışı

### 📱 **1. Uygulama Başlatma (App Launch)**

```
┌─────────────────────────────────────────┐
│  main.dart - App Initialization         │
│  • Initialize Hive (local storage)      │
│  • Initialize DI (dependency injection) │
│  • Configure NetworkManager             │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  VocabularyNotebookPage                 │
│  • BlocProvider<VocabularyBloc>         │
│  • Initial state: VocabularyInitial     │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  VocabularyBloc                         │
│  • add(LoadVocabulary())                │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  VocabularyRepositoryImpl               │
│  • getUserWords(limit: 50, offset: 0)   │
│  • getUserStats()                       │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Backend API Call                       │
│  GET /api/ApiUserVocabulary             │
│  GET /api/ApiUserVocabulary/stats       │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Backend Response (JSON)                │
│  {                                      │
│    "success": true,                     │
│    "data": {                            │
│      "items": [                         │
│        {                                │
│          "id": 123,                     │
│          "word": "beautiful",           │
│          "reviewCount": 5,    ← camelCase│
│          "correctCount": 4,   ← camelCase│
│          "status": "learning"           │
│        }                                │
│      ],                                 │
│      "total": 25                        │
│    }                                    │
│  }                                      │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Flutter Parsing (_fromServer)          │
│  ✅ Uses case-insensitive extensions    │
│  • id = e.getInt('id')                  │
│  • reviewCount = e.getInt('reviewCount')│
│  • correctCount = e.getInt('correctCount')│
│  • status = e.getString('status')       │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  LocalVocabularyStore                   │
│  ✅ mergeWithPersisted() - FIXED!       │
│  • Now uses incoming (backend) data     │
│  • Only preserves recentActivities      │
│  • Stores in _wordStateById Map         │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  VocabularyBloc                         │
│  emit(VocabularyLoaded(                 │
│    words: [...],                        │
│    stats: VocabularyStats(...)          │
│  ))                                     │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  UI Display                             │
│  ✅ User sees correct data!             │
│  • Review Count: 5                      │
│  • Correct Count: 4                     │
│  • Status: Learning                     │
└─────────────────────────────────────────┘
```

---

### ✏️ **2. Kelime Çalışma (Word Review)**

```
┌─────────────────────────────────────────┐
│  USER ACTION                            │
│  • User answers flashcard               │
│  • User completes quiz question         │
│  • User finishes practice session       │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  vocabulary_study_page.dart             │
│  _onAnswerSubmitted(isCorrect, timeMs)  │
│                                         │
│  • Adds result to current session      │
│  • Triggers BLoC event immediately     │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  VocabularyBloc                         │
│  on<MarkWordReviewed>()                 │
│                                         │
│  1. Call repository.markWordReviewed()  │
│  2. Set _lastStats = null              │
│  3. add(RefreshVocabulary())           │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  VocabularyRepositoryImpl               │
│  markWordReviewed(wordId, isCorrect)    │
│                                         │
│  🔍 DEBUG LOG:                          │
│  "📝 [VOCAB] Marking word 123 as CORRECT"│
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Backend API Call                       │
│  POST /api/ApiUserVocabulary/123/review │
│  Body: { "isCorrect": true }            │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  ApiUserVocabularyController.cs         │
│  [HttpPost("{id}/review")]              │
│  Review(id, body)                       │
│                                         │
│  • Validates user authorization         │
│  • Calls UserVocabularyService          │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  UserVocabularyService.cs               │
│  ReviewAsync(userId, id, isCorrect)     │
│                                         │
│  ✅ VERI GÜNCELLEMESİ:                  │
│  1. vocab.ReviewCount += 1              │
│  2. if (isCorrect):                    │
│     - vocab.CorrectCount += 1           │
│     - vocab.ConsecutiveCorrectCount += 1│
│  3. Status Progression:                │
│     - new_ → learning (first correct)   │
│     - learning → known (3 consecutive)  │
│     - known → mastered (6 consecutive)  │
│  4. vocab.LastReviewedAt = UtcNow       │
│  5. vocab.NextReviewAt = Calculate()    │
│  6. await _db.SaveChangesAsync() ✅     │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  PostgreSQL Database                    │
│  UserVocabulary Table                   │
│                                         │
│  UPDATE UserVocabulary                  │
│  SET ReviewCount = 6,        ← +1       │
│      CorrectCount = 5,       ← +1       │
│      ConsecutiveCorrectCount = 3, ← +1  │
│      Status = 'learning',               │
│      LastReviewedAt = '2025-11-02...',  │
│      NextReviewAt = '2025-11-04...',    │
│      UpdatedAt = '2025-11-02...'        │
│  WHERE Id = 123                         │
│                                         │
│  ✅ SAVED TO DATABASE!                  │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Backend Response                       │
│  {                                      │
│    "success": true,                     │
│    "message": "Review kaydedildi",      │
│    "data": {                            │
│      "totalReviews": 6,                 │
│      "correctReviews": 5,               │
│      "accuracy": 0.833,                 │
│      "status": "learning",              │
│      "nextReviewAt": "2025-11-04..."    │
│    }                                    │
│  }                                      │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Flutter: markWordReviewed (continued)  │
│  🔍 DEBUG LOG:                          │
│  "✅ [VOCAB] Backend response: {...}"   │
│                                         │
│  • Call getWordById(123) to fetch fresh│
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Backend API Call                       │
│  GET /api/ApiUserVocabulary/123         │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Backend Response                       │
│  {                                      │
│    "success": true,                     │
│    "data": {                            │
│      "id": 123,                         │
│      "word": "beautiful",               │
│      "reviewCount": 6,      ← Updated!  │
│      "correctCount": 5,     ← Updated!  │
│      "consecutiveCorrectCount": 3,      │
│      "status": "learning",  ← Updated!  │
│      "lastReviewedAt": "2025-11-02...", │
│      "nextReviewAt": "2025-11-04..."    │
│    }                                    │
│  }                                      │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Flutter: _fromServer() Parsing         │
│  ✅ Uses safe case-insensitive parsing  │
│                                         │
│  reviewCount = e.getInt('reviewCount')  │
│  // Result: 6 ✅                        │
│                                         │
│  correctCount = e.getInt('correctCount')│
│  // Result: 5 ✅                        │
│                                         │
│  status = e.getString('status')         │
│  // Result: "learning" ✅               │
│                                         │
│  🔍 DEBUG LOG:                          │
│  "🔄 [VOCAB] Parsing word 'beautiful'   │
│   ReviewCount: 6, CorrectCount: 5,      │
│   Status: learning, Consecutive: 3"     │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  LocalVocabularyStore                   │
│  mergeWithPersisted(incoming)           │
│                                         │
│  ✅ FIX APPLIED: Uses incoming data!    │
│  • incoming.reviewCount = 6             │
│  • incoming.correctCount = 5            │
│  • incoming.status = learning           │
│                                         │
│  ❌ OLD BUG (Fixed):                    │
│  Would have kept old cached values      │
│  and overwritten new data!              │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  _store.upsertWord(updated)             │
│  🔍 DEBUG LOG:                          │
│  "📊 [VOCAB] Updated stats -            │
│   ReviewCount: 6, CorrectCount: 5,      │
│   Status: learning"                     │
│                                         │
│  ✅ Stored in cache!                    │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  VocabularyBloc                         │
│  add(RefreshVocabulary())               │
│  • Fetches all words again              │
│  • Fetches fresh stats                  │
│  • emit(VocabularyLoaded(...))          │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  UI Update                              │
│  ✅ User sees updated progress!         │
│                                         │
│  📊 Word Detail:                        │
│  • Toplam Tekrar: 6 times               │
│  • Doğru Cevap: 5 times                 │
│  • Başarı Oranı: 83.3%                  │
│  • Ardışık Doğru: 3 streak              │
│  • Status: 🟡 Learning                  │
│  • Sonraki Tekrar: 2 gün sonra          │
└─────────────────────────────────────────┘
```

---

### 🔄 **3. Uygulama Yeniden Başlatma (App Restart)**

```
┌─────────────────────────────────────────┐
│  User closes and reopens app           │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  LocalVocabularyStore                   │
│  • In-memory Map is EMPTY               │
│  • _wordStateById = {}                  │
│                                         │
│  ⚠️ NOTE: This is in-memory only!       │
│  Cache is lost on restart.              │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  VocabularyBloc                         │
│  • add(LoadVocabulary())                │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Backend API Call                       │
│  GET /api/ApiUserVocabulary             │
│  • Fetches all words from database      │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Database Query                         │
│  SELECT * FROM UserVocabulary           │
│  WHERE UserId = 'xxx'                   │
│    AND DeletedAt IS NULL                │
│  ORDER BY UpdatedAt DESC                │
│  LIMIT 50                               │
│                                         │
│  ✅ Returns ALL saved progress!         │
│  • ReviewCount: 6                       │
│  • CorrectCount: 5                      │
│  • Status: "learning"                   │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  Flutter Parsing                        │
│  • _fromServer() parses each word       │
│  • mergeWithPersisted(incoming)         │
│  • existing == null (cache empty)       │
│  • Returns incoming directly ✅         │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│  UI Display                             │
│  ✅ ALL PROGRESS RESTORED!              │
│  • User sees yesterday's progress       │
│  • All review counts correct            │
│  • All statuses correct                 │
└─────────────────────────────────────────┘
```

---

## 🐛 Tespit Edilen Buglar ve Düzeltmeler

### **Bug #1: LocalStore Merge Logic** ❌ → ✅

**Problem:**

```dart
// ❌ ESKİ KOD (YANLIŞ):
reviewCount: existing.reviewCount != 0
    ? existing.reviewCount      // Eski cache değerini kullanır
    : incoming.reviewCount,     // Backend'den gelen yeni değer

status: existing.status,        // HER ZAMAN eski status kullanır!
```

**Sonuç:**

- Backend 6 gönderiyor, Flutter 3 gösteriyor (cache'te eski değer varsa)
- Status hiç güncellenmiyor (new\_ → learning geçişi olmuyordu)

**Düzeltme:**

```dart
// ✅ YENİ KOD (DOĞRU):
return incoming.copyWith(
  // Backend'den gelen TÜM verileri kullan
  // Sadece local-only field'ları (recentActivities) koru
  recentActivities: existing.recentActivities.isNotEmpty
      ? existing.recentActivities
      : incoming.recentActivities,
);
```

---

### **Bug #2: JSON Parsing - Case Sensitivity** ⚠️ → ✅

**Problem:**

```dart
// ❌ ESKİ KOD:
final reviewCount = (e['reviewCount'] as num?)?.toInt() ?? 0;
// Backend 'ReviewCount' (PascalCase) gönderse null döner → 0
```

**Düzeltme:**

```dart
// ✅ YENİ KOD:
final reviewCount = e.getInt('reviewCount', defaultValue: 0);
// Case-insensitive, hem 'reviewCount' hem 'ReviewCount' çalışır
```

**Not:** Backend zaten camelCase gönderiyor ama bu fix gelecek-proof.

---

## 📊 Veri Akışı Özeti

### **Başarılı Çalışma Senaryosu:**

```
Kullanıcı Çalışır
    ↓
Flutter → Backend API (POST /review)
    ↓
Backend → Database UPDATE
    ✅ ReviewCount: 5 → 6
    ✅ CorrectCount: 4 → 5
    ✅ Status: new_ → learning
    ↓
Backend → Flutter (Response)
    ↓
Flutter Fetch Fresh Data (GET /{id})
    ↓
Backend → Flutter (Full Word Data)
    ↓
Flutter Parse (case-insensitive) ✅
    ↓
LocalStore Merge (incoming only) ✅
    ↓
BLoC Refresh
    ↓
UI Shows Updated Stats ✅
```

---

## 🧪 Test Checklist

### **Test 1: İlerleme Kaydediliyor mu?**

- [ ] Bir kelime çalış
- [ ] Console'da log'ları kontrol et:
  - `📝 [VOCAB] Marking word X as CORRECT`
  - `✅ [VOCAB] Backend response: {...}`
  - `🔄 [VOCAB] Parsing word "..." ReviewCount: Y`
  - `📊 [VOCAB] Updated stats - ReviewCount: Y`
- [ ] UI'da sayaçların arttığını gör

### **Test 2: Uygulama Yeniden Açınca Veriler Korunuyor mu?**

- [ ] Bir kelime çalış
- [ ] ReviewCount değerini not et (örn: 5)
- [ ] Uygulamayı TAMAMEN kapat (kill)
- [ ] Uygulamayı yeniden aç
- [ ] Aynı kelimeyi bul
- [ ] ReviewCount hala aynı mı? (5 olmalı)

### **Test 3: Status Geçişleri Çalışıyor mu?**

- [ ] Yeni bir kelime ekle (Status: new\_)
- [ ] İlk doğru cevap → Status: learning olmalı
- [ ] 3 ardışık doğru → Status: known olmalı
- [ ] 6 ardışık doğru → Status: mastered olmalı

### **Test 4: Backend Verisi Doğru mu?**

```sql
-- PostgreSQL'de kontrol et:
SELECT
    Word,
    ReviewCount,
    CorrectCount,
    ConsecutiveCorrectCount,
    Status,
    LastReviewedAt,
    NextReviewAt
FROM UserVocabulary
WHERE UserId = 'USER_ID'
ORDER BY UpdatedAt DESC
LIMIT 10;
```

---

## 🔍 Debug Log Örnekleri

### **Başarılı Review:**

```
📝 [VOCAB] Marking word 123 as CORRECT
✅ [VOCAB] Backend response: {success: true, data: {totalReviews: 6, ...}}
🔄 [VOCAB] Parsing word "beautiful" (ID: 123) - ReviewCount: 6, CorrectCount: 5, Status: VocabularyStatus.learning, Consecutive: 3
📊 [VOCAB] Updated stats - ReviewCount: 6, CorrectCount: 5, Status: learning
```

### **Hatalı Senaryo (Eğer hala sorun varsa):**

```
📝 [VOCAB] Marking word 123 as CORRECT
❌ [VOCAB] Error marking word reviewed: DioException [...]
⚠️ [VOCAB] Word 123 not found in local store
```

**Bu durumda:**

- Backend'e ulaşılamıyor
- Network problemi var
- Authentication hatası olabilir

---

## 🎯 Özet

### **Düzeltilen Sorunlar:**

1. ✅ LocalStore merge logic - Backend verisi artık doğru kullanılıyor
2. ✅ Case-insensitive JSON parsing eklendi
3. ✅ Debug logging eklendi - Sorun tespiti kolay
4. ✅ Status güncellemeleri artık çalışıyor

### **Sistem Garantileri:**

1. ✅ Backend verileri doğru kaydediyor (PostgreSQL'de persist)
2. ✅ Flutter backend'den doğru okuyor (case-insensitive)
3. ✅ LocalStore backend verisini eziyor YOK artık
4. ✅ App restart'ta veriler korunuyor (backend'den yükleniyor)

### **Beklenen Sonuç:**

🎉 Kullanıcılar artık çalışma ilerlemelerini kaybetmeyecek!
