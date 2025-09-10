import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'theme/colors.dart';
import 'providers/settings_providers.dart';

final brightnessProvider = StateProvider<Brightness>((ref) => Brightness.light);

// Theme provider that switches between light and dark with font size scaling
final themeProvider = Provider<ThemeData>((ref) {
  final brightness = ref.watch(brightnessProvider);
  ref.watch(fontSizeProvider); // Watch for font size changes
  final fontSizeNotifier = ref.read(fontSizeProvider.notifier);
  
  // Get base theme
  final baseTheme = brightness == Brightness.light ? lightTheme : darkTheme;
  
  // Apply font size scaling to the text theme
  return baseTheme.copyWith(
    textTheme: _scaleTextTheme(baseTheme.textTheme, fontSizeNotifier.scaleFactor),
  );
});

// Helper function to scale text theme proportionally
TextTheme _scaleTextTheme(TextTheme baseTextTheme, double scaleFactor) {
  return TextTheme(
    displayLarge: baseTextTheme.displayLarge?.copyWith(
      fontSize: (baseTextTheme.displayLarge?.fontSize ?? 57) * scaleFactor,
    ),
    displayMedium: baseTextTheme.displayMedium?.copyWith(
      fontSize: (baseTextTheme.displayMedium?.fontSize ?? 45) * scaleFactor,
    ),
    displaySmall: baseTextTheme.displaySmall?.copyWith(
      fontSize: (baseTextTheme.displaySmall?.fontSize ?? 36) * scaleFactor,
    ),
    headlineLarge: baseTextTheme.headlineLarge?.copyWith(
      fontSize: (baseTextTheme.headlineLarge?.fontSize ?? 32) * scaleFactor,
    ),
    headlineMedium: baseTextTheme.headlineMedium?.copyWith(
      fontSize: (baseTextTheme.headlineMedium?.fontSize ?? 28) * scaleFactor,
    ),
    headlineSmall: baseTextTheme.headlineSmall?.copyWith(
      fontSize: (baseTextTheme.headlineSmall?.fontSize ?? 24) * scaleFactor,
    ),
    titleLarge: baseTextTheme.titleLarge?.copyWith(
      fontSize: (baseTextTheme.titleLarge?.fontSize ?? 22) * scaleFactor,
    ),
    titleMedium: baseTextTheme.titleMedium?.copyWith(
      fontSize: (baseTextTheme.titleMedium?.fontSize ?? 16) * scaleFactor,
    ),
    titleSmall: baseTextTheme.titleSmall?.copyWith(
      fontSize: (baseTextTheme.titleSmall?.fontSize ?? 14) * scaleFactor,
    ),
    bodyLarge: baseTextTheme.bodyLarge?.copyWith(
      fontSize: (baseTextTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
    ),
    bodyMedium: baseTextTheme.bodyMedium?.copyWith(
      fontSize: (baseTextTheme.bodyMedium?.fontSize ?? 14) * scaleFactor,
    ),
    bodySmall: baseTextTheme.bodySmall?.copyWith(
      fontSize: (baseTextTheme.bodySmall?.fontSize ?? 12) * scaleFactor,
    ),
    labelLarge: baseTextTheme.labelLarge?.copyWith(
      fontSize: (baseTextTheme.labelLarge?.fontSize ?? 14) * scaleFactor,
    ),
    labelMedium: baseTextTheme.labelMedium?.copyWith(
      fontSize: (baseTextTheme.labelMedium?.fontSize ?? 12) * scaleFactor,
    ),
    labelSmall: baseTextTheme.labelSmall?.copyWith(
      fontSize: (baseTextTheme.labelSmall?.fontSize ?? 11) * scaleFactor,
    ),
  );
}

// Light theme with warm, peaceful colors
final lightTheme =
    ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: AuraColors.lightScheme,
      typography: Typography.material2021(),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: const Color(0xFFFFFFFF).withValues(alpha: 0.95),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        backgroundColor: AuraColors.lightSurfaceContainerHigh,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: AuraColors.lightPrimary,
        unselectedItemColor: AuraColors.lightOutline,
      ),
    );

// Dark theme - warm and cozy
final darkTheme =
    ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: AuraColors.darkScheme,
      typography: Typography.material2021(),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: const Color(0xFF2A221C).withValues(alpha: 0.95),
      ),
      chipTheme: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        backgroundColor: AuraColors.darkSurfaceContainerHigh,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: AuraColors.darkSurface,
        selectedItemColor: AuraColors.darkPrimary,
        unselectedItemColor: AuraColors.darkOutline,
      ),
    );
