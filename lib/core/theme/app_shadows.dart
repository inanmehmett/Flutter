import 'package:flutter/material.dart';

/// iOS-style shadow system for Daily English app
/// Provides consistent shadow elevations across all components
class AppShadows {
  // Shadow System (iOS Style)
  static const List<BoxShadow> shadowNone = []; // No shadow

  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x0A000000), // 4% opacity
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x0F000000), // 6% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x14000000), // 8% opacity
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowXLarge = [
    BoxShadow(
      color: Color(0x19000000), // 10% opacity
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  // Component-specific shadows
  static const List<BoxShadow> cardShadow = shadowSmall;
  static const List<BoxShadow> cardShadowElevated = shadowMedium;
  static const List<BoxShadow> buttonShadow = shadowSmall;
  static const List<BoxShadow> appBarShadow = shadowSmall;
  static const List<BoxShadow> modalShadow = shadowLarge;
  static const List<BoxShadow> floatingActionShadow = shadowMedium;

  // Dark mode shadows
  static const List<BoxShadow> shadowSmallDark = [
    BoxShadow(
      color: Color(0x1A000000), // 10% opacity
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMediumDark = [
    BoxShadow(
      color: Color(0x26000000), // 15% opacity
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLargeDark = [
    BoxShadow(
      color: Color(0x33000000), // 20% opacity
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> shadowXLargeDark = [
    BoxShadow(
      color: Color(0x40000000), // 25% opacity
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
