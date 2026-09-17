import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static TextTheme get _textTheme {
    final manrope = GoogleFonts.manropeTextTheme();
    return manrope;
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.terracotta,
        onPrimary: AppColors.ivory,
        primaryContainer: AppColors.parchment,
        onPrimaryContainer: AppColors.ink,
        secondary: AppColors.gold,
        onSecondary: AppColors.ivory,
        secondaryContainer: AppColors.accent,
        onSecondaryContainer: AppColors.ink,
        tertiary: AppColors.sage,
        onTertiary: AppColors.ivory,
        error: AppColors.destructive,
        onError: AppColors.ivory,
        surface: AppColors.card,
        onSurface: AppColors.ink,
        surfaceContainerHighest: AppColors.parchment,
        outline: AppColors.hairline,
        outlineVariant: AppColors.hairline,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardColor: AppColors.card,
      dividerColor: AppColors.hairline,
      textTheme: _textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.sidebar,
        foregroundColor: AppColors.ink,
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.sidebar,
        selectedIconTheme: const IconThemeData(color: AppColors.terracotta),
        unselectedIconTheme:
            IconThemeData(color: AppColors.ink.withValues(alpha: 0.5)),
        selectedLabelTextStyle:
            GoogleFonts.manrope(color: AppColors.terracotta, fontSize: 12),
        unselectedLabelTextStyle: GoogleFonts.manrope(
            color: AppColors.ink.withValues(alpha: 0.6), fontSize: 12),
        indicatorColor: AppColors.sidebarAccent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle:
            GoogleFonts.manrope(color: AppColors.mutedForeground, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: AppColors.ivory,
          minimumSize: const Size(double.infinity, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.manrope(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.hairline),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.parchment,
        selectedColor: AppColors.sidebarAccent,
        labelStyle: GoogleFonts.manrope(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.darkSidebarPrimary,
        onPrimary: AppColors.ivory,
        primaryContainer: AppColors.darkCard,
        onPrimaryContainer: AppColors.darkForeground,
        secondary: AppColors.gold,
        onSecondary: AppColors.ink,
        secondaryContainer: Color(0xFF4A3520),
        onSecondaryContainer: AppColors.darkForeground,
        tertiary: AppColors.sage,
        onTertiary: AppColors.ivory,
        error: Color(0xFFEF7C6B),
        onError: AppColors.ink,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkForeground,
        surfaceContainerHighest: Color(0xFF443520),
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkBorder,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
      textTheme: _textTheme.apply(
        bodyColor: AppColors.darkForeground,
        displayColor: AppColors.darkForeground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSidebar,
        foregroundColor: AppColors.darkForeground,
        elevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          color: AppColors.darkForeground,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
