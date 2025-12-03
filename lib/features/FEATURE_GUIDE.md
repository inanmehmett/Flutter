# 📚 DailyEnglish - Feature Guide

## 🗂️ Features Klasör Yapısı

### 1. 📖 `vocabulary_notebook/` - Kişisel Kelime Defteri (SRS Tabanlı)

**Amaç:** Kullanıcının kendi kelime defterini yönetmesi ve Spaced Repetition System (SRS) ile öğrenmesi.

**Özellikler:**
- ✅ Kişisel kelime ekleme/düzenleme/silme
- ✅ Spaced Repetition System (SRS)
- ✅ 3 Çalışma Modu:
  - **ÇALIŞ:** Due kelimeleri (SRS tabanlı)
  - **PRATİK:** Zor kelimeler (typing practice)
  - **KART:** Rastgele kelimeler (flashcards)
- ✅ İlerleme takibi (new → learning → known → mastered)
- ✅ Kelime istatistikleri

**Kullanım:**
```
Anasayfa → Kelime Defteri Kartı → /vocabulary
```

---

### 2. 🎯 `word_exercises/` - Kelime Alıştırmaları (Seviye Bazlı Quiz)

**Amaç:** Seviye bazlı genel kelime alıştırmaları ve quiz'ler (kişisel defterden BAĞIMSIZ).

**Planlanan Özellikler:**
- 🔲 Seviye bazlı kelime quiz'leri (A1, A2, B1, B2, C1, C2)
- 🔲 Kelime türüne göre alıştırmalar (fiil, isim, sıfat)
- 🔲 Tematik kelime setleri (iş, seyahat, yemek, vb.)
- 🔲 Günlük kelime challenge'ları
- 🔲 Kişisel defterden BAĞIMSIZ ilerleme

**Mevcut Sayfalar:**
- `/word-exercises` → Kelime listesi
- `/word-exercises/flashcards` → Flashcard'lar
- `/word-exercises/quiz` → Quiz

**Not:** Bu feature henüz tam geliştirilmemiş, eski kodlar var.

---

### 3. 📕 `reader/` - Kitap Okuma ve Reading Quiz

**Amaç:** İngilizce kitap okuma ve anlama testi.

**Özellikler:**
- ✅ Kitap okuma (advanced reader)
- ✅ Kitap quiz'leri (reading comprehension)
- ✅ Kelime çevirisi (inline)
- ✅ TTS (Text-to-Speech)
- ✅ Reading session tracking
- ✅ Progress tracking

---

### 4. 🏆 `game/` - Gamification ve Liderlik Tablosu

**Amaç:** XP, seviye, rozet, liderlik tablosu.

**Özellikler:**
- ✅ XP sistemi
- ✅ Liderlik tablosu
- ✅ Rozet sistemi
- ✅ Streak tracking

---

### 5. 🎓 `quiz/` - Genel Quiz Sistemi

**Amaç:** Vocabulary quiz ve genel quiz altyapısı.

**Özellikler:**
- ✅ Vocabulary quiz
- ✅ Quiz repository pattern
- ✅ Quiz cubit/state management

---

### 6. 👤 `auth/` - Kimlik Doğrulama

**Amaç:** Login, register, profil yönetimi.

---

### 7. 🏠 `home/` - Anasayfa

**Amaç:** Dashboard, quick access, genel bakış.

---

### 8. 👥 `user/` - Kullanıcı Ayarları

**Amaç:** Profil detayları, bildirimler, gizlilik.

---

## 🔄 VOCABULARY_NOTEBOOK vs WORD_EXERCISES Farkı

### `vocabulary_notebook/` (Kişisel Defter)
```dart
// Kullanıcı kendi kelimelerini ekler
UserVocabulary {
  userId: "123",
  word: "apple",
  status: "learning",        // SRS durumu
  nextReviewAt: "2025-12-05", // SRS zamanlaması
  reviewCount: 5,
  consecutiveCorrect: 2
}

// SRS algoritması ile yönetilir
// Kişiye özel ilerleme
```

### `word_exercises/` (Genel Quiz/Alıştırma)
```dart
// Sistemdeki genel kelimeler
Vocabulary {
  word: "apple",
  meaning: "elma",
  level: "A1",
  category: "fruits"
}

// Seviye bazlı seçilir
// Tüm kullanıcılar için aynı kelime havuzu
// SRS YOK, genel quiz mantığı
```

---

## 📝 ÖNERİLER

### 1. `vocab/` Klasörü Yeniden Adlandırıldı ✅

**Önceki:** `lib/features/vocab/`
**Şimdiki:** `lib/features/word_exercises/` ✅

**Neden:**
- "vocab" ve "vocabulary_notebook" çok benzer
- Karışıklık yaratıyor
- Amaç netleşir

### 2. Routes'ları Netleştir

**Önceki:**
```dart
'/vocabulary' → VocabularyNotebookPage  // Kişisel defter
'/learning-list' → LearningListPage     // Genel alıştırma
```

**Şimdiki:**
```dart
'/vocabulary' → VocabularyNotebookPage       // Kişisel defterim
'/word-exercises' → LearningListPage         // Genel alıştırmalar
'/word-exercises/flashcards' → FlashcardsPage
'/word-exercises/quiz' → VocabQuizPage
```

### 3. UI'da Net Ayrım

**Anasayfa Kartları:**
```
┌─────────────────────────┐  ┌─────────────────────────┐
│  📚 KELİME DEFTERİM      │  │  🎯 KELİME ALIŞTIRMA   │
│                         │  │                         │
│  SRS ile öğren          │  │  Seviye bazlı quiz     │
│  12 kelime bekliyor     │  │  A2 - B1 alıştırmaları │
│                         │  │                         │
│  [Çalışmaya Başla]      │  │  [Quiz Çöz]           │
└─────────────────────────┘  └─────────────────────────┘
   vocabulary_notebook/           vocab/
```

---

## ✅ YAPISAL KALİTE PUANI

| Kategori | Puan | Not |
|----------|------|-----|
| Clean Architecture | ⭐⭐⭐⭐⭐ | Perfect layering |
| State Management | ⭐⭐⭐⭐⭐ | BLoC pattern |
| Dependency Injection | ⭐⭐⭐⭐⭐ | Injectable + GetIt |
| Code Organization | ⭐⭐⭐⭐☆ | İyi ama isimlendirme iyileştirilebilir |
| Widget Reusability | ⭐⭐⭐⭐☆ | Bazı duplicate'ler var |
| **GENEL** | **⭐⭐⭐⭐½** | **4.5/5** |

---

**Son Güncelleme:** 3 Aralık 2025

