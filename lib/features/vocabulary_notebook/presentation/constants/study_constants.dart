/// Constants for study mode functionality
/// Centralizes magic numbers and configuration values for better maintainability
class StudyConstants {
  StudyConstants._(); // Private constructor to prevent instantiation

  // ============================================================================
  // ANIMATION DURATIONS
  // ============================================================================
  
  /// Duration for card flip animation in flashcard mode
  static const Duration cardFlipDuration = Duration(milliseconds: 600);
  
  /// Duration for shake animation on wrong answer
  static const Duration shakeDuration = Duration(milliseconds: 500);
  
  /// Duration for result animation (scale-up effect)
  static const Duration resultAnimationDuration = Duration(milliseconds: 300);
  
  /// Duration for progress indicator animation
  static const Duration progressAnimationDuration = Duration(milliseconds: 300);
  
  /// Duration for card entrance animation
  static const Duration cardEntranceDuration = Duration(milliseconds: 500);
  
  // ============================================================================
  // DELAYS & TIMING
  // ============================================================================
  
  /// Delay before moving to next word after answer submission
  static const Duration resultDisplayDelay = Duration(milliseconds: 750);  // Yarıya indirildi (1500ms → 750ms)
  
  // ============================================================================
  // SPACING & SIZING
  // ============================================================================
  
  /// Standard padding for main content areas
  static const double contentPadding = 16.0;
  
  /// Large padding for spacious areas
  static const double largePadding = 24.0;
  
  /// Small padding for compact areas
  static const double smallPadding = 12.0;
  
  /// Extra small padding
  static const double xSmallPadding = 8.0;
  
  /// Border radius for cards
  static const double cardBorderRadius = 20.0;
  
  /// Border radius for buttons
  static const double buttonBorderRadius = 12.0;
  
  /// Icon size for action buttons
  static const double actionIconSize = 24.0;
  
  /// Icon size for large display icons
  static const double largeIconSize = 48.0;
  
  /// Icon size for extra large display icons
  static const double xLargeIconSize = 64.0;
  
  /// Success icon container size
  static const double successIconContainerSize = 120.0;
  
  // ============================================================================
  // TYPOGRAPHY
  // ============================================================================
  
  /// Word display font size (primary)
  static const double wordFontSize = 36.0;
  
  /// Word display font size (flashcard)
  static const double flashcardWordFontSize = 42.0;
  
  /// Meaning display font size
  static const double meaningFontSize = 32.0;
  
  /// Example sentence font size
  static const double exampleFontSize = 14.0;
  
  /// Hint text font size
  static const double hintFontSize = 12.0;
  
  /// Answer option font size
  static const double answerOptionFontSize = 16.0;
  
  /// Stat label font size
  static const double statLabelFontSize = 16.0;
  
  /// Word letter spacing
  static const double wordLetterSpacing = -1.0;
  
  /// Meaning letter spacing
  static const double meaningLetterSpacing = -0.5;
  
  // ============================================================================
  // QUIZ CONFIGURATION
  // ============================================================================
  
  /// Number of answer options in quiz mode
  static const int quizOptionCount = 4;
  
  /// Number of wrong answers to generate
  static const int wrongAnswerCount = 3;
  
  /// Minimum response time to consider (in milliseconds)
  static const int minResponseTimeMs = 100;
  
  /// Fast response threshold for bonus (in milliseconds)
  static const int fastResponseThresholdMs = 5000;
  
  // ============================================================================
  // SESSION LIMITS
  // ============================================================================
  
  /// Default words per study session
  static const int defaultWordsPerSession = 20;
  
  /// Minimum words for a valid session
  static const int minWordsPerSession = 5;
  
  /// Maximum words per session
  static const int maxWordsPerSession = 50;
  
  /// Recommended session duration in minutes
  static const int recommendedSessionDurationMin = 10;
  
  // ============================================================================
  // OPACITY VALUES
  // ============================================================================
  
  /// Standard overlay opacity
  static const double overlayOpacity = 0.1;
  
  /// Border opacity
  static const double borderOpacity = 0.2;
  
  /// Disabled element opacity
  static const double disabledOpacity = 0.3;
  
  /// Subtle text opacity
  static const double subtleTextOpacity = 0.7;
  
  /// Very subtle element opacity
  static const double verySubtleOpacity = 0.5;
  
  // ============================================================================
  // ANIMATION CURVES
  // ============================================================================
  
  /// Bounce animation value for wrong answer shake
  static const double shakeAnimationAmplitude = 10.0;
  
  /// Scale animation begin value
  static const double scaleAnimationBegin = 0.0;
  
  /// Scale animation end value
  static const double scaleAnimationEnd = 1.0;
  
  // ============================================================================
  // ACCESSIBILITY
  // ============================================================================
  
  /// Minimum tap target size (Material Design guidelines)
  static const double minTapTargetSize = 48.0;
  
  /// Minimum contrast ratio for text (WCAG AA)
  static const double minContrastRatio = 4.5;
  
  // ============================================================================
  // ERROR MESSAGES
  // ============================================================================
  
  static const String ttsErrorMessage = 'Ses çalınamadı. Lütfen ayarlarınızı kontrol edin.';
  static const String sessionLoadErrorMessage = 'Çalışma oturumu yüklenemedi.';
  static const String noWordsAvailableMessage = 'Çalışacak kelime bulunamadı.';
  static const String networkErrorMessage = 'İnternet bağlantısı kurulamadı.';
  
  // ============================================================================
  // SUCCESS MESSAGES
  // ============================================================================
  
  static const String sessionCompleteMessage = 'Tebrikler! Çalışma oturumu tamamlandı.';
  static const String correctAnswerMessage = 'Doğru!';
  static const String wrongAnswerMessage = 'Yanlış!';
  
  // ============================================================================
  // UI LABELS
  // ============================================================================
  
  static const String flipCardHintFront = 'Anlamını görmek için dokun';
  static const String flipCardHintBack = 'Kelimeyi görmek için dokun';
  static const String submitAnswerLabel = 'Cevabı Gönder';
  static const String iKnowLabel = 'Biliyorum';
  static const String iDontKnowLabel = 'Bilmiyorum';
  static const String nextWordLabel = 'Sonraki Kelime';
  static const String restartSessionLabel = 'Yeniden Başla';
  static const String exitSessionLabel = 'Çıkış';
  static const String tryAgainLabel = 'Tekrar Dene';
  static const String goBackLabel = 'Geri Dön';
  static const String startStudyLabel = 'Çalışmaya Başla';
  
  // ============================================================================
  // STAT LABELS
  // ============================================================================
  
  static const String accuracyLabel = 'Doğruluk Oranı';
  static const String completedWordsLabel = 'Tamamlanan Kelime';
  static const String durationLabel = 'Süre';
  static const String totalWordsLabel = 'Toplam Kelime';
  static const String correctAnswersLabel = 'Doğru Cevap';
  static const String wrongAnswersLabel = 'Yanlış Cevap';
}

