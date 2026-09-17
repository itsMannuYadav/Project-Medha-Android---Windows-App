import 'package:flutter/material.dart';

// Medha brand palette — mirrors shiksha_sathi/app/globals.css.
// Values verified 2026-09-17 by converting the SOURCE oklch() strings to hex
// via a real browser canvas (not hand/mental oklch math, which is how the
// previous values in this file drifted this far off — every single token was
// wrong, some substantially, e.g. violet #5B3FAF vs the real #7a55c7).
// Re-verify against globals.css directly if brand colors are ever revisited.
class AppColors {
  // Named editorial palette
  static const ivory = Color(0xFFFAF6EF);
  static const parchment = Color(0xFFF5EEE2);
  static const ink = Color(0xFF1C1612);
  static const terracotta = Color(0xFFA75639);
  static const gold = Color(0xFFC4984F);
  static const earth = Color(0xFF4C3323);
  static const sage = Color(0xFF556C55);
  static const hairline = Color(0xFFDBD3C7);

  // Violet (AI / Ask Medha accent)
  static const violet = Color(0xFF7A55C7);
  static const violetMuted = Color(0xFFF1EAFF);

  // Light theme
  static const background = ivory;
  static const foreground = ink;
  static const card = Color(0xFFFEFBF5);
  static const cardForeground = ink;
  static const primary = ink;
  static const primaryForeground = ivory;
  static const secondary = parchment;
  static const secondaryForeground = ink;
  static const muted = parchment;
  static const mutedForeground = Color(0xFF655A51);
  static const accent = Color(0xFFF2E5CD);
  static const accentForeground = ink;
  static const destructive = Color(0xFFC5312E);
  static const border = hairline;
  static const ring = gold;

  // Sidebar
  static const sidebar = Color(0xFFFAF7F2);
  static const sidebarForeground = ink;
  static const sidebarPrimary = terracotta;
  static const sidebarPrimaryForeground = ivory;
  static const sidebarAccent = Color(0xFFFDE5DB);
  static const sidebarAccentForeground = terracotta;
  static const sidebarBorder = hairline;

  // Login/Register pages only (.mlogin-*/.mreg-* in globals.css) — a
  // deliberately darker, more saturated shade than --terracotta, used for
  // the heading, active role tab, and submit button on those two screens
  // specifically. Do not use elsewhere in the app.
  static const authDeep = Color(0xFF632A15);
  static const authDeepHover = Color(0xFF512312);

  // Dark theme
  static const darkBackground = Color(0xFF2F2519);
  static const darkForeground = Color(0xFFF4EFE5);
  static const darkCard = Color(0xFF3A2E22);
  static const darkSidebar = Color(0xFF342A1E);
  static const darkSidebarPrimary = Color(0xFFCB7048);
  static const darkBorder = Color(0x1FFFFFFF);

  // Content-generation category tints + fills (Quick Action cards, type
  // badges) — verified against globals.css: lesson=violet, presentation=blue,
  // question paper=terracotta, quiz=green, notes=gold.
  static const tintLessonPlan = Color(0xFFF0EBFF);
  static const tintPresentation = Color(0xFFDEF2FF);
  static const tintQuestionPaper = Color(0xFFFFE9E4);
  static const tintQuiz = Color(0xFFE1F6E4);
  static const tintNotes = Color(0xFFFDF0D5);
  static const fillLessonPlan = violet;
  static const fillPresentation = Color(0xFF0077C7);
  static const fillQuestionPaper = terracotta;
  static const fillQuiz = Color(0xFF319751);
  static const fillNotes = gold;

  // Indian tricolor for the quote bar
  static const saffron = Color(0xFFFF9933);
  static const tricolorWhite = Color(0xFFFFFFFF);
  static const tricolorGreen = Color(0xFF138808);
}
