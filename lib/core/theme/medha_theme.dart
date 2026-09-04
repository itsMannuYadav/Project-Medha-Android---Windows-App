import 'package:flutter/material.dart';

import 'medha_colors.dart';
import 'medha_radii.dart';

/// Assembles the app's [ThemeData] from the Medha design tokens.
///
/// Hind is bundled locally (see pubspec.yaml) rather than fetched at
/// runtime, so type renders correctly offline — schools in rural Bihar
/// cannot be assumed to have a reliable connection on first launch.
class MedhaTheme {
  MedhaTheme._();

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MedhaColors.primary,
      brightness: Brightness.light,
      primary: MedhaColors.primary,
      onPrimary: Colors.white,
      secondary: MedhaColors.accent,
      onSecondary: Colors.white,
      surface: MedhaColors.surface,
      onSurface: MedhaColors.ink,
      error: MedhaColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MedhaColors.bg,
      fontFamily: 'Hind',
      splashFactory: InkRipple.splashFactory,
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: MedhaColors.surface,
        foregroundColor: MedhaColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Hind',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: MedhaColors.ink,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MedhaColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: MedhaColors.borderStrong,
          elevation: 0,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MedhaRadii.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Hind',
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MedhaColors.ink,
          side: const BorderSide(color: MedhaColors.borderStrong, width: 1.5),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MedhaRadii.md),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Hind',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MedhaColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: const TextStyle(color: MedhaColors.muted, fontFamily: 'Hind'),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MedhaRadii.md),
          borderSide: const BorderSide(color: MedhaColors.borderStrong, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MedhaRadii.md),
          borderSide: const BorderSide(color: MedhaColors.borderStrong, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MedhaRadii.md),
          borderSide: const BorderSide(color: MedhaColors.primary, width: 1.75),
        ),
      ),
      dividerTheme: const DividerThemeData(color: MedhaColors.border, thickness: 1, space: 1),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: MedhaColors.primary),
    );
  }

  static const _textTheme = TextTheme(
    headlineMedium: TextStyle(fontFamily: 'Hind', fontSize: 22, fontWeight: FontWeight.w700, color: MedhaColors.ink),
    titleLarge: TextStyle(fontFamily: 'Hind', fontSize: 18, fontWeight: FontWeight.w700, color: MedhaColors.ink),
    titleMedium: TextStyle(fontFamily: 'Hind', fontSize: 15, fontWeight: FontWeight.w600, color: MedhaColors.ink),
    bodyLarge: TextStyle(fontFamily: 'Hind', fontSize: 15, fontWeight: FontWeight.w400, color: MedhaColors.ink),
    bodyMedium: TextStyle(fontFamily: 'Hind', fontSize: 13.5, fontWeight: FontWeight.w400, color: MedhaColors.inkSoft),
    bodySmall: TextStyle(fontFamily: 'Hind', fontSize: 11.5, fontWeight: FontWeight.w400, color: MedhaColors.muted),
    labelLarge: TextStyle(fontFamily: 'Hind', fontSize: 14, fontWeight: FontWeight.w600, color: MedhaColors.ink),
  );
}
