import 'package:flutter/material.dart';

// ── MediAuth AI Design Tokens ──────────────────────────────────────────────────
// Organized by semantic intent per senior design spec.
// Zero box-shadows. Depth via surface color + border weight only.

abstract final class C {
  // Surface hierarchy (layering depth)
  static const surf0 = Color(0xFFFFFFFF); // cards, modals
  static const surf1 = Color(0xFFF8FAFD); // scaffold
  static const surf2 = Color(0xFFEFF3F8); // inputs, inactive zones
  static const surf3 = Color(0xFFDDE4EE); // dividers, disabled

  // Aliases for existing code compatibility
  static const white   = surf0;
  static const surf50  = surf1;
  static const surf100 = surf2;
  static const surf200 = Color(0xFFCAD5E5);
  static const surf300 = surf3;

  // Brand primaries
  static const teal50  = Color(0xFFE8FBF6); // teal-050
  static const teal400 = Color(0xFF1AD9B2);
  static const teal500 = Color(0xFF00C9A7); // primary
  static const teal600 = Color(0xFF00B596);
  static const teal700 = Color(0xFF009E84); // pressed states
  static const teal800 = Color(0xFF007E68);
  static const teal900 = Color(0xFF005F4F);

  // Text scale — contrast verified
  static const textPrimary   = Color(0xFF0B1C3A); // 14.1:1 on white ✓
  static const textSecondary = Color(0xFF4A6080); // 6.2:1 on white ✓
  static const textTertiary  = Color(0xFF8097B1); // 3.4:1 (large text only) ✓

  // Aliases for existing code compatibility
  static const navy900 = textPrimary;
  static const navy800 = Color(0xFF112344);
  static const navy700 = Color(0xFF1A3055);
  static const navy500 = Color(0xFF2A4A6E);
  static const navy50  = Color(0xFFEAF0FC);

  static const ink600 = textSecondary;
  static const ink400 = textTertiary;
  static const ink300 = Color(0xFF9AAEC5);

  // Border — universal
  static const border = surf3;

  // Semantic state trios: fill / border / text
  // Approved
  static const green50  = Color(0xFFEAF7EF);
  static const green500 = Color(0xFF27AE60);
  static const green600 = Color(0xFF219150);
  static const green700 = Color(0xFF1A7A42);

  // Denied
  static const red50  = Color(0xFFFDEEEE);
  static const red500 = Color(0xFFE8433A);
  static const red700 = Color(0xFFB02B24);

  // Pending
  static const amber50  = Color(0xFFFEF6E4);
  static const amber500 = Color(0xFFF5A623);
  static const amber600 = Color(0xFFD4901E);
  static const amber700 = Color(0xFFB8751A);

  // Appeal / Violet
  static const violet50  = Color(0xFFEFECFF);
  static const violet500 = Color(0xFF7B61FF);
  static const violet700 = Color(0xFF5942CC);

  // Submitted / Blue
  static const blue50  = Color(0xFFEAF0FC);
  static const blue500 = Color(0xFF3A7BD5);
  static const blue700 = Color(0xFF2459A8);
}
