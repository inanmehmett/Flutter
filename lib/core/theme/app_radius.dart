/// iOS-style border radius system for Daily English app
/// Provides consistent border radius values across all components
class AppRadius {
  // Border Radius Scale (iOS Style)
  static const double radiusNone = 0.0;        // No radius
  static const double radiusSmall = 4.0;       // Small radius
  static const double radiusMedium = 8.0;      // Medium radius
  static const double radiusLarge = 12.0;      // Large radius
  static const double radiusXLarge = 16.0;     // Extra large radius
  static const double radiusXXLarge = 20.0;    // 2X large radius
  static const double radiusRound = 50.0;      // Round (for circular elements)

  // Component-specific radius
  static const double buttonRadius = radiusMedium;      // 8px
  static const double cardRadius = radiusLarge;         // 12px
  static const double inputRadius = radiusMedium;       // 8px
  static const double chipRadius = radiusRound;         // 50px
  static const double avatarRadius = radiusRound;       // 50px
  static const double modalRadius = radiusXLarge;       // 16px
  static const double bottomSheetRadius = radiusXLarge; // 16px
  static const double dialogRadius = radiusLarge;       // 12px
  static const double tabRadius = radiusMedium;         // 8px
  static const double badgeRadius = radiusRound;        // 50px

  // Legacy radius values for backward compatibility
  static const double radius4 = radiusSmall;    // 4px
  static const double radius8 = radiusMedium;   // 8px
  static const double radius12 = radiusLarge;   // 12px
  static const double radius16 = radiusXLarge;  // 16px
  static const double radius20 = radiusXXLarge; // 20px
  static const double radius50 = radiusRound;   // 50px
}
