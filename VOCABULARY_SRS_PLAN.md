## Vocabulary SRS (Spaced Repetition) - Design and Flow

### Goals
- Tutarlı, backend ve veritabanı ile uyumlu bir kelime öğrenme sistemi.
- Doğru cevaplarda seviye (status) ilerlesin, yanlışta gerileme veya sabitleme.
- Aralıklı tekrarlarla `nextReviewAt` üzerinden planlama; mobil ve API arasında tek gerçek kaynak DB.

### States (Levels) and Meaning
- new_: yeni eklenen; ilk tekrar kısa sürede (1 saat)
- learning: öğrenme aşaması; ardışık doğru sayısına göre gün cinsinden artan aralık
- known: biliniyor; aralıklar daha uzun
- mastered: kalıcı; en uzun aralıklar

### Core Fields (DB and Domain)
- UserVocabulary
  - Status: new_ | learning | known | mastered
  - ConsecutiveCorrectCount: int (ardışık doğru sayısı)
  - ReviewCount: int (toplam tekrar)
  - CorrectCount: int (toplam doğru)
  - LastReviewedAt: datetime (UTC)
  - NextReviewAt: datetime (UTC) [PLAN: eklenecek]
  - Difficulty: double (0.0–1.0) [opsiyonel, varsayılan 0.5]
  - UpdatedAt: datetime (UTC)

- UserVocabularyReview
  - VocabularyId, UserId, IsCorrect, ResponseTimeMs, ReviewedAt (UTC), AccuracyAfter (double)

### Scheduling – Intervals
- new_: 1 saat
- learning: 1–3 gün (ConsecutiveCorrectCount’e göre)
- known: 3–14 gün (2x artış, üst sınır 14)
- mastered: 14–90 gün (7x artış, üst sınır 90)

Basit kural (client ve server aynı):
- new_ → Duration(hours: 1)
- learning → Duration(days: clamp(ConsecutiveCorrectCount, 1, 3))
- known → Duration(days: clamp(ConsecutiveCorrectCount*2, 3, 14))
- mastered → Duration(days: clamp(ConsecutiveCorrectCount*7, 14, 90))

### Status Evolution Rules
- Review sonucu doğru ise:
  - ConsecutiveCorrectCount += 1
  - Status yükseltme sınırları:
    - new_ → learning (ilk doğru)
    - learning → known (ConsecutiveCorrectCount ≥ 3)
    - known → mastered (ConsecutiveCorrectCount ≥ 6)
  - NextReviewAt = now + interval(status, ConsecutiveCorrectCount)

- Review sonucu yanlış ise:
  - ConsecutiveCorrectCount = 0
  - Status düşürme sınırları (yumuşak gerileme):
    - mastered → known
    - known → learning
    - learning/new_ → new_
  - NextReviewAt = now + interval(new_ veya güncel status, 0/1)

Not: Kurallar basit ve anlaşılır; ileride SM-2 benzeri ağırlıklandırma eklenebilir (Difficulty katsayısı ile).

### Server-Side Logic (IUserVocabularyService)
- ReviewAsync(userId, id, isCorrect):
  - Sonucu kaydet (UserVocabularyReview)
  - UserVocabulary üzerinde: ReviewCount++, CorrectCount (isCorrect ise)++, ConsecutiveCorrectCount güncelle
  - Status evrimi ve NextReviewAt hesapla
  - LastReviewedAt = now
  - UpdatedAt = now

- GetStatsAsync(userId):
  - byStatus dağılımı, todayAdded, todayReviewed, vb.

- StartSessionAsync / AddSessionItemAsync / CompleteSessionAsync:
  - Mevcut implementasyon korunur; session item’lar review kaydına ek yardımıcı olur.

### API Contracts (mevcut + teyit)
- POST /api/ApiUserVocabulary: { word, meaning, notes?, status?, readingTextId? } → 201/200 + dto
- PUT /api/ApiUserVocabulary/{id}: { word, meaning, notes?, status? }
- DELETE /api/ApiUserVocabulary/{id}
- GET /api/ApiUserVocabulary?status?&search?&offset&limit
- GET /api/ApiUserVocabulary/stats
- POST /api/ApiUserVocabulary/{id}/review: { isCorrect: bool }
- POST /api/ApiUserVocabulary/session/start
- POST /api/ApiUserVocabulary/session/{id}/item: { vocabularyId, isCorrect, timeMs }
- POST /api/ApiUserVocabulary/session/{id}/complete: { itemsCount, correctCount, durationSeconds }

### Mobile Flow
1) Due Words:
   - GET /api/ApiUserVocabulary?status=learning/known/mastered + client-side filter `NextReviewAt <= now`
   - Veya ileride server tarafı `due=true` filtresi eklenebilir.

2) Review Oturumu:
   - startReviewSession(): backend session start → id
   - kullanıcı cevap verdikçe markWordReviewed(id, isCorrect) ve AddSessionItem
   - completeReviewSession(session): itemsCount, correctCount, durationSeconds

3) Optimistic UI:
   - Review sonrası UI anında güncellenir; backend başarılı olursa kalıcı olur, aksi durumda retry.

4) Error/Retry:
   - Ağ hatasında 2 deneme (mevcut _retry), sonra local store’da görünüm korunur, sonraki etkileşimde yeniden dener.

### Data Model – Migration İhtiyacı
- UserVocabulary’a eklenecek alanlar:
  - NextReviewAt (timestamp with time zone, nullable)
  - ConsecutiveCorrectCount (int, default 0) [uygulamada var; DB’de yoksa eklenir]
  - Difficulty (double, default 0.5) [opsiyonel]
- İndeksler:
  - (UserId, Status)
  - (UserId, NextReviewAt)

### UI/UX Notları
- Kelime kartında mevcut status ve bir sonraki tekrar zamanı gösterilebilir.
- Hızlı “Doğru / Yanlış” aksiyonları ve session progress bar.

### Açık Noktalar / Geliştirme Sırası
1) Migration: NextReviewAt (+ gerekli ek alanlar)
2) Service: ReviewAsync içinde status/interval/nextReviewAt mantığını netleştir
3) API teyidi: mevcut endpointler yeterli
4) Mobile: due words ve session akışında NextReviewAt kullanımı
5) Analytics: günlük/haftalık ilerleme, streak

Bu plan, mevcut basit kural tabanlı SRS ile uyumlu ve ileride SM‑2 benzeri algoritmalara evrilebilecek şekilde tasarlanmıştır.


