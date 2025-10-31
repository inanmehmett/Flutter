## Kelime Defterim – Backend ve Mobil Entegrasyon Planı

### 1) Mevcut Özellikler ve İhtiyaçlar

- Özellikler
  - Kelime listesi, durum filtreleri (new_/learning/known/mastered), arama, sayfalama
  - Kelime ekle/güncelle/sil
  - Çalışma/oturum akışı: “Bugün çalışılacak”, tekrar sayacı, doğru/yanlış sonuçları
  - İstatistikler: toplam, statü kırılımı, bugün eklenen/tekrar edilen, ilerleme yüzdesi
  - Kelime detay: örnek cümle, notlar, konuşma (TTS)

- İhtiyaçlar
  - Kullanıcı bazlı kalıcı saklama (backend)
  - Review kayıtları (doğru/yanlış, accuracy/mastery ilerlemesi)
  - Oturum kaydı (başlangıç/bitiş, doğru sayısı, süre)
  - Güvenli API: arama, filtre, sayfalama; mevcut response formatına uyum
  - Gelecekte offline ve senkronizasyon desteği (kademeli)

---

### 2) Backend Yapısı (Mevcut .NET + EF Core Mimarisine Uyumlu)

- DataAccess/DbModels
  - `UserVocabulary`: Id, UserId, StableId(Guid), Word, Meaning, Notes, Status, CreatedAt, UpdatedAt, DeletedAt
  - `UserVocabularyReview`: Id, UserId, VocabularyId, IsCorrect, AccuracyAfter, ReviewedAt
  - `UserVocabularySession`: Id, UserId, StartedAt, EndedAt, DurationSeconds, ItemsCount, CorrectCount
  - `UserVocabularySessionItem`: Id, SessionId, VocabularyId, IsCorrect, TimeMs

- DTOModels
  - `UserVocabularyDto`, `VocabularyReviewDto`, `VocabularySessionDto`, `VocabularyStatsDto`

- Services
  - `IUserVocabularyService`
  - `UserVocabularyService`: CRUD + search/paginate/filter + stats + review + session kayıtları

- Controllers
  - `ApiUserVocabularyController`
    - `GET /api/ApiUserVocabulary?status&search&offset&limit`
    - `POST /api/ApiUserVocabulary`
    - `PUT /api/ApiUserVocabulary/{id}`
    - `DELETE /api/ApiUserVocabulary/{id}` (soft delete)
    - `GET /api/ApiUserVocabulary/stats`
    - `POST /api/ApiUserVocabulary/{id}/review`

- Ortak İlkeler
  - Response formatı: `{ success, message, data }`
  - Kimlik: claims’den `userId`
  - Çakışma: `UpdatedAt` tabanlı last‑write‑wins, silme öncelikli
  - İndeksler: `(UserId, Status)`, `(UserId, UpdatedAt)`, `(UserId, WordLower)`

- (Opsiyonel) Sync İskeleti
  - `POST /api/ApiUserVocabulary/sync/push` → operations batch
  - `GET /api/ApiUserVocabulary/sync/pull?since=token` → delta

---

### 3) Plan (Sprint Kırılımı)

#### Sprint 1: Veri Modeli ve CRUD
1. EF Core modelleri + migration — [x] (modeller eklendi, migration sonraki committe)
2. `IUserVocabularyService` + `UserVocabularyService` → CRUD, arama, sayfalama, filtre — [x]
3. `ApiUserVocabularyController` → CRUD uçları (response standardı, logging) — [x]
4. Mobil repository → list/add/update/delete uçlarına bağlama — [x]

#### Sprint 2: Review + Stats
1. Review endpoint → doğrulama ve accuracy/mastery güncellemeleri — [x]
2. Session/SessionItem temel kayıtları — [x]
3. Stats endpoint → toplam, status dağılım, bugün eklenen/tekrar, ilerleme% — [x]
4. Mobil çalışma akışı → review çağrıları + istatistik entegrasyonu — [x]

#### Sprint 3: Stabilizasyon + UX
1. Hata yönetimi (409, doğrulama), retry politikaları
2. Performans: indeksler, sayfalama varsayılanları
3. (İleri tarih) Sync push/pull iskeleti

---

### 4) Uygulama Adımları (Adım Adım)

1) EF Core veritabanı şemasını ekle ve migration oluştur — [~] (modeller eklendi, migration çıkarılacak)

2) `IUserVocabularyService` + `UserVocabularyService` — [x]
   - CRUD (create/update/delete soft), get/list
   - Arama (LIKE), statü filtreleri, offset/limit sayfalama

3) `ApiUserVocabularyController` — [x]
   - CRUD uçları + `GET /stats`
   - Response standardı `{ success, message, data }`

4) Mobil `VocabularyRepositoryImpl` entegrasyonu — [x]
   - list/add/update/delete → yeni endpoint’ler
   - Mevcut Bloc ve UI’yi bozmayacak adapter katmanı

5) Review endpoint + mobil bağlama — [x]
   - `POST /{id}/review { isCorrect }`
   - Doğru/yanlış sonrası yerel state güncelleme

6) Stats hesaplama ve mobil entegrasyon — [x]
   - Dashboard/başlıkta gösterilen istatistikler
   - Oturum başlat/tamamla + item kaydı — [x]

7) Test ve Hata Yönetimi
   - Service ve Controller unit/integration testleri
   - Mobil tarafında Dio hata mesajları (409/400/500) için kullanıcı dostu geri bildirim

---

### 5) Mobil Tarafta Kısa Notlar

- Repository çağrıları yeni uçlara taşınır; Bloc/Widget sözleşmesi korunur.
- Yazma işlemlerinde optimistic UI + retry (ağ hatalarında).
- Offline için kademeli plan: ilk etapta server‑first; ileride local‑first + sync kuyruğu eklenebilir (aynı API sözleşmesiyle).


