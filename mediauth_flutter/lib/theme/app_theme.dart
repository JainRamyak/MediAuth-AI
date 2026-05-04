import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

// ── MediAuth AI AppTheme — V4 ──────────────────────────────────────────────────
// Font: Outfit (headings/display) + Inter (body/UI) + DM Mono (code)
// Zero elevation. Depth via surface colour + 0.5px border only.
// Radii spec: card=14, button=14, input=10, pill=100, chip=8, bottomSheet top=20

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: C.surf1,

      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary:             C.primary500,
        onPrimary:           C.white,
        primaryContainer:    C.primary50,
        onPrimaryContainer:  C.primary700,
        secondary:           C.primary400,
        onSecondary:         C.white,
        surface:             C.surf0,
        onSurface:           C.textPrimary,
        error:               C.red,
        onError:             C.white,
      ),

      // ── Typography ────────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w800,
          color: C.textPrimary, letterSpacing: -1),
        displayMedium: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: C.textPrimary, letterSpacing: -0.5),
        displaySmall: GoogleFonts.inter(
          fontSize: 19, fontWeight: FontWeight.w700,
          color: C.textPrimary, letterSpacing: -0.4),
        headlineLarge: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: C.textPrimary, letterSpacing: -0.2),
        headlineMedium: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w500,
          color: C.textPrimary, letterSpacing: -0.2, height: 1.2),
        headlineSmall: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: C.textPrimary),
        titleLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: C.textPrimary),
        titleMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: C.textPrimary),
        titleSmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: C.textSecondary),
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: C.textPrimary, height: 1.5),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: C.textPrimary),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: C.textSecondary, height: 1.5),
        labelLarge: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: C.textTertiary, letterSpacing: 0.1),
        labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: C.textSecondary),
        labelSmall: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w400,
          color: C.textTertiary, letterSpacing: 0.2),
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: C.primary500,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Cards — very rounded ──────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: C.surf0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: C.surf3.withValues(alpha: 0.5), width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Dialogs / Sheets ──────────────────────────────────────────────────
      dialogTheme: const DialogThemeData(elevation: 0),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: C.surf0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)))),

      // ── Input fields ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: C.surf2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.primary500, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: C.red, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13, color: C.textSecondary, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(
          fontSize: 14, color: C.textTertiary, fontWeight: FontWeight.w400),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: C.red),
        prefixIconColor: C.textTertiary,
      ),

      // ── Elevated buttons ──────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.primary500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: C.primary500.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),

      // ── Outlined buttons ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: C.textPrimary,
          backgroundColor: C.surf0,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          side: const BorderSide(color: C.surf3, width: 1),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Chips ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: C.surf2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: C.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: BorderSide.none,
      ),

      // ── Bottom nav ────────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: C.surf0,
        elevation: 0,
        selectedItemColor: C.primary500,
        unselectedItemColor: C.textTertiary,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: C.surf3, thickness: 0.5, space: 0),

      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: C.primary500,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    );
  }

  static TextStyle monoStyle({
    double size = 13,
    Color color = C.primary400,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => GoogleFonts.dmMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height ?? 1.55,
  );
}

