import 'package:flutter/material.dart';

/// iOS-style typography system for Daily English app
/// Provides consistent text styles across all components and pages
class AppTypography {
  // Font Sizes (iOS Scale)
  static const double fontSizeLargeTitle = 34.0;    // Large Title (iOS)
  static const double fontSizeTitle1 = 28.0;        // Title 1 (iOS)
  static const double fontSizeTitle2 = 22.0;        // Title 2 (iOS)
  static const double fontSizeTitle3 = 20.0;        // Title 3 (iOS)
  static const double fontSizeHeadline = 17.0;      // Headline (iOS)
  static const double fontSizeBody = 17.0;          // Body (iOS)
  static const double fontSizeCallout = 16.0;       // Callout (iOS)
  static const double fontSizeSubhead = 15.0;       // Subhead (iOS)
  static const double fontSizeFootnote = 13.0;      // Footnote (iOS)
  static const double fontSizeCaption1 = 12.0;      // Caption 1 (iOS)
  static const double fontSizeCaption2 = 11.0;      // Caption 2 (iOS)

  // Font Weights (iOS Style)
  static const FontWeight weightUltraLight = FontWeight.w100;  // Ultra Light
  static const FontWeight weightThin = FontWeight.w200;        // Thin
  static const FontWeight weightLight = FontWeight.w300;       // Light
  static const FontWeight weightRegular = FontWeight.w400;     // Regular
  static const FontWeight weightMedium = FontWeight.w500;      // Medium
  static const FontWeight weightSemibold = FontWeight.w600;    // Semibold
  static const FontWeight weightBold = FontWeight.w700;        // Bold
  static const FontWeight weightHeavy = FontWeight.w800;       // Heavy
  static const FontWeight weightBlack = FontWeight.w900;       // Black

  // Line Heights (iOS Style)
  static const double lineHeightTight = 1.2;        // Tight line height
  static const double lineHeightNormal = 1.4;       // Normal line height
  static const double lineHeightRelaxed = 1.6;      // Relaxed line height
  static const double lineHeightLoose = 1.8;        // Loose line height

  // Text Styles
  static const TextStyle largeTitle = TextStyle(
    fontSize: fontSizeLargeTitle,
    fontWeight: weightBold,
    height: lineHeightTight,
    letterSpacing: -0.4,
  );

  static const TextStyle title1 = TextStyle(
    fontSize: fontSizeTitle1,
    fontWeight: weightBold,
    height: lineHeightTight,
    letterSpacing: -0.4,
  );

  static const TextStyle title2 = TextStyle(
    fontSize: fontSizeTitle2,
    fontWeight: weightBold,
    height: lineHeightTight,
    letterSpacing: -0.4,
  );

  static const TextStyle title3 = TextStyle(
    fontSize: fontSizeTitle3,
    fontWeight: weightSemibold,
    height: lineHeightNormal,
    letterSpacing: -0.2,
  );

  static const TextStyle headline = TextStyle(
    fontSize: fontSizeHeadline,
    fontWeight: weightSemibold,
    height: lineHeightNormal,
    letterSpacing: -0.2,
  );

  static const TextStyle body = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: weightRegular,
    height: lineHeightRelaxed,
    letterSpacing: -0.2,
  );

  static const TextStyle callout = TextStyle(
    fontSize: fontSizeCallout,
    fontWeight: weightRegular,
    height: lineHeightRelaxed,
    letterSpacing: -0.1,
  );

  static const TextStyle subhead = TextStyle(
    fontSize: fontSizeSubhead,
    fontWeight: weightRegular,
    height: lineHeightRelaxed,
    letterSpacing: -0.1,
  );

  static const TextStyle footnote = TextStyle(
    fontSize: fontSizeFootnote,
    fontWeight: weightRegular,
    height: lineHeightNormal,
    letterSpacing: 0.0,
  );

  static const TextStyle caption1 = TextStyle(
    fontSize: fontSizeCaption1,
    fontWeight: weightRegular,
    height: lineHeightNormal,
    letterSpacing: 0.0,
  );

  static const TextStyle caption2 = TextStyle(
    fontSize: fontSizeCaption2,
    fontWeight: weightRegular,
    height: lineHeightNormal,
    letterSpacing: 0.0,
  );

  // Alias for caption (commonly used)
  static const TextStyle caption = caption1;

  // Button Text Styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: fontSizeHeadline,
    fontWeight: weightSemibold,
    height: lineHeightTight,
    letterSpacing: -0.2,
  );

  static const TextStyle buttonMedium = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: weightMedium,
    height: lineHeightTight,
    letterSpacing: -0.1,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: fontSizeCallout,
    fontWeight: weightMedium,
    height: lineHeightTight,
    letterSpacing: 0.0,
  );

  // Navigation Text Styles
  static const TextStyle tabLabel = TextStyle(
    fontSize: fontSizeCaption1,
    fontWeight: weightMedium,
    height: lineHeightTight,
    letterSpacing: 0.0,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: fontSizeHeadline,
    fontWeight: weightSemibold,
    height: lineHeightTight,
    letterSpacing: -0.2,
  );
}
