import 'package:flutter/material.dart';

// ── MediAuth AI Design Tokens — V4 ───────────────────────────────────────────
// All hex values match the V4 design spec exactly.
// Zero box-shadows. Depth via surface color + border weight only.

abstract final class C {
  // ── Surfaces (layering depth) ─────────────────────────────────────────────
  static const surf0 = Color(0xFFFFFFFF); // cards, modals
  static const surf1 = Color(0xFFF4F5F8); // page background
  static const surf2 = Color(0xFFF0F1F4); // input fill, chip area bg
  static const surf3 = Color(0xFFE2E4EA); // borders, dividers, skeleton

  // Aliases for backward compat
  static const white   = surf0;
  static const surf50  = surf1;
  static const surf100 = surf2;
  static const surf200 = Color(0xFFCAD5E5);
  static const surf300 = surf3;
  static const border  = surf3;

  // ── Brand primaries ───────────────────────────────────────────────────────
  static const teal50  = Color(0xFFE6F6F2); // chip/badge bg
  static const teal100 = Color(0xFFB3E5D8); // hover tints
  static const teal400 = Color(0xFF1BBF96); // online dot, ring accents
  static const teal500 = Color(0xFF0A9E7A); // PRIMARY — buttons, active states
  static const teal600 = Color(0xFF087A5E); // teal text on light bg, hover
  static const teal700 = Color(0xFF065C47); // dark teal text
  static const teal800 = Color(0xFF044836);
  static const teal900 = Color(0xFF02311F);

  // ── App Bar ───────────────────────────────────────────────────────────────
  static const navy800 = Color(0xFF1A2744); // app bar background
  static const navy900 = Color(0xFF111C38); // gradient start (top-left)
  static const navy700 = Color(0xFF243359);
  static const navy500 = Color(0xFF2A4A6E);
  static const navy50  = Color(0xFFEAF0FC);

  // ── Text ─────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF0F1117); // headings, card titles
  static const textSecondary = Color(0xFF5A6072); // body, subtitles
  static const textTertiary  = Color(0xFF9BA3B8); // hints, dates, metadata

  // Aliases
  static const ink600 = textSecondary;
  static const ink400 = textTertiary;
  static const ink300 = Color(0xFF9AAEC5);

  // ── Status: Approved (green) ──────────────────────────────────────────────
  static const green50  = Color(0xFFEAF6EC);
  static const green500 = Color(0xFF22A840); // dot/accent
  static const green600 = Color(0xFF1E9238);
  static const green700 = Color(0xFF146625); // text
  static const green800 = Color(0xFF0E4C1B);

  // ── Status: Pending (amber) ───────────────────────────────────────────────
  static const amber50  = Color(0xFFFEF7E6);
  static const amber500 = Color(0xFFF0A500); // dot/accent
  static const amber600 = Color(0xFFCC8C00);
  static const amber700 = Color(0xFF8C5E00); // text
  static const amber800 = Color(0xFF664400);

  // ── Status: Denied (red) ─────────────────────────────────────────────────
  static const red50  = Color(0xFFFEF0F0);
  static const red500 = Color(0xFFE8413A); // dot/accent
  static const red700 = Color(0xFF951C17); // text
  static const red800 = Color(0xFF6E1410);

  // ── Status: Appealing (violet) ────────────────────────────────────────────
  static const violet50  = Color(0xFFF0EEFB);
  static const violet500 = Color(0xFF7C63E8); // dot/accent
  static const violet700 = Color(0xFF4A35B8); // text
  static const violet800 = Color(0xFF362590);

  // ── Status: Submitted (blue) ──────────────────────────────────────────────
  static const blue50  = Color(0xFFEAF2FD);
  static const blue500 = Color(0xFF2979D6); // dot/accent
  static const blue700 = Color(0xFF1A4E9C); // text
  static const blue800 = Color(0xFF123A73);
}
