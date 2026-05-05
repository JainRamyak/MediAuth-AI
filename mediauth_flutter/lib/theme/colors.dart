import 'package:flutter/material.dart';

// ── MediAuth AI Design Tokens — V4 ───────────────────────────────────────────
// All hex values match the V4 design spec exactly.
// Zero box-shadows. Depth via surface color + border weight only.

abstract final class C {
  // ── Surfaces ─────────────────────────────────────────────────────────────
  static const surf0 = Color(0xFFFFFFFF); // cards, modals
  static const surf1 = Color(0xFFF8FAFC); // page background (slate 50)
  static const surf2 = Color(0xFFF1F5F9); // input fill (slate 100)
  static const surf3 = Color(0xFFE2E8F0); // borders (slate 200)

  // Aliases
  static const white   = surf0;
  static const border  = surf3;

  // ── Brand Primary (Blue) ──────────────────────────────────────────────────
  static const primary50  = Color(0xFFEFF6FF);
  static const primary100 = Color(0xFFDBEAFE);
  static const primary400 = Color(0xFF60A5FA);
  static const primary500 = Color(0xFF628DC5); // PRIMARY — matching images
  static const primary600 = Color(0xFF2563EB);
  static const primary700 = Color(0xFF1D4ED8);
  static const primary800 = Color(0xFF1E3A8A);

  // ── Stats / Accent Colors ────────────────────────────────────────────────
  static const purple = Color(0xFF7C3AED); // Submissions In Progress
  static const green  = Color(0xFF10B981); // Approved
  static const orange = Color(0xFFF59E0B); // Pending
  static const red    = Color(0xFFEF4444); // Denied

  // ── Text ─────────────────────────────────────────────────────────────────
  static const textPrimary   = Color(0xFF0F172A); // slate 900
  static const textSecondary = Color(0xFF475569); // slate 600
  static const textTertiary  = Color(0xFF94A3B8); // slate 400

  // ── Status: Approved (green) ──────────────────────────────────────────────
  static const green50  = Color(0xFFECFDF5);
  static const green500 = green;
  static const green600 = Color(0xFF059669);
  static const green700 = Color(0xFF047857);
  static const green800 = Color(0xFF065F46);

  // ── Status: Pending (amber) ───────────────────────────────────────────────
  static const amber50  = Color(0xFFFFFBEB);
  static const amber500 = orange;
  static const amber600 = Color(0xFFD97706);
  static const amber700 = Color(0xFFB45309);
  static const amber800 = Color(0xFF92400E);

  // ── Status: Denied (red) ─────────────────────────────────────────────────
  static const red50  = Color(0xFFFEF2F2);
  static const red500 = red;
  static const red600 = Color(0xFFDC2626);
  static const red700 = Color(0xFFB91C1C);
  static const red800 = Color(0xFF991B1B);

  // ── Stats: Purple ────────────────────────────────────────────────────────
  static const violet50  = Color(0xFFF5F3FF);
  static const violet500 = purple;
  static const violet700 = Color(0xFF6D28D9);
  static const violet800 = Color(0xFF5B21B6);

  // ── Legacy / Compatibility ───────────────────────────────────────────────
  static const navy800 = primary500; 
  static const navy900 = primary600;
  static const light   = surf0;
  static const teal50  = primary50;
  static const teal400 = primary400;
  static const teal500 = primary500;
  static const teal600 = primary600;
  static const teal700 = primary700;
  
  static const blue50  = primary50;
  static const blue500 = primary500;
  static const blue800 = primary800;
}

