import 'package:flutter/material.dart';

/// Centralized color scheme for Aura One app
/// Provides warm, peaceful colors for a calming user experience
class AuraColors {
  AuraColors._();

  // Light theme colors - warm and peaceful
  static const Color lightPrimary = Color(0xFFE8A87C);
  static const Color lightOnPrimary = Color(0xFFFFFFFF);
  static const Color lightPrimaryContainer = Color(0xFFFFF0E5);
  static const Color lightOnPrimaryContainer = Color(0xFF5D4037);
  
  static const Color lightSecondary = Color(0xFFF4C2A1);
  static const Color lightOnSecondary = Color(0xFFFFFFFF);
  static const Color lightSecondaryContainer = Color(0xFFFFF5F0);
  static const Color lightOnSecondaryContainer = Color(0xFF6D4C41);
  
  static const Color lightTertiary = Color(0xFFD4A574);
  static const Color lightOnTertiary = Color(0xFFFFFFFF);
  static const Color lightTertiaryContainer = Color(0xFFFFF8F3);
  static const Color lightOnTertiaryContainer = Color(0xFF5D4E37);
  
  static const Color lightError = Color(0xFFE57373);
  static const Color lightOnError = Color(0xFFFFFFFF);
  static const Color lightErrorContainer = Color(0xFFFFEBEE);
  static const Color lightOnErrorContainer = Color(0xFF7F0000);
  
  static const Color lightSurface = Color(0xFFFFFBF7);
  static const Color lightOnSurface = Color(0xFF4A3C28);
  static const Color lightSurfaceContainerHighest = Color(0xFFFFF8F3);
  static const Color lightSurfaceContainerHigh = Color(0xFFFFF5ED);
  static const Color lightSurfaceContainer = Color(0xFFFFF2E7);
  static const Color lightSurfaceContainerLow = Color(0xFFFFEFE0);
  static const Color lightSurfaceContainerLowest = Color(0xFFFFECDA);
  
  static const Color lightInverseSurface = Color(0xFF3E2E1F);
  static const Color lightOnInverseSurface = Color(0xFFFFF8F3);
  static const Color lightInversePrimary = Color(0xFFFFDCC5);
  
  static const Color lightOutline = Color(0xFFBCAA97);
  static const Color lightOutlineVariant = Color(0xFFE0D5C7);
  static const Color lightShadow = Color(0xFF000000);
  static const Color lightScrim = Color(0xFF000000);
  static const Color lightSurfaceTint = Color(0xFFE8A87C);

  // Dark theme colors - warm and cozy
  static const Color darkPrimary = Color(0xFFFFB74D);
  static const Color darkOnPrimary = Color(0xFF4E2E00);
  static const Color darkPrimaryContainer = Color(0xFF6D3F00);
  static const Color darkOnPrimaryContainer = Color(0xFFFFDDB3);
  
  static const Color darkSecondary = Color(0xFFFFAB91);
  static const Color darkOnSecondary = Color(0xFF5D2E1F);
  static const Color darkSecondaryContainer = Color(0xFF7A3F2E);
  static const Color darkOnSecondaryContainer = Color(0xFFFFDAD0);
  
  static const Color darkTertiary = Color(0xFFFFD54F);
  static const Color darkOnTertiary = Color(0xFF4A3C00);
  static const Color darkTertiaryContainer = Color(0xFF695300);
  static const Color darkOnTertiaryContainer = Color(0xFFFFE8B3);
  
  static const Color darkError = Color(0xFFEF9A9A);
  static const Color darkOnError = Color(0xFF690000);
  static const Color darkErrorContainer = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);
  
  static const Color darkSurface = Color(0xFF1A1410);
  static const Color darkOnSurface = Color(0xFFF0E6DC);
  static const Color darkSurfaceContainerHighest = Color(0xFF3A322B);
  static const Color darkSurfaceContainerHigh = Color(0xFF322A24);
  static const Color darkSurfaceContainer = Color(0xFF2A221C);
  static const Color darkSurfaceContainerLow = Color(0xFF221A15);
  static const Color darkSurfaceContainerLowest = Color(0xFF15100C);
  
  static const Color darkInverseSurface = Color(0xFFF0E6DC);
  static const Color darkOnInverseSurface = Color(0xFF352F2A);
  static const Color darkInversePrimary = Color(0xFF8B5000);
  
  static const Color darkOutline = Color(0xFF9C8F80);
  static const Color darkOutlineVariant = Color(0xFF4F453A);
  static const Color darkShadow = Color(0xFF000000);
  static const Color darkScrim = Color(0xFF000000);
  static const Color darkSurfaceTint = Color(0xFFFFB74D);

  // Gradient colors for UI elements
  static const List<Color> lightBackgroundGradient = [
    Color(0xFFFFFBF7), // Warm cream
    Color(0xFFFFF8F3), // Light peach
    Color(0xFFFFF0E5), // Soft coral tint
  ];

  static const List<Color> darkBackgroundGradient = [
    Color(0xFF1A1410), // Dark warm
    Color(0xFF221A15), // Deeper warm
    Color(0xFF2A221C), // Rich brown
  ];

  static const List<Color> lightLogoGradient = [
    Color(0xFFE8A87C), // Warm peach
    Color(0xFFF4C2A1), // Soft rose
    Color(0xFFD4A574), // Terracotta
  ];

  static const List<Color> darkLogoGradient = [
    Color(0xFFFFB74D), // Warm amber
    Color(0xFFFFAB91), // Soft coral
    Color(0xFFFFD54F), // Warm gold
  ];

  static const List<Color> lightCardGradient = [
    Color(0xFFFFFFFF), // Pure white
    Color(0xFFFFF8F3), // Warm cream
  ];

  static const List<Color> darkCardGradient = [
    Color(0xFF2A221C), // Warm dark
    Color(0xFF322A24), // Deeper warm
  ];

  // Light theme ColorScheme
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: lightPrimary,
    onPrimary: lightOnPrimary,
    primaryContainer: lightPrimaryContainer,
    onPrimaryContainer: lightOnPrimaryContainer,
    secondary: lightSecondary,
    onSecondary: lightOnSecondary,
    secondaryContainer: lightSecondaryContainer,
    onSecondaryContainer: lightOnSecondaryContainer,
    tertiary: lightTertiary,
    onTertiary: lightOnTertiary,
    tertiaryContainer: lightTertiaryContainer,
    onTertiaryContainer: lightOnTertiaryContainer,
    error: lightError,
    onError: lightOnError,
    errorContainer: lightErrorContainer,
    onErrorContainer: lightOnErrorContainer,
    surface: lightSurface,
    onSurface: lightOnSurface,
    surfaceContainerHighest: lightSurfaceContainerHighest,
    surfaceContainerHigh: lightSurfaceContainerHigh,
    surfaceContainer: lightSurfaceContainer,
    surfaceContainerLow: lightSurfaceContainerLow,
    surfaceContainerLowest: lightSurfaceContainerLowest,
    inverseSurface: lightInverseSurface,
    onInverseSurface: lightOnInverseSurface,
    inversePrimary: lightInversePrimary,
    outline: lightOutline,
    outlineVariant: lightOutlineVariant,
    shadow: lightShadow,
    scrim: lightScrim,
    surfaceTint: lightSurfaceTint,
  );

  // Dark theme ColorScheme
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: darkPrimary,
    onPrimary: darkOnPrimary,
    primaryContainer: darkPrimaryContainer,
    onPrimaryContainer: darkOnPrimaryContainer,
    secondary: darkSecondary,
    onSecondary: darkOnSecondary,
    secondaryContainer: darkSecondaryContainer,
    onSecondaryContainer: darkOnSecondaryContainer,
    tertiary: darkTertiary,
    onTertiary: darkOnTertiary,
    tertiaryContainer: darkTertiaryContainer,
    onTertiaryContainer: darkOnTertiaryContainer,
    error: darkError,
    onError: darkOnError,
    errorContainer: darkErrorContainer,
    onErrorContainer: darkOnErrorContainer,
    surface: darkSurface,
    onSurface: darkOnSurface,
    surfaceContainerHighest: darkSurfaceContainerHighest,
    surfaceContainerHigh: darkSurfaceContainerHigh,
    surfaceContainer: darkSurfaceContainer,
    surfaceContainerLow: darkSurfaceContainerLow,
    surfaceContainerLowest: darkSurfaceContainerLowest,
    inverseSurface: darkInverseSurface,
    onInverseSurface: darkOnInverseSurface,
    inversePrimary: darkInversePrimary,
    outline: darkOutline,
    outlineVariant: darkOutlineVariant,
    shadow: darkShadow,
    scrim: darkScrim,
    surfaceTint: darkSurfaceTint,
  );
}