# Çalışma Modları Farklılaştırma Planı

## 🎯 Mevcut Durum (SORUN)

```dart
switch (_currentMode) {
  case StudyMode.quiz:
    return QuizWidget(...);
  case StudyMode.practice:
    return QuizWidget(..., practiceMode: true);  // ❌ Aynı widget!
  case StudyMode.flashcards:
    return FlashcardWidget(...);
  case StudyMode.review:
  default:
    return QuizWidget(...);  // ❌ Yine aynı!
}
```

**Sorunlar:**
- ❌ Review ve Quiz aynı
- ❌ Quiz ve Practice aynı (sadece bir flag farkı)
- ❌ 4 mod var ama sadece 2 farklı deneyim
- ❌ `practiceMode` flag'i kullanılmıyor bile

---

## 💡 Önerilen Farklılaştırma

### 1. **Review Mode (Günlük Tekrar)** 📚
**Amaç:** Due olan kelimeleri spaced repetition sistemine göre tekrar et

**Özellikler:**
- ✅ Sadece due olan kelimeler (`needsReview == true`)
- ✅ Çoktan seçmeli test (4 şık)
- ✅ Timer yok (rahat tempo)
- ✅ İstatistikler: accuracy, review count
- ✅ SRS algoritması ile scheduling

**UI:**
```dart
┌─────────────────────────────┐
│  🔄 Günlük Tekrar           │
│  Due: 15 kelime             │
└─────────────────────────────┘

┌─────────────────────────────┐
│        BEAUTIFUL            │
│     [🔊] Speak              │
│  "She is beautiful"         │
└─────────────────────────────┘

○ güzel          ✓
○ çirkin
○ büyük
○ küçük

[Cevabı Gönder]
```

**Backend Entegrasyon:**
- `/api/ApiUserVocabulary?due=true` endpoint
- `markWordReviewed(wordId, isCorrect)`
- SRS scheduling update

---

### 2. **Quiz Mode (Hızlı Test)** 🎯
**Amaç:** Tüm kelime dağarcığını test et, performans ölç

**Özellikler:**
- ✅ Tüm kelimeler (status filter ile)
- ✅ **TIMER VAR** (10 saniye per question)
- ✅ **SKORLAMA** (hız bonusu)
- ✅ **LEADERBOARD** integration
- ✅ Competitive mode

**UI:**
```dart
┌─────────────────────────────┐
│  🎯 Quiz Modu               │
│  Skor: 850  ⏱️ 00:07        │
└─────────────────────────────┘

┌─────────────────────────────┐
│        HAPPY                │
│     [🔊] Speak              │
│                             │
│  ⏱️ 7                        │  ← Countdown!
└─────────────────────────────┘

○ mutlu          ✓
○ üzgün
○ kızgın
○ sakin

[Hızlı Gönder] 🚀  ← Bonus: +50 XP
```

**Skorlama Sistemi:**
```dart
// Base points
correctAnswer = 100 points

// Speed bonus
if (responseTime < 5s) {
  bonus = (5 - seconds) * 20
  // 3s → +40 points
  // 2s → +60 points
  // 1s → +80 points
}

// Streak bonus
consecutiveCorrect * 10

// Total score
totalScore += basePoints + speedBonus + streakBonus
```

**Backend:**
- Quiz session tracking
- Leaderboard update
- XP calculation

---

### 3. **Practice Mode (Pratik)** 💪
**Amaç:** Zor kelimeleri yoğun çalış, öğren

**Özellikler:**
- ✅ Sadece **zor kelimeler** (`difficulty > 0.7` VEYA `consecutiveCorrectCount < 2`)
- ✅ **MULTIPLE ATTEMPTS** (2 deneme hakkı)
- ✅ **HINTS AVAILABLE** (ilk harf, synonym gösterme)
- ✅ **TYPING MODE** (yazarak öğren)
- ✅ Detailed feedback

**UI:**
```dart
┌─────────────────────────────┐
│  💪 Pratik Modu             │
│  Zor Kelimeler: 8           │
│  Kalan Hak: 2/2  💡 1 ipucu │
└─────────────────────────────┘

┌─────────────────────────────┐
│     THROUGH                 │
│     [🔊] Speak              │
│  "Walk through the door"    │
│                             │
│  💡 İpucu: İlk harf 'i'     │  ← Hint!
└─────────────────────────────┘

┌─────────────────────────────┐
│  Türkçe karşılığını yazın:  │
│  [________________]         │  ← Typing!
└─────────────────────────────┘

[Kontrol Et] (2 deneme hakkı kaldı)
```

**Hint System:**
```dart
// Hint 1: İlk harf
'Başlangıç: i...'

// Hint 2: Synonym
'Eş anlamlısı: "için"'

// Hint 3: Example without word
'"Walk _____ the door"'
```

**Multiple Attempts:**
```dart
attempt1: Wrong → Show hint 1
attempt2: Wrong → Show hint 2, mark as difficult
attempt2: Correct → Mark as learning (not mastered yet)
```

---

### 4. **Flashcard Mode (Kart)** 🎴
**Amaç:** Passive learning, kelime-anlam eşleştirme

**Özellikler:**
- ✅ Self-assessment (kendin değerlendir)
- ✅ Flip animation
- ✅ Swipe gestures (biliyorum/bilmiyorum)
- ✅ Batch review (10-20 kelime)

**UI:**
```dart
┌─────────────────────────────┐
│  🎴 Flashcard Modu          │
│  15 / 20                    │
└─────────────────────────────┘

  [Flip animation]
  
┌─────────────────────────────┐
│                             │
│        BEAUTIFUL            │
│      [🔊] Speak             │
│                             │
│   Tap to see meaning 👆     │
└─────────────────────────────┘

  [Swipe left: Bilmiyorum]
  [Swipe right: Biliyorum]

OR

[❌ Bilmiyorum]  [✅ Biliyorum]
```

**Swipe Gestures:**
```dart
// Swipe left → Don't know
// Swipe right → Know
// Tap → Flip
// Long press → Speak
```

---

## 🎯 Farklılaştırma Özeti

| Mod | Kelimeler | Format | Timer | Attempts | Hints | Amaç |
|-----|-----------|--------|-------|----------|-------|------|
| **Review** | Due words | Multiple choice | ❌ No | 1 | ❌ No | SRS tekrar |
| **Quiz** | All words | Multiple choice | ✅ Yes | 1 | ❌ No | Hız + skor |
| **Practice** | Difficult | Typing | ❌ No | 2 | ✅ Yes | Öğrenme |
| **Flashcard** | Batch | Self-assess | ❌ No | ∞ | ❌ No | Pasif öğrenme |

---

## 🔧 Implementasyon

### 1. Review Mode (Mevcut)
```dart
case StudyMode.review:
  return QuizWidget(
    word: word,
    onAnswerSubmitted: _onAnswerSubmitted,
    showTimer: false,        // ✓
    allowMultipleAttempts: false,  // ✓
    showHints: false,        // ✓
  );
```

### 2. Quiz Mode (YENİ)
```dart
case StudyMode.quiz:
  return QuizWidget(
    word: word,
    onAnswerSubmitted: _onAnswerSubmitted,
    showTimer: true,         // ✓ 10s countdown
    timerDuration: const Duration(seconds: 10),
    onTimeout: _handleTimeout,
    calculateScore: true,    // ✓ Speed bonus
    onScoreUpdate: _updateScore,
  );
```

### 3. Practice Mode (YENİ)
```dart
case StudyMode.practice:
  return PracticeWidget(  // ✓ Yeni widget!
    word: word,
    onAnswerSubmitted: _onAnswerSubmitted,
    allowMultipleAttempts: true,  // ✓ 2 attempts
    maxAttempts: 2,
    showHints: true,         // ✓ Progressive hints
    inputMode: InputMode.typing,  // ✓ Keyboard input
  );
```

### 4. Flashcard Mode (Mevcut - İyileştirilmiş)
```dart
case StudyMode.flashcards:
  return FlashcardWidget(
    word: word,
    onAnswerSubmitted: _onAnswerSubmitted,
    enableSwipeGestures: true,  // ✓ NEW!
    onSwipeLeft: () => _onAnswerSubmitted(false, ...),
    onSwipeRight: () => _onAnswerSubmitted(true, ...),
  );
```

---

## 🎨 UI Mockups

### Review Mode:
```
┌──────────────────────────┐
│ 🔄 Günlük Tekrar         │  ← Mavi gradient
│ 5 / 15 kelime            │
│ ████████░░░░░░░░  53%    │  ← Linear progress
└──────────────────────────┘

        BEAUTIFUL
      [🔊] Speak button
   "She is beautiful"

  ○  güzel          ← 4 options
  ○  çirkin
  ○  büyük  
  ○  küçük

    [Cevabı Gönder]
```

### Quiz Mode:
```
┌──────────────────────────┐
│ 🎯 Quiz                  │  ← Turuncu gradient
│ Skor: 850    ⏱️ 00:07    │  ← Score + Timer
│ ████████████░░░░  75%    │
└──────────────────────────┘

┌──────────────────────────┐
│      HAPPY       ⏱️ 7    │  ← Countdown
│    [🔊] Speak            │
│                          │
│   🔥 Streak: 3           │  ← Streak indicator
└──────────────────────────┘

  ○  mutlu  ✓
  ○  üzgün
  ○  kızgın
  ○  sakin

  [Hızlı Gönder] 🚀
   +50 Speed Bonus!
```

### Practice Mode:
```
┌──────────────────────────┐
│ 💪 Pratik Modu           │  ← Yeşil gradient
│ Zor Kelimeler: 3 / 8     │
│ Hak: 2/2   💡 İpucu: 1   │
└──────────────────────────┘

┌──────────────────────────┐
│     THROUGH              │
│   [🔊] Speak             │
│ "Walk through the door"  │
│                          │
│ 💡 İlk harf: 'i'         │  ← Hint shown!
└──────────────────────────┘

┌──────────────────────────┐
│ Türkçe karşılığını yazın:│
│ ┌──────────────────────┐ │
│ │ içinden__            │ │  ← Typing input
│ └──────────────────────┘ │
└──────────────────────────┘

[Kontrol Et] [💡 İpucu İste]
  2 deneme hakkı kaldı
```

### Flashcard Mode:
```
┌──────────────────────────┐
│ 🎴 Flashcard             │  ← Mor gradient
│ 12 / 20 kart             │
│ ████████████░░░░  60%    │
└──────────────────────────┘

        [CARD FLIP]
        
┌──────────────────────────┐
│                          │
│      BEAUTIFUL           │  ← Front
│    [🔊] Speak            │
│                          │
│  Tap to see meaning 👆   │
└──────────────────────────┘

        [FLIP TO]
        
┌──────────────────────────┐
│                          │
│        güzel             │  ← Back
│  "She is beautiful"      │
│                          │
│  Tap to flip back 👆     │
└──────────────────────────┘

 ← Swipe left     Swipe right →
   Bilmiyorum        Biliyorum
```

---

## 🎮 Kullanıcı Akışları

### Review Mode Flow:
```
1. User opens Review → Loads due words
2. Shows word → User selects answer
3. Submits → SRS updates (nextReviewAt)
4. Next word → Repeat
5. Complete → Shows accuracy stats
```

### Quiz Mode Flow:
```
1. User opens Quiz → Loads all words (randomized)
2. Shows word + TIMER starts (10s)
3. User selects FAST → Speed bonus calculated
4. Next word → Score updates + Streak counter
5. Timeout? → Auto-skip, no points
6. Complete → Shows SCORE + RANK
7. Option: Share to leaderboard
```

### Practice Mode Flow:
```
1. User opens Practice → Loads difficult words
2. Shows word → User TYPES answer
3. Submit attempt 1:
   - Correct? → Next word
   - Wrong? → Show Hint 1, try again
4. Submit attempt 2:
   - Correct? → Mark as "learning", next word
   - Wrong? → Show correct answer + explanation
5. Complete → Shows improvement stats
```

### Flashcard Mode Flow:
```
1. User opens Flashcard → Loads word batch
2. Shows front (word) → User taps to flip
3. Shows back (meaning + example)
4. User swipes or taps button:
   - Right/✅ → "Know it"
   - Left/❌ → "Don't know"
5. Next card → Repeat
6. Complete → Shows know/don't-know ratio
```

---

## 🏗️ Yeni Widget Yapısı

```
presentation/
  widgets/
    quiz/
      ├── quiz_widget.dart              ← Multiple choice
      ├── quiz_timer.dart               ← NEW! Countdown
      ├── quiz_score_badge.dart         ← NEW! Score display
      └── quiz_streak_indicator.dart    ← NEW! Streak counter
    
    practice/
      ├── practice_widget.dart          ← NEW! Typing mode
      ├── practice_input_field.dart     ← NEW! Custom input
      ├── practice_hint_card.dart       ← NEW! Hint display
      └── practice_attempts_indicator.dart  ← NEW! 2/2 hearts
    
    flashcard/
      ├── flashcard_widget.dart         ← Self-assessment
      ├── flashcard_swipe_detector.dart ← NEW! Swipe handling
      └── flashcard_flip_animation.dart ← NEW! 3D flip
    
    shared/
      ├── word_display_card.dart        ← Reusable
      ├── speak_button.dart             ← Reusable
      └── example_sentence_pill.dart    ← Reusable
```

---

## 📝 Code Examples

### Quiz Mode - Timer & Score

```dart
class QuizWidget extends StatefulWidget {
  final bool showTimer;
  final Duration? timerDuration;
  final Function(int score)? onScoreUpdate;
  
  // ...
}

class _QuizWidgetState extends State<QuizWidget> {
  Timer? _timer;
  int _remainingSeconds = 10;
  int _currentScore = 0;
  int _consecutiveCorrect = 0;
  
  @override
  void initState() {
    super.initState();
    if (widget.showTimer) {
      _startTimer();
    }
  }
  
  void _startTimer() {
    _remainingSeconds = widget.timerDuration?.inSeconds ?? 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _handleTimeout();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }
  
  void _submitAnswer() {
    if (widget.showTimer) {
      _timer?.cancel();
      
      // Calculate score
      final basePoints = 100;
      final speedBonus = _remainingSeconds * 10;  // 10 points per second left
      final streakBonus = _consecutiveCorrect * 10;
      final totalPoints = basePoints + speedBonus + streakBonus;
      
      _currentScore += totalPoints;
      widget.onScoreUpdate?.call(_currentScore);
      
      if (isCorrect) {
        _consecutiveCorrect++;
      } else {
        _consecutiveCorrect = 0;
      }
    }
  }
  
  Widget _buildTimerDisplay() {
    final color = _remainingSeconds <= 3 ? Colors.red : Colors.blue;
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row([
        Icon(Icons.timer, color: color, size: 16),
        SizedBox(width: 4),
        Text('$_remainingSeconds', style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color,
        )),
      ]),
    );
  }
}
```

### Practice Mode - Typing & Hints

```dart
class PracticeWidget extends StatefulWidget {
  final VocabularyWord word;
  final int maxAttempts;
  final bool showHints;
  
  // ...
}

class _PracticeWidgetState extends State<PracticeWidget> {
  final TextEditingController _controller = TextEditingController();
  int _currentAttempt = 0;
  String? _currentHint;
  
  void _submitAnswer() {
    final userAnswer = _controller.text.trim().toLowerCase();
    final correctAnswer = widget.word.meaning.toLowerCase();
    
    final isCorrect = userAnswer == correctAnswer;
    
    if (isCorrect) {
      // Success!
      widget.onAnswerSubmitted(true, responseTime);
    } else {
      _currentAttempt++;
      
      if (_currentAttempt < widget.maxAttempts) {
        // Show hint and allow retry
        _showHint(_currentAttempt);
        _showRetryMessage();
      } else {
        // Failed after max attempts
        _showCorrectAnswer();
        widget.onAnswerSubmitted(false, responseTime);
      }
    }
  }
  
  void _showHint(int attemptNumber) {
    setState(() {
      _currentHint = switch (attemptNumber) {
        1 => 'İlk harf: ${widget.word.meaning[0]}',
        2 => widget.word.synonyms.isNotEmpty 
            ? 'Eş anlamlısı: ${widget.word.synonyms.first}'
            : 'Uzunluk: ${widget.word.meaning.length} harf',
        _ => null,
      };
    });
  }
  
  Widget _buildTypingInput() {
    return TextField(
      controller: _controller,
      autofocus: true,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Türkçe karşılığını yazın',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        filled: true,
      ),
      onSubmitted: (_) => _submitAnswer(),
    );
  }
  
  Widget _buildHintCard() {
    if (_currentHint == null) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber),
      ),
      child: Row([
        Icon(Icons.lightbulb, color: Colors.amber),
        SizedBox(width: 8),
        Text(_currentHint!, style: TextStyle(
          color: Colors.amber.shade700,
          fontWeight: FontWeight.w600,
        )),
      ]),
    );
  }
  
  Widget _buildAttemptsIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.maxAttempts, (index) {
        final isUsed = index < _currentAttempt;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            isUsed ? Icons.favorite : Icons.favorite_border,
            color: isUsed ? Colors.grey : Colors.red,
            size: 20,
          ),
        );
      }),
    );
  }
}
```

### Flashcard Mode - Swipe Gestures

```dart
class FlashcardWidget extends StatefulWidget {
  final bool enableSwipeGestures;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  
  // ...
}

class _FlashcardWidgetState extends State<FlashcardWidget> {
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!widget.enableSwipeGestures) return;
    
    final velocity = details.primaryVelocity ?? 0;
    
    if (velocity < -500) {
      // Swipe left → Don't know
      _submitAnswer(false);
      widget.onSwipeLeft?.call();
    } else if (velocity > 500) {
      // Swipe right → Know
      _submitAnswer(true);
      widget.onSwipeRight?.call();
    }
  }
  
  Widget _buildFlashcard(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: // ... card content
    );
  }
  
  Widget _buildSwipeHint() {
    return Row([
      Icon(Icons.swipe_left, color: Colors.red.withOpacity(0.5)),
      Spacer(),
      Text('Kaydırın', style: subtitle),
      Spacer(),
      Icon(Icons.swipe_right, color: Colors.green.withOpacity(0.5)),
    ]);
  }
}
```

---

## 🎯 Önerilen Uygulama Sırası

### Phase 1: Critical (Şimdi)
1. ✅ **Quiz Mode Timer** ekle
   - Countdown widget
   - Timeout handling
   - Score calculation

2. ✅ **Practice Widget** oluştur
   - Typing input
   - Hint system
   - Multiple attempts

3. ✅ **Flashcard Swipe** ekle
   - Gesture detector
   - Swipe animations
   - Visual feedback

### Phase 2: Enhancement (Sonra)
4. ⬜ **Leaderboard** integration
5. ⬜ **XP System** integration
6. ⬜ **Achievement** unlocks
7. ⬜ **Statistics** dashboard

---

## 💾 Backend Requirements

### Quiz Mode:
```csharp
// New endpoint
POST /api/ApiUserVocabulary/quiz/session/start
POST /api/ApiUserVocabulary/quiz/session/{id}/complete
{
  "score": 1250,
  "accuracy": 0.85,
  "avgResponseTime": 4500,
  "streak": 5
}

// Leaderboard
GET /api/ApiUserVocabulary/quiz/leaderboard?period=daily
```

### Practice Mode:
```csharp
// Track difficult words
GET /api/ApiUserVocabulary?difficulty=high&limit=20

// Update difficulty
POST /api/ApiUserVocabulary/{id}/practice
{
  "attempts": 2,
  "usedHints": 1,
  "isCorrect": true
}
```

---

## 📊 Expected Impact

| Metrik | Before | After | Improvement |
|--------|--------|-------|-------------|
| Mode variety | 2 real | 4 unique | ✅ +100% |
| User engagement | 6/10 | 9/10 | ✅ +50% |
| Learning effectiveness | 7/10 | 9/10 | ✅ +28% |
| Gamification | Low | High | ✅ +100% |
| Competitive features | None | Yes | ✅ NEW |
| Practice tools | None | Yes | ✅ NEW |

---

## ✅ Sonuç

**Durum:** 📋 **Plan Hazır**

**Önerilen Yaklaşım:**
1. Quiz Mode → Timer + Score
2. Practice Mode → Typing + Hints
3. Flashcard Mode → Swipe gestures
4. Review Mode → Keep as is (SRS)

**Tahmini Süre:** 1-2 gün
**Öncelik:** Orta-Yüksek
**ROI:** Yüksek (user engagement +50%)

---

**Son Güncelleme:** 2025-11-01
**Durum:** 📋 Planlama Tamamlandı
**Sonraki Adım:** Phase 1 implementasyon

