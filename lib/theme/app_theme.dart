import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Sprout theme — warm cream/terracotta, Fraunces display + Inter body.
/// Accent-driven widget tints live next to the widgets (XP ring, CTAs, etc.)
/// and read from [tweaksProvider]; the global theme only carries shared
/// surfaces, text, and components.
class AppTheme {
  static ThemeData light() => _build();
  // No dark mode per spec (README §10 non-goal). Return the same theme so
  // existing ThemeMode plumbing doesn't crash while we remove the toggle.
  static ThemeData dark() => _build();

  static ThemeData _build() {
    const defaultAccent = AccentKind.terracotta;
    final accent = accentPalettes[defaultAccent]!;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: accent.main,
      onPrimary: SP.onAccent,
      primaryContainer: accent.soft,
      onPrimaryContainer: accent.deep,
      secondary: accent.deep,
      onSecondary: SP.onAccent,
      secondaryContainer: accent.soft,
      onSecondaryContainer: accent.deep,
      tertiary: SP.gold,
      onTertiary: SP.cocoa,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: SP.cream,
      onSurface: SP.cocoa,
      surfaceContainerLowest: SP.creamSoft,
      surfaceContainerLow: SP.creamSoft,
      surfaceContainer: SP.creamSoft,
      surfaceContainerHigh: SP.creamDeep,
      surfaceContainerHighest: SP.creamDeep,
      onSurfaceVariant: SP.cocoaSoft,
      outline: SP.muted,
      outlineVariant: SP.hairline,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: SP.cocoa,
      onInverseSurface: SP.creamSoft,
      inversePrimary: accent.glow,
    );

    final inter = GoogleFonts.interTextTheme();
    final fraunces = GoogleFonts.frauncesTextTheme();

    final textTheme = inter.copyWith(
      displayLarge: fraunces.displayLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.6,
        color: SP.cocoa,
      ),
      displayMedium: fraunces.displayMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.5,
        color: SP.cocoa,
      ),
      displaySmall: fraunces.displaySmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
        color: SP.cocoa,
      ),
      headlineLarge: fraunces.headlineLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.4,
        color: SP.cocoa,
      ),
      headlineMedium: fraunces.headlineMedium?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
        color: SP.cocoa,
      ),
      headlineSmall: fraunces.headlineSmall?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
        color: SP.cocoa,
      ),
      titleLarge: fraunces.titleLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
        color: SP.cocoa,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: SP.cocoa,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: SP.cocoa,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(color: SP.cocoa),
      bodyMedium: inter.bodyMedium?.copyWith(color: SP.cocoa),
      bodySmall: inter.bodySmall?.copyWith(color: SP.cocoaSoft),
      labelLarge: inter.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: SP.cocoa,
      ),
      labelMedium: inter.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: SP.cocoaSoft,
      ),
      labelSmall: inter.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: SP.muted,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SP.cream,
      canvasColor: SP.cream,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: SP.cream,
        foregroundColor: SP.cocoa,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: fraunces.titleLarge?.copyWith(
          color: SP.cocoa,
          fontWeight: FontWeight.w500,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: SP.creamSoft,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: SP.hairline,
        space: 1,
        thickness: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent.main,
          foregroundColor: SP.onAccent,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: inter.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent.deep),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent.deep,
          side: const BorderSide(color: SP.hairline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SP.creamSoft,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SP.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SP.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent.main, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: SP.creamSoft,
        selectedColor: accent.soft,
        labelStyle: inter.labelMedium?.copyWith(color: SP.cocoaSoft),
        side: const BorderSide(color: SP.hairline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: SP.cocoa,
        contentTextStyle: TextStyle(color: SP.creamSoft),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SP.creamSoft,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
