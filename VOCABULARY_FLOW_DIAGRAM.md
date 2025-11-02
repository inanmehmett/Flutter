# 📊 Kelime Sistemi - Görsel Akış Şeması

## 🎯 1. Kelime Çalışma Akışı (Review Flow)

```mermaid
sequenceDiagram
    participant U as 👤 Kullanıcı
    participant UI as 📱 Flutter UI
    participant Bloc as 🧠 VocabularyBloc
    participant Repo as 💾 Repository
    participant API as 🌐 Backend API
    participant DB as 🗄️ Database
    
    U->>UI: Kelime çalışır (Doğru cevap)
    UI->>Bloc: MarkWordReviewed(id: 123, isCorrect: true)
    Bloc->>Repo: markWordReviewed(123, true)
    Repo->>API: POST /api/ApiUserVocabulary/123/review
    API->>DB: UPDATE UserVocabulary SET ReviewCount += 1
    DB-->>API: ✅ Kaydedildi
    API-->>Repo: {success: true, data: {...}}
    Repo->>API: GET /api/ApiUserVocabulary/123
    API->>DB: SELECT * FROM UserVocabulary WHERE Id = 123
    DB-->>API: {reviewCount: 6, correctCount: 5, ...}
    API-->>Repo: Güncel Word Data
    Repo->>Repo: _fromServer() - Parse JSON ✅
    Repo->>Repo: LocalStore.merge() - Cache ✅
    Repo-->>Bloc: ✅ Word updated
    Bloc->>Repo: getUserStats()
    Repo->>API: GET /api/ApiUserVocabulary/stats
    API-->>Repo: Fresh stats
    Bloc->>UI: emit(VocabularyLoaded(...))
    UI->>U: 🎉 İlerleme gösterildi!
```

---

## 🔄 2. Uygulama Başlatma Akışı (App Launch)

```mermaid
sequenceDiagram
    participant U as 👤 Kullanıcı
    participant App as 📱 Flutter App
    participant Store as 💾 LocalStore
    participant API as 🌐 Backend API
    participant DB as 🗄️ Database
    
    U->>App: Uygulamayı açar
    App->>Store: LocalStore oluştur
    Note over Store: _wordStateById = {} <br/>(BOŞ - in-memory)
    App->>API: GET /api/ApiUserVocabulary
    API->>DB: SELECT * FROM UserVocabulary
    DB-->>API: Tüm kelimeler (with progress)
    API-->>App: [{reviewCount: 6, ...}, ...]
    App->>App: _fromServer() - Parse each word
    App->>Store: merge() - Cache'e ekle
    Note over Store: _wordStateById[123] = word ✅
    App->>U: 📊 İlerleme gösterildi!
```

---

## 🐛 3. Bug'lı Durum (ESKİ KOD - DÜZELTİLDİ)

```mermaid
flowchart TD
    A[Backend: reviewCount = 6] -->|Response| B[Flutter Alır]
    B --> C{LocalStore'da<br/>bu kelime var mı?}
    C -->|Hayır existing=null| D[incoming.reviewCount kullan = 6 ✅]
    C -->|Evet existing var| E{❌ ESKİ BUG:<br/>existing.reviewCount != 0?}
    E -->|Evet != 0| F[❌ existing.reviewCount kullan = 3<br/>YANLIŞ!]
    E -->|Hayır = 0| G[incoming.reviewCount kullan = 6]
    F --> H[❌ UI: 3 gösterir<br/>Ama DB'de 6 var!]
    G --> I[✅ UI: 6 gösterir]
    D --> I
    
    style F fill:#f66,color:#fff
    style H fill:#f66,color:#fff
    style I fill:#6f6,color:#000
```

---

## ✅ 4. Düzeltilmiş Durum (YENİ KOD)

```mermaid
flowchart TD
    A[Backend: reviewCount = 6] -->|Response| B[Flutter Alır]
    B --> C[✅ _fromServer parse]
    C --> D[✅ Case-insensitive getInt]
    D --> E[reviewCount = 6]
    E --> F{LocalStore merge}
    F -->|✅ YENİ KOD| G[HER ZAMAN incoming kullan]
    G --> H[incoming.reviewCount = 6]
    H --> I[Cache'e kaydet: 6]
    I --> J[✅ UI: 6 gösterir]
    
    style C fill:#6f6,color:#000
    style D fill:#6f6,color:#000
    style G fill:#6f6,color:#000
    style J fill:#6f6,color:#000
```

---

## 🔍 5. Veri Katmanları (Data Layers)

```mermaid
flowchart LR
    subgraph Backend
        API[🌐 API Controllers]
        SVC[⚙️ Services]
        DB[(🗄️ PostgreSQL)]
    end
    
    subgraph Flutter
        UI[📱 UI Widgets]
        BLOC[🧠 BLoC]
        REPO[💾 Repository]
        STORE[📦 LocalStore<br/>in-memory]
    end
    
    UI <-->|Events/States| BLOC
    BLOC <-->|Methods| REPO
    REPO <-->|HTTP| API
    REPO <-->|Cache| STORE
    API <-->|Queries| SVC
    SVC <-->|CRUD| DB
    
    style DB fill:#ff9,color:#000
    style STORE fill:#9cf,color:#000
```

---

## 🎯 6. Status Progression (İlerleme Basamakları)

```mermaid
stateDiagram-v2
    [*] --> new_: Kelime eklendi
    new_ --> learning: İlk doğru cevap ✅
    learning --> known: 3 ardışık doğru ✅✅✅
    known --> mastered: 6 ardışık doğru ✅✅✅✅✅✅
    
    mastered --> known: Yanlış cevap ❌
    known --> learning: Yanlış cevap ❌
    learning --> new_: Yanlış cevap ❌
    
    note right of new_
        🔵 Yeni Kelime
        NextReview: 1 saat
    end note
    
    note right of learning
        🟡 Öğreniliyor
        NextReview: 1-3 gün
    end note
    
    note right of known
        🟢 Biliniyor
        NextReview: 3-14 gün
    end note
    
    note right of mastered
        🟣 Uzman
        NextReview: 14-90 gün
    end note
```

---

## 🧪 7. Test Senaryoları

```mermaid
flowchart TD
    START([Test Başlat]) --> T1[Test 1:<br/>Kelime Çalış]
    T1 --> T1A{ReviewCount arttı mı?}
    T1A -->|Evet ✅| T2[Test 2:<br/>App Restart]
    T1A -->|Hayır ❌| FAIL1[❌ Backend veya<br/>API hatası]
    
    T2 --> T2A[App'i kapat]
    T2A --> T2B[App'i aç]
    T2B --> T2C{Veri korundu mu?}
    T2C -->|Evet ✅| T3[Test 3:<br/>Status Progression]
    T2C -->|Hayır ❌| FAIL2[❌ Backend okuma<br/>hatası]
    
    T3 --> T3A[Yeni kelime ekle]
    T3A --> T3B[3 doğru cevap ver]
    T3B --> T3C{Status = known?}
    T3C -->|Evet ✅| SUCCESS([✅ TÜM TESTLER BAŞARILI])
    T3C -->|Hayır ❌| FAIL3[❌ Status update<br/>hatası]
    
    style SUCCESS fill:#6f6,color:#000
    style FAIL1 fill:#f66,color:#fff
    style FAIL2 fill:#f66,color:#fff
    style FAIL3 fill:#f66,color:#fff
```

---

## 📊 8. Veri Akışı Özeti

```mermaid
graph TD
    A[👤 User Action] -->|1| B[📱 Flutter UI]
    B -->|2| C[🧠 BLoC Event]
    C -->|3| D[💾 Repository]
    D -->|4| E[🌐 HTTP Request]
    E -->|5| F[⚙️ Backend Service]
    F -->|6| G[(🗄️ Database UPDATE)]
    G -->|7| F
    F -->|8| E
    E -->|9| D
    D -->|10| H[📦 Parse & Cache]
    H -->|11| C
    C -->|12| B
    B -->|13| I[🎉 UI Update]
    
    style A fill:#ff9,color:#000
    style G fill:#9f9,color:#000
    style I fill:#9cf,color:#000
```

---

## 🔧 9. Debug Points (Hata Ayıklama Noktaları)

```mermaid
flowchart TD
    START([Sorun var!]) --> Q1{Console'da<br/>log var mı?}
    Q1 -->|Hayır| D1[🔴 Log eklenmemiş<br/>veya build hatası]
    Q1 -->|Evet| Q2{Hangi log<br/>görünüyor?}
    
    Q2 -->|📝 Marking word...| Q3{✅ Backend response<br/>görünüyor mu?}
    Q3 -->|Hayır| D2[🔴 API isteği başarısız<br/>Network/Auth kontrol et]
    Q3 -->|Evet| Q4{🔄 Parsing log'da<br/>reviewCount > 0?}
    
    Q4 -->|Hayır| D3[🔴 JSON parsing hatası<br/>Backend response kontrol et]
    Q4 -->|Evet| Q5{📊 Updated stats<br/>log doğru mu?}
    
    Q5 -->|Hayır| D4[🔴 LocalStore merge<br/>hatası olabilir]
    Q5 -->|Evet| Q6{UI'da doğru<br/>gösteriyor mu?}
    
    Q6 -->|Hayır| D5[🔴 BLoC state<br/>güncellenmiyor]
    Q6 -->|Evet| SUCCESS([✅ Sistem çalışıyor!])
    
    style SUCCESS fill:#6f6,color:#000
    style D1 fill:#f66,color:#fff
    style D2 fill:#f66,color:#fff
    style D3 fill:#f66,color:#fff
    style D4 fill:#f66,color:#fff
    style D5 fill:#f66,color:#fff
```

---

## 🎯 Özet Akış (High-Level)

```mermaid
graph LR
    A[Kullanıcı<br/>Çalışır] --> B[Flutter<br/>→ Backend]
    B --> C[Backend<br/>→ Database]
    C --> D[Database<br/>Kaydeder ✅]
    D --> E[Backend<br/>→ Flutter]
    E --> F[Flutter<br/>Parse ✅]
    F --> G[LocalStore<br/>Cache ✅]
    G --> H[UI<br/>Göster ✅]
    
    I[App<br/>Restart] --> J[Flutter<br/>→ Backend]
    J --> K[Backend<br/>→ Database]
    K --> L[Database<br/>Okur ✅]
    L --> M[Backend<br/>→ Flutter]
    M --> N[Flutter<br/>Yükler ✅]
    N --> O[UI<br/>İlerleme<br/>Korunur ✅]
    
    style D fill:#9f9,color:#000
    style H fill:#9cf,color:#000
    style O fill:#9cf,color:#000
```

---

## 📝 Notlar

### Akış Şemalarını Görüntülemek İçin:

1. **GitHub/GitLab:** Bu markdown dosyasını push edin, otomatik render edilir
2. **VS Code:** "Markdown Preview Mermaid Support" eklentisini yükleyin
3. **Online:** https://mermaid.live adresine gidin ve kodu yapıştırın
4. **Obsidian:** Doğrudan render eder

### Renk Kodları:

- 🟢 Yeşil: Başarılı durum
- 🔴 Kırmızı: Hata/Problem
- 🟡 Sarı: Uyarı/Dikkat
- 🔵 Mavi: Normal akış

### Semboller:

- 📱 Flutter/Mobile
- 🌐 Backend API
- 🗄️ Database
- 🧠 BLoC/State Management
- 💾 Repository/Data Layer
- 📦 Cache/Storage
- 👤 User/Kullanıcı
- ✅ Başarılı
- ❌ Başarısız


