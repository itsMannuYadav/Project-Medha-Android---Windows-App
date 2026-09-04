import 'package:flutter/widgets.dart';

/// Design tokens for Medha's "clean official" visual language — an
/// institutional blue as the primary color, a single warm gold accent used
/// sparingly, and semantic colors for the approval-heavy workflows
/// (pending / approved / rejected) that run through this app.
///
/// These mirror the tokens authored in the Claude Design canvas
/// (`design-canvas/medha-teacher-app/`) so the two stay in sync — if a
/// token changes there, mirror the change here.
class MedhaColors {
  MedhaColors._();

  static const bg = Color(0xFFF6F8FB);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEEF2F8);

  static const ink = Color(0xFF152238);
  static const inkSoft = Color(0xFF3B4A63);
  static const muted = Color(0xFF6B7A92);

  static const border = Color(0xFFDFE5EE);
  static const borderStrong = Color(0xFFC9D3E0);

  static const primary = Color(0xFF1E3E72);
  static const primaryDark = Color(0xFF152C55);
  static const primaryWash = Color(0xFFEAF0FA);

  static const accent = Color(0xFFC98A2C);
  static const accentInk = Color(0xFF6B4A17);
  static const accentWash = Color(0xFFFBF0DD);

  static const success = Color(0xFF2F7D4F);
  static const successInk = Color(0xFF1F5836);
  static const successWash = Color(0xFFE7F5EC);

  static const danger = Color(0xFFB4392C);
  static const dangerWash = Color(0xFFFBEAE7);

  static const shadow = Color(0x14152238);
}
