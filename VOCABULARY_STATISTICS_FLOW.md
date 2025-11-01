# Vocabulary Learning Statistics Flow

## 📊 Comprehensive Statistics Documentation

### 1️⃣ **Backend: Statistics Calculation & Storage**

#### **Database Fields (UserVocabulary)**

Located in: `DailyEnglish/DataAccess/DbModels/UserVocabulary.cs`

```csharp
// Core counters
public int ReviewCount { get; set; }           // Total review attempts
public int CorrectCount { get; set; }          // Total correct answers
public int ConsecutiveCorrectCount { get; set; } // Current streak

// Scheduling
public DateTime? LastReviewedAt { get; set; }  // Last review timestamp
public DateTime? NextReviewAt { get; set; }    // Next scheduled review
public double Difficulty { get; set; }         // 0.0-1.0 (easy to hard)

// Status progression
public string Status { get; set; }             // new_ → learning → known → mastered
```

#### **Statistics Calculation (UserVocabularyService.cs)**

**A. GetStatsAsync** - Overall Statistics

```csharp
Location: Line 111-122

Returns:
{
  total: int,                    // Total words count
  byStatus: [                    // Count by status
    { status: "new_", count: X },
    { status: "learning", count: Y },
    { status: "known", count: Z },
    { status: "mastered", count: W }
  ],
  todayAdded: int,               // Words added today (CreatedAt >= today)
  todayReviewed: int,            // Reviews done today (from UserVocabularyReview table)
  progress: double               // (known + mastered) / total
}
```

**B. ReviewAsync** - Per-Word Statistics Update

```csharp
Location: Line 124-172

When user answers:
1. Create UserVocabularyReview record
2. Update counters:
   - ReviewCount += 1
   - If correct: CorrectCount += 1, ConsecutiveCorrectCount += 1
   - If wrong: ConsecutiveCorrectCount = 0
3. Calculate accuracy: CorrectCount / ReviewCount
4. Status evolution:
   - new_ → learning (first correct)
   - learning → known (3 consecutive correct)
   - known → mastered (6 consecutive correct)
   - Demotion on wrong answer
5. Schedule next review (CalculateNextReview)
6. Store AccuracyAfter in review record
```

**C. CalculateNextReview** - Spaced Repetition Logic

```csharp
Location: Line 212-235

Intervals:
- new_: 1 hour
- learning: 1-3 days (based on consecutiveCorrect)
- known: 3-14 days (consecutiveCorrect * 2)
- mastered: 14-90 days (consecutiveCorrect * 7)

Difficulty scaling:
- Easy words (0.0): longer intervals (+30%)
- Hard words (1.0): shorter intervals (-30%)
```

---

### 2️⃣ **Mobile: Statistics Fetching**

#### **Repository Layer**

Located in: `Flutter/lib/features/vocabulary_notebook/data/repositories/vocabulary_repository_impl.dart`

**A. getUserStats()** - Line 358-407

```dart
Flow:
1. Call backend: GET /api/ApiUserVocabulary/stats
2. Parse response:
   - totalWords
   - newWords, learningWords, knownWords, masteredWords (from byStatus)
   - wordsAddedToday
   - wordsReviewedToday
3. Fallback: Calculate from local store if API fails
4. Return VocabularyStats entity
```

**B. markWordReviewed()** - Line 462-510

```dart
Flow:
1. Call backend: PUT /api/ApiUserVocabulary/{id}/review
   Body: { isCorrect: bool }
2. Backend updates counters & status
3. Fetch updated word: GET /api/ApiUserVocabulary/{id}
4. Update local store with fresh data
5. Return updated VocabularyWord
```

**C. Local Fallback Statistics**

```dart
When API fails:
- Count words by status from local store
- Calculate accuracy from reviewCount/correctCount
- Detect today's additions by comparing dates
- Use SpacedRepetitionService for streak calculation
```

---

### 3️⃣ **Mobile: Statistics Display**

#### **A. Vocabulary List Header**

Widget: `VocabularyStatsHeader`
Location: `lib/features/vocabulary_notebook/presentation/widgets/vocabulary_stats_header.dart`

**Displays:**

```
┌──────────────────────────────────┐
│ 🔥 Bugün Çalışılacak             │
│ 10 tekrar kelime • 3 yeni        │
│ [Başla] [Quiz]                   │
└──────────────────────────────────┘

┌──────┐ ┌──────┐ ┌──────────┐
│Toplam│ │Tekrar│ │ İlerleme │
│  25  │ │  10  │ │   60%    │
└──────┘ └──────┘ └──────────┘
```

**Data Source:**

- `stats.totalWords` - Total count
- `stats.wordsNeedingReview` - Due for review
- `stats.learningProgress` - (known + mastered) / total
- `stats.wordsAddedToday` - Added today

#### **B. Word Detail Page**

Widget: `VocabularyWordDetailPage`
Location: `lib/features/vocabulary_notebook/presentation/pages/vocabulary_word_detail_page.dart`

**Displays (Line 403-445):**

**For New Words (reviewCount == 0):**

```
┌─────────────────────────────────┐
│ 🎯 Yeni Kelime                  │
│ Bu kelimeyi ilk kez çalışacaksın│
└─────────────────────────────────┘
```

**For Reviewed Words:**

```
📊 İstatistikler:
- Toplam Tekrar: 15 times
- Doğru Cevap: 12 times
- Başarı Oranı: 80.0%
- Ardışık Doğru: 3 streak
- Zorluk Seviyesi: Orta (0.5)
```

**Learning Status Timeline (Line 477-534):**

```
Progress: ████████░░░░ 60%

new_ → learning → known → mastered
```

**Next Review Info (Line 536-583):**

```
📅 Sonraki Tekrar:
- Overdue: 🔴 2 saat gecikmiş!
- Due soon: 🟡 1 saat içinde
- Future: 🟢 3 gün sonra
```

**Data Source:**

- `word.reviewCount` - Total reviews
- `word.correctCount` - Correct answers
- `word.accuracyRate` - correctCount / reviewCount
- `word.consecutiveCorrectCount` - Current streak
- `word.difficultyLevel` - 0.0-1.0
- `word.lastReviewedAt` - Last review timestamp
- `word.nextReviewAt` - Next scheduled review
- `word.status` - Current learning status

#### **C. Word Card in List**

Widget: `VocabularyWordCard`
Location: `lib/features/vocabulary_notebook/presentation/widgets/vocabulary_word_card.dart`

**Displays:**

```
┌────────────────────────────┐
│ BEAUTIFUL        [new_] 🔊 │
│ güzel                      │
│ 📅 Sonraki tekrar: 2 saat  │
└────────────────────────────┘
```

**Data Source:**

- `word.status` - Status badge color
- `word.nextReviewAt` - Time until next review

---

### 4️⃣ **State Management: BLoC Pattern**

#### **VocabularyBloc**

Location: `lib/features/vocabulary_notebook/presentation/bloc/vocabulary_bloc.dart`

**Statistics Updates:**

**A. Load Vocabulary** (Line 40-52)

```dart
emit(VocabularyLoading());
words = await repository.getUserWords();
stats = await repository.getUserStats(); ← Fetch stats
emit(VocabularyLoaded(words, stats));
```

**B. After Review** (Line 145-165)

```dart
1. Call repository.markWordReviewed(wordId, isCorrect)
2. Backend updates: ReviewCount, CorrectCount, Status
3. Fetch fresh stats: repository.getUserStats()
4. Re-emit VocabularyLoaded with updated stats
```

**C. After Add Word** (Line 105-140)

```dart
1. Call repository.addWord(word)
2. Refresh stats: repository.getUserStats()
3. Update UI with new stats (todayAdded++)
```

#### **VocabularyState**

Location: `lib/features/vocabulary_notebook/presentation/bloc/vocabulary_state.dart`

```dart
class VocabularyLoaded extends VocabularyState {
  final List<VocabularyWord> words;
  final VocabularyStats stats;        ← Always included
  final String? selectedStatus;
  final String? searchQuery;
  final bool hasMore;
}
```

---

### 5️⃣ **Statistics Flow Diagram**

```
USER ACTION
    ↓
┌───────────────────────────────────┐
│ Mobile: Answer Question           │
│ - FlashcardWidget                 │
│ - QuizWidget                      │
│ - PracticeWidget                  │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│ VocabularyBloc                    │
│ - _onMarkWordReviewed()           │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│ VocabularyRepositoryImpl          │
│ - markWordReviewed(id, isCorrect) │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│ Backend API                       │
│ PUT /api/ApiUserVocabulary/{id}/  │
│     review?isCorrect=true         │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│ UserVocabularyService.ReviewAsync │
│ 1. ReviewCount++                  │
│ 2. CorrectCount++ (if correct)    │
│ 3. Update ConsecutiveCorrect      │
│ 4. Calculate Accuracy             │
│ 5. Evolve Status                  │
│ 6. Schedule NextReviewAt          │
│ 7. Save to DB                     │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│ Database (SQL Server)             │
│ - UserVocabulary table updated    │
│ - UserVocabularyReview record     │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│ Mobile: Fetch Fresh Stats         │
│ GET /api/ApiUserVocabulary/stats  │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│ VocabularyBloc                    │
│ - getUserStats()                  │
│ - emit VocabularyLoaded(stats)    │
└───────────────────────────────────┘
    ↓
┌───────────────────────────────────┐
│ UI Update                         │
│ - VocabularyStatsHeader           │
│ - VocabularyWordCard              │
│ - VocabularyWordDetailPage        │
└───────────────────────────────────┘
```

---

### 6️⃣ **Key Statistics Metrics**

| Metric                 | Calculation                | Where Used                    | Purpose             |
| ---------------------- | -------------------------- | ----------------------------- | ------------------- |
| **ReviewCount**        | Total attempts             | Detail page, sorting          | Show engagement     |
| **CorrectCount**       | Sum of correct             | Detail page                   | Show success        |
| **AccuracyRate**       | CorrectCount / ReviewCount | Detail page, difficulty       | Measure performance |
| **ConsecutiveCorrect** | Streak counter             | Detail page, status evolution | Track mastery       |
| **Difficulty**         | Dynamic (0.0-1.0)          | Scheduling, sorting           | Adapt intervals     |
| **Status**             | Evolves with reviews       | Badges, filters               | Learning stage      |
| **NextReviewAt**       | Calculated interval        | "Due" filter, badges          | Spaced repetition   |
| **TodayAdded**         | Count(CreatedAt >= today)  | Header                        | Daily progress      |
| **TodayReviewed**      | Count(ReviewedAt >= today) | Header                        | Daily activity      |
| **LearningProgress**   | (known + mastered) / total | Header                        | Overall mastery     |

---

### 7️⃣ **Statistics Update Triggers**

| Event                    | Updates                                     | Backend Call                | UI Refresh |
| ------------------------ | ------------------------------------------- | --------------------------- | ---------- |
| **Add Word**             | todayAdded++                                | POST /api/ApiUserVocabulary | ✅ Auto    |
| **Review Word**          | reviewCount++, correctCount++, status, etc. | PUT /api/.../review         | ✅ Auto    |
| **Delete Word**          | total--, status counts                      | DELETE /api/...             | ✅ Auto    |
| **Manual Status Change** | NextReviewAt recalculated                   | PUT /api/...                | ✅ Auto    |
| **Page Load**            | -                                           | GET /api/.../stats          | ✅ Auto    |
| **Pull to Refresh**      | -                                           | GET /api/.../stats          | ✅ Manual  |

---

### 8️⃣ **Clean Code Principles Applied**

✅ **Single Responsibility**

- Backend: Calculation & persistence
- Repository: API communication & caching
- BLoC: State management
- Widgets: Display only

✅ **Separation of Concerns**

- Statistics logic: Backend (C#)
- Data fetching: Repository (Dart)
- State: BLoC (Dart)
- UI: Widgets (Flutter)

✅ **Consistency**

- All stats from single endpoint: `/stats`
- All updates trigger stats refresh
- Fallback to local calculation if offline

✅ **Performance**

- Stats cached in BLoC (\_lastStats)
- Only refresh when needed
- Parallel API calls where possible

---

### 9️⃣ **Which Study Modes Save Statistics?**

**ALL 3 MODES SAVE TO BACKEND! ✅**

| Mode                  | Widget          | Backend Call           | Statistics Updated                   |
| --------------------- | --------------- | ---------------------- | ------------------------------------ |
| **Çalış** (Study)     | QuizWidget      | ✅ PUT /api/.../review | ✅ ReviewCount, CorrectCount, Status |
| **Pratik** (Practice) | PracticeWidget  | ✅ PUT /api/.../review | ✅ ReviewCount, CorrectCount, Status |
| **Kart** (Flashcards) | FlashcardWidget | ✅ PUT /api/.../review | ✅ ReviewCount, CorrectCount, Status |

**Code Location:**

```dart
// vocabulary_repository_impl.dart (Line 656-661)
Future<void> completeReviewSession(ReviewSession session) async {
  for (final result in session.results) {
    await markWordReviewed(word.id, result.isCorrect); ← ALL modes call this!
  }
}
```

**Flow:**

1. User answers in ANY mode (Study/Practice/Flashcards)
2. Widget calls `onAnswerSubmitted(isCorrect, time)`
3. Study page stores result in session
4. Session complete → Loop through ALL results
5. Each result calls `markWordReviewed` → Backend updates
6. Statistics refresh automatically

**Result: All study modes contribute equally to learning statistics! 📊**

---

### 🔟 **Summary**

**How Statistics Are Determined:**

- ✅ Backend calculates from UserVocabulary table
- ✅ Real-time aggregation (GroupBy, Count)
- ✅ Accuracy = CorrectCount / ReviewCount
- ✅ Progress = (known + mastered) / total

**How Statistics Are Saved:**

- ✅ Automatic on every review (ReviewAsync)
- ✅ Immediate DB persistence
- ✅ Audit trail in UserVocabularyReview table
- ✅ Optimistic UI updates

**How Statistics Are Displayed:**

- ✅ VocabularyStatsHeader (list page)
- ✅ VocabularyWordDetailPage (per word)
- ✅ VocabularyWordCard (mini stats)
- ✅ Auto-refresh after any action

**Result: Clean, efficient, real-time statistics system! 📊**
