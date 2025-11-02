# 🐛 VOCABULARY PROGRESS BUG - Detaylı Analiz

## Sorun Özeti
- **Problem**: Dün çalışılan kelimeler bugün 0 görünüyor, ilerleme kaydedilmiyor
- **Tarih**: 2 Kasım 2025
- **Etkilenen Alan**: Kelime çalışma sistemi (vocabulary review)

---

## 🔍 Tespit Edilen Sorunlar

### **ANA SORUN: Backend JSON Serialization**

Backend (C#) PascalCase döndürüyor:
```json
{
  "ReviewCount": 5,
  "CorrectCount": 4,
  "ConsecutiveCorrectCount": 2
}
```

Flutter camelCase bekliyor:
```dart
final reviewCount = (e['reviewCount'] as num?)?.toInt() ?? 0;
// Eğer 'reviewCount' yoksa, 0 döner!
```

#### **Sonuç**: Backend doğru veriyi saklıyor ama Flutter parse edemiyor!

---

## 📊 Mevcut Akış Şeması

### 1️⃣ **Kelime Çalışma Akışı (Review Flow)**

```
┌─────────────────────────────────────────────────┐
│ KULLANICI AKSİYONU                              │
│ - Flashcard'da cevap verir                      │
│ - Quiz'de soru çözer                            │
│ - Practice modunda çalışır                      │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ FLUTTER: vocabulary_study_page.dart             │
│                                                 │
│ _onAnswerSubmitted(isCorrect, timeMs) {        │
│   context.read<VocabularyBloc>().add(          │
│     MarkWordReviewed(                          │
│       wordId: currentWord.id,                  │
│       isCorrect: isCorrect                     │
│     )                                          │
│   );                                           │
│ }                                              │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ FLUTTER: vocabulary_bloc.dart                   │
│                                                 │
│ _onMarkWordReviewed() {                        │
│   await repository.markWordReviewed(           │
│     event.wordId,                              │
│     event.isCorrect                            │
│   );                                           │
│   _lastStats = null;  // Force refresh         │
│   add(RefreshVocabulary());                    │
│ }                                              │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ FLUTTER: vocabulary_repository_impl.dart        │
│                                                 │
│ markWordReviewed(wordId, isCorrect) {          │
│   // POST /api/ApiUserVocabulary/{id}/review   │
│   await _net.post(                             │
│     '/api/ApiUserVocabulary/$wordId/review',   │
│     data: { 'isCorrect': isCorrect }           │
│   );                                           │
│                                                 │
│   // Güncel kelimeyi getir                     │
│   final updated = await getWordById(wordId);   │
│   _store.upsertWord(updated);  // Cache'e yaz  │
│ }                                              │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ BACKEND: ApiUserVocabularyController.cs         │
│                                                 │
│ [HttpPost("{id}/review")]                      │
│ Review(int id, VocabularyReviewDto body) {     │
│   var result = await _svc.ReviewAsync(         │
│     userId, id, body.IsCorrect                 │
│   );                                           │
│   return Ok(result);                           │
│ }                                              │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ BACKEND: UserVocabularyService.cs               │
│                                                 │
│ ReviewAsync(userId, id, isCorrect) {           │
│   var vocab = await _db.Find(id);              │
│                                                 │
│   // ✅ SAYAÇLARI GÜNCELLE                     │
│   vocab.ReviewCount += 1;                      │
│   if (isCorrect) {                             │
│     vocab.CorrectCount += 1;                   │
│     vocab.ConsecutiveCorrectCount += 1;        │
│   } else {                                     │
│     vocab.ConsecutiveCorrectCount = 0;         │
│   }                                            │
│                                                 │
│   // ✅ STATUS GÜNCELLE                        │
│   if (vocab.Status == "new_")                  │
│     vocab.Status = "learning";                 │
│   else if (consecutiveCorrect >= 3)            │
│     vocab.Status = "known";                    │
│   else if (consecutiveCorrect >= 6)            │
│     vocab.Status = "mastered";                 │
│                                                 │
│   // ✅ ZAMANLAMA GÜNCELLE                     │
│   vocab.LastReviewedAt = DateTime.UtcNow;      │
│   vocab.NextReviewAt = CalculateNextReview(); │
│                                                 │
│   // ✅ VERİTABANINA KAYDET                    │
│   await _db.SaveChangesAsync();                │
│                                                 │
│   // ❌ PascalCase DÖNDÜR (SORUN BURADA!)      │
│   return new {                                 │
│     totalReviews = total,                      │
│     correctReviews = correct,                  │
│     accuracy = accuracy,                       │
│     status = vocab.Status                      │
│   };                                           │
│ }                                              │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ VERİTABANI: UserVocabulary Tablosu             │
│                                                 │
│ ✅ KAYIT BAŞARILI!                             │
│ ReviewCount: 5                                 │
│ CorrectCount: 4                                │
│ ConsecutiveCorrectCount: 2                     │
│ Status: "learning"                             │
│ LastReviewedAt: "2025-11-02T10:30:00Z"         │
│ NextReviewAt: "2025-11-04T10:30:00Z"           │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ FLUTTER: getWordById() - Güncel Veriyi Getir   │
│                                                 │
│ GET /api/ApiUserVocabulary/{id}                │
│                                                 │
│ Backend Response:                              │
│ {                                              │
│   "success": true,                             │
│   "data": {                                    │
│     "Id": 123,                   ← PascalCase! │
│     "ReviewCount": 5,            ← PascalCase! │
│     "CorrectCount": 4,           ← PascalCase! │
│     "ConsecutiveCorrectCount": 2 ← PascalCase! │
│   }                                            │
│ }                                              │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ FLUTTER: _fromServer() Parsing                 │
│                                                 │
│ ❌ PARSING HATASI!                             │
│                                                 │
│ final reviewCount =                            │
│   (e['reviewCount'] as num?)?.toInt() ?? 0;   │
│   // 'reviewCount' yok, 'ReviewCount' var!     │
│   // Sonuç: 0                                  │
│                                                 │
│ final correctCount =                           │
│   (e['correctCount'] as num?)?.toInt() ?? 0;  │
│   // Sonuç: 0                                  │
│                                                 │
│ final consecutive =                            │
│   (e['consecutiveCorrectCount'] as num?)?.toInt() ?? 0; │
│   // Sonuç: 0                                  │
│                                                 │
│ ⚠️ TÜM SAYAÇLAR 0 OLARAK PARSE EDİLİYOR!       │
└─────────────┬───────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────────────┐
│ FLUTTER: UI Gösterimi                          │
│                                                 │
│ ❌ KULLANICI EKRANDA 0 GÖRÜYOR!                │
│                                                 │
│ • Toplam Tekrar: 0 ← YanlışShould be 5        │
│ • Doğru Cevap: 0 ← Yanlış, Should be 4        │
│ • Başarı Oranı: 0% ← Yanlış, Should be 80%    │
│ • Status: new_ ← Yanlış, Should be "learning" │
└─────────────────────────────────────────────────┘
```

---

## 🎯 Sorunun Kök Nedeni

### **Backend JSON Serialization Ayarları Eksik**

C# .NET Core varsayılan olarak **PascalCase** ile JSON serialize eder:

```csharp
// Backend döner:
{
  "ReviewCount": 5,
  "CorrectCount": 4
}
```

Flutter **camelCase** bekler:

```dart
// Flutter bekler:
{
  "reviewCount": 5,
  "correctCount": 4
}
```

### **Mevcut Kod (vocabulary_repository_impl.dart:106-109)**

```dart
final reviewCount = (e['reviewCount'] as num?)?.toInt() ?? 0;
final correctCount = (e['correctCount'] as num?)?.toInt() ?? 0;
final consecutive = (e['consecutiveCorrectCount'] as num?)?.toInt() ?? 0;
final difficulty = (e['difficulty'] as num?)?.toDouble() ?? 0.5;
```

**Eğer key yoksa → varsayılan değer (0) kullanılır!**

---

## ✅ Çözüm Seçenekleri

### **Çözüm 1: Backend'i camelCase'e Çevir (ÖNERİLEN)**

Backend'in `Program.cs` veya `Startup.cs` dosyasına:

```csharp
builder.Services.AddControllers()
    .AddJsonOptions(options => {
        options.JsonSerializerOptions.PropertyNamingPolicy = 
            JsonNamingPolicy.CamelCase;
    });
```

✅ **Artılar**: 
- Web standartlarına uygun
- Tüm endpointler otomatik düzelir
- Frontend ile tutarlı

❌ **Eksiler**:
- Tüm projeyi etkiler
- Mevcut mobil app güncellemesi gerekir

### **Çözüm 2: Flutter'da PascalCase Parse Et**

```dart
final reviewCount = (e['reviewCount'] ?? e['ReviewCount'] as num?)?.toInt() ?? 0;
final correctCount = (e['correctCount'] ?? e['CorrectCount'] as num?)?.toInt() ?? 0;
```

✅ **Artılar**: 
- Hızlı düzeltme
- Backend değişmez

❌ **Eksiler**:
- Her field için iki kez kontrol
- Kod kirliliği

### **Çözüm 3: Extension Method ile Güvenli Parse**

```dart
extension MapExtensions on Map<String, dynamic> {
  T? getIgnoreCase<T>(String key) {
    // Try exact match first
    if (containsKey(key)) return this[key] as T?;
    
    // Try case-insensitive match
    final lowerKey = key.toLowerCase();
    for (var entry in entries) {
      if (entry.key.toLowerCase() == lowerKey) {
        return entry.value as T?;
      }
    }
    return null;
  }
}

// Kullanım:
final reviewCount = e.getIgnoreCase<num>('reviewCount')?.toInt() ?? 0;
```

✅ **Artılar**: 
- En güvenli çözüm
- Hem PascalCase hem camelCase çalışır
- Eski uygulamalarla uyumlu

---

## 🔧 İKİNCİL SORUN: LocalVocabularyStore Mantık Hatası

### **Sorun:**

`local_vocabulary_store.dart` dosyasında `mergeWithPersisted` metodu:

```dart
return _wordStateById[incoming.id] = incoming.copyWith(
  reviewCount: existing.reviewCount != 0 ? existing.reviewCount : incoming.reviewCount,
  correctCount: existing.correctCount != 0 ? existing.correctCount : incoming.correctCount,
  status: existing.status, // ← SORUN BURADA!
);
```

**Problem:**
- `status: existing.status` → Eski status'ü kullanıyor
- Backend "learning" gönderse bile, cache'teki "new_" kalıyor

### **Düzeltilmiş Versiyon:**

```dart
return _wordStateById[incoming.id] = incoming.copyWith(
  status: incoming.status, // Backend'den gelen güncel status
  reviewCount: incoming.reviewCount > existing.reviewCount 
    ? incoming.reviewCount 
    : existing.reviewCount,
  correctCount: incoming.correctCount > existing.correctCount
    ? incoming.correctCount 
    : existing.correctCount,
);
```

---

## 📝 Özet

| Sorun | Etki | Çözüm | Öncelik |
|-------|------|-------|---------|
| Backend PascalCase döndürüyor | ⚠️ Kritik - Tüm sayaçlar 0 | Backend'i camelCase'e çevir | 🔴 Yüksek |
| Flutter Parse hatası | ⚠️ Kritik - Veri kaybı | Extension method ekle | 🔴 Yüksek |
| LocalStore status override | ⚠️ Orta - Status güncellenmiyor | `incoming.status` kullan | 🟡 Orta |
| In-memory cache | ⚠️ Düşük - Restart'ta kaybolur | Sorun değil (backend'den yüklenir) | 🟢 Düşük |

---

## 🎯 Önerilen Düzeltme Sırası

1. **Backend JSON ayarlarını düzelt** → camelCase
2. **Flutter'a Extension method ekle** → Case-insensitive parse
3. **LocalStore merge logic'i düzelt** → incoming.status kullan
4. **Test et**: 
   - Kelime çalış → Sayaçlar artıyor mu?
   - Uygulamayı kapat/aç → Veriler koruniyor mu?
   - Backend'i kontrol et → DB'de doğru değerler var mı?

---

## 🧪 Test Senaryosu

### **Test Adımları:**

1. Backend'den bir kelimeyi çağır:
   ```bash
   curl -H "Authorization: Bearer TOKEN" \
        https://api.../api/ApiUserVocabulary/123
   ```
   
   **Beklenen:** 
   ```json
   {
     "reviewCount": 5,
     "correctCount": 4
   }
   ```
   
   **Gerçek:** 
   ```json
   {
     "ReviewCount": 5,
     "CorrectCount": 4
   }
   ```

2. Flutter'da kelime çalış → Console'a log bas:
   ```dart
   print('Backend response: ${resp.data}');
   print('Parsed reviewCount: $reviewCount');
   ```

3. Veritabanını kontrol et:
   ```sql
   SELECT ReviewCount, CorrectCount, Status 
   FROM UserVocabulary 
   WHERE Id = 123;
   ```

---

## ✅ Sonuç

**Backend verileri doğru kaydediyor ✅**  
**Flutter verileri yanlış parse ediyor ❌**

**Çözüm:** Backend JSON serialization + Flutter case-insensitive parsing


