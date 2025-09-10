import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_shadows.dart';
import 'app_radius.dart';

/// Main design system class for Daily English app
/// Provides centralized access to all design tokens and utilities
class AppDesignSystem {
  // Color System
  static AppColors get colors => AppColors();
  
  // Typography System
  static AppTypography get typography => AppTypography();
  
  // Spacing System
  static AppSpacing get spacing => AppSpacing();
  
  // Shadow System
  static AppShadows get shadows => AppShadows();
  
  // Radius System
  static AppRadius get radius => AppRadius();

  /// Get color scheme for light mode
  static ColorScheme get lightColorScheme => const ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.primaryDark,
    
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.secondaryContainer,
    onSecondaryContainer: AppColors.secondaryDark,
    
    tertiary: AppColors.accent,
    onTertiary: AppColors.white,
    tertiaryContainer: AppColors.accentContainer,
    onTertiaryContainer: AppColors.accentDark,
    
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorContainer,
    onErrorContainer: AppColors.errorDark,
    
    background: AppColors.background,
    onBackground: AppColors.textPrimary,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceVariant: AppColors.surfaceSecondary,
    onSurfaceVariant: AppColors.textSecondary,
    
    outline: AppColors.border,
    outlineVariant: AppColors.borderLight,
    shadow: AppColors.black,
    scrim: AppColors.black,
    inverseSurface: AppColors.surfaceDark,
    onInverseSurface: AppColors.textPrimaryDark,
    inversePrimary: AppColors.primaryLight,
  );

  /// Get color scheme for dark mode
  static ColorScheme get darkColorScheme => const ColorScheme.dark(
    primary: AppColors.primaryLight,
    onPrimary: AppColors.black,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.primaryLight,
    
    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.black,
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.secondaryLight,
    
    tertiary: AppColors.accentLight,
    onTertiary: AppColors.black,
    tertiaryContainer: AppColors.accentDark,
    onTertiaryContainer: AppColors.accentLight,
    
    error: AppColors.errorLight,
    onError: AppColors.black,
    errorContainer: AppColors.errorDark,
    onErrorContainer: AppColors.errorLight,
    
    background: AppColors.backgroundDark,
    onBackground: AppColors.textPrimaryDark,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    surfaceVariant: AppColors.surfaceDark,
    onSurfaceVariant: AppColors.textSecondaryDark,
    
    outline: AppColors.separatorDark,
    outlineVariant: AppColors.separatorDark,
    shadow: AppColors.black,
    scrim: AppColors.black,
    inverseSurface: AppColors.surface,
    onInverseSurface: AppColors.textPrimary,
    inversePrimary: AppColors.primary,
  );

  /// Get theme data for light mode
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: lightColorScheme,
    fontFamily: 'SF Pro Display',
    
    // App Bar Theme
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: AppTypography.appBarTitle,
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardRadius),
      ),
      color: AppColors.surface,
      shadowColor: AppColors.black,
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingM,
          vertical: AppSpacing.paddingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
        ),
        textStyle: AppTypography.buttonMedium,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingM,
          vertical: AppSpacing.paddingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
        ),
        textStyle: AppTypography.buttonMedium,
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingM,
          vertical: AppSpacing.paddingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
        ),
        textStyle: AppTypography.buttonMedium,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.inputRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.inputRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.inputRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.inputRadius),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.inputRadius),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingM,
        vertical: AppSpacing.paddingS,
      ),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: AppTypography.tabLabel,
      unselectedLabelStyle: AppTypography.tabLabel,
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      displayLarge: AppTypography.largeTitle,
      displayMedium: AppTypography.title1,
      displaySmall: AppTypography.title2,
      headlineLarge: AppTypography.title3,
      headlineMedium: AppTypography.headline,
      headlineSmall: AppTypography.headline,
      titleLarge: AppTypography.title3,
      titleMedium: AppTypography.title3,
      titleSmall: AppTypography.subhead,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.footnote,
      labelLarge: AppTypography.callout,
      labelMedium: AppTypography.footnote,
      labelSmall: AppTypography.caption1,
    ),
  );

  /// Get theme data for dark mode
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    fontFamily: 'SF Pro Display',
    
    // App Bar Theme
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: AppColors.textPrimaryDark,
      titleTextStyle: AppTypography.appBarTitle,
    ),
    
    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cardRadius),
      ),
      color: AppColors.surfaceDark,
      shadowColor: AppColors.black,
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingM,
          vertical: AppSpacing.paddingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
        ),
        textStyle: AppTypography.buttonMedium,
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingM,
          vertical: AppSpacing.paddingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
        ),
        textStyle: AppTypography.buttonMedium,
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.paddingM,
          vertical: AppSpacing.paddingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.buttonRadius),
        ),
        textStyle: AppTypography.buttonMedium,
      ),
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.inputRadius),
        borderSide: const BorderSide(color: AppColors.separatorDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.inputRadius),
        borderSide: const BorderSide(color: AppColors.separatorDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.inputRadius),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.inputRadius),
        borderSide: const BorderSide(color: AppColors.errorLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.inputRadius),
        borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.paddingM,
        vertical: AppSpacing.paddingS,
      ),
    ),
    
    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textSecondaryDark,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: AppTypography.tabLabel,
      unselectedLabelStyle: AppTypography.tabLabel,
    ),
    
    // Text Theme
    textTheme: const TextTheme(
      displayLarge: AppTypography.largeTitle,
      displayMedium: AppTypography.title1,
      displaySmall: AppTypography.title2,
      headlineLarge: AppTypography.title3,
      headlineMedium: AppTypography.headline,
      headlineSmall: AppTypography.headline,
      titleLarge: AppTypography.title3,
      titleMedium: AppTypography.title3,
      titleSmall: AppTypography.subhead,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.footnote,
      labelLarge: AppTypography.callout,
      labelMedium: AppTypography.footnote,
      labelSmall: AppTypography.caption1,
    ),
  );
}
