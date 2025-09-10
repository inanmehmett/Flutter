/// iOS-style spacing system for Daily English app
/// Provides consistent spacing using 8pt grid system
class AppSpacing {
  // Spacing Scale (8pt grid system)
  static const double spacing0 = 0.0;      // 0x
  static const double spacing1 = 4.0;      // 0.5x
  static const double spacing2 = 8.0;      // 1x
  static const double spacing3 = 12.0;     // 1.5x
  static const double spacing4 = 16.0;     // 2x
  static const double spacing5 = 20.0;     // 2.5x
  static const double spacing6 = 24.0;     // 3x
  static const double spacing8 = 32.0;     // 4x
  static const double spacing10 = 40.0;    // 5x
  static const double spacing12 = 48.0;    // 6x
  static const double spacing16 = 64.0;    // 8x
  static const double spacing20 = 80.0;    // 10x
  static const double spacing24 = 96.0;    // 12x

  // Semantic Spacing
  static const double paddingXS = spacing1;      // 4px
  static const double paddingS = spacing2;       // 8px
  static const double paddingM = spacing4;       // 16px
  static const double paddingL = spacing6;       // 24px
  static const double paddingXL = spacing8;      // 32px
  static const double paddingXXL = spacing12;    // 48px

  static const double marginXS = spacing1;       // 4px
  static const double marginS = spacing2;        // 8px
  static const double marginM = spacing4;        // 16px
  static const double marginL = spacing6;        // 24px
  static const double marginXL = spacing8;       // 32px
  static const double marginXXL = spacing12;     // 48px

  // Component Spacing
  static const double cardPadding = paddingM;           // 16px
  static const double cardMargin = marginM;             // 16px
  static const double buttonPadding = paddingM;         // 16px
  static const double inputPadding = paddingM;          // 16px
  static const double sectionSpacing = spacing8;        // 32px
  static const double itemSpacing = spacing3;           // 12px
  static const double listSpacing = spacing2;           // 8px

  // Layout Spacing
  static const double screenPadding = paddingM;         // 16px
  static const double contentPadding = paddingL;        // 24px
  static const double headerPadding = paddingXL;        // 32px
  static const double footerPadding = paddingXL;        // 32px

  // Border Spacing
  static const double borderWidth = 1.0;
  static const double borderWidthThick = 2.0;
  static const double dividerHeight = 1.0;
  static const double separatorHeight = 0.5;
}
