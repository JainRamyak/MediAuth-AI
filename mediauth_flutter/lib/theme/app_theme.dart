import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

// ── MediAuth AI AppTheme ───────────────────────────────────────────────────────
// Zero elevation. Depth via surface color + border only.
// Inter for UI. JetBrains Mono for editor panes + code.

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: C.surf1,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary:        C.teal500,
        onPrimary:      C.white,
        primaryContainer: C.teal50,
        onPrimaryContainer: C.teal700,
        secondary:      C.navy500,
        onSecondary:    C.white,
        surface:        C.surf0,
        onSurface:      C.textPrimary,
        error:          C.red500,
        onError:        C.white,
      ),

      // ── Typography ──────────────────────────────────────────────────────────
      textTheme: TextTheme(
        // display 32/500
        displayLarge: GoogleFonts.inter(
          fontSize: 32, fontWeight: FontWeight.w500,
          color: C.textPrimary, letterSpacing: -0.5),
        // h1 24/500
        headlineLarge: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: C.textPrimary, letterSpacing: -0.3),
        // h2 20/500
        headlineMedium: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: C.textPrimary, letterSpacing: -0.2),
        // h3 16/500
        headlineSmall: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: C.textPrimary),
        // title (used in AppBar, card headers)
        titleLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600,
          color: C.textPrimary),
        titleMedium: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w600,
          color: C.textPrimary),
        titleSmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: C.textPrimary),
        // body 15/400
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: C.textPrimary, height: 1.5),
        // body 13/400 (small)
        bodyMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: C.textSecondary, height: 1.5),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: C.textTertiary, height: 1.4),
        // label 11/500
        labelLarge: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: C.textSecondary),
        labelMedium: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: C.textTertiary, letterSpacing: 0.2),
        labelSmall: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w500,
          color: C.textTertiary, letterSpacing: 0.3),
      ),

      // ── AppBar — zero elevation ─────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: C.surf0,
        foregroundColor: C.textPrimary,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: C.textPrimary),
        iconTheme: const IconThemeData(
          color: C.textPrimary, size: 22),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Cards — zero elevation ──────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: C.surf0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: C.surf3, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Elevations killed everywhere ────────────────────────────────────────
      dialogTheme: const DialogThemeData(elevation: 0),
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        backgroundColor: C.surf0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)))),

      // ── Input fields ────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: C.surf2,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: C.surf3, width: 0.5)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: C.surf3, width: 0.5)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: C.teal500, width: 1.5)),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: C.red500, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: C.red500, width: 1.5)),
        labelStyle: GoogleFonts.inter(
          fontSize: 13, color: C.textTertiary),
        hintStyle: GoogleFonts.inter(
          fontSize: 14, color: C.textTertiary),
        errorStyle: GoogleFonts.inter(
          fontSize: 12, color: C.red700),
        suffixStyle: GoogleFonts.inter(
          fontSize: 12, color: C.textTertiary),
      ),

      // ── Elevated buttons ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.teal500,
          foregroundColor: C.white,
          disabledBackgroundColor: C.surf3,
          disabledForegroundColor: C.textTertiary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // ── Outlined buttons ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: C.textPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: C.surf3, width: 0.5),
          textStyle: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Chips ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: C.surf2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.inter(
          fontSize: 12, color: C.textSecondary),
        padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 4),
        side: const BorderSide(color: C.surf3, width: 0.5),
      ),

      // ── Bottom nav ──────────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: C.surf0,
        elevation: 0,
        selectedItemColor: C.teal500,
        unselectedItemColor: C.textTertiary,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w400),
        type: BottomNavigationBarType.fixed,
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: C.surf3, thickness: 0.5, space: 0),

      // ── FAB ─────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: C.teal500,
        foregroundColor: C.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ── JetBrains Mono text style (editor panes) ─────────────────────────────────
  static TextStyle monoStyle({
    double size = 13,
    Color color = C.teal400,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height ?? 1.55,
  );
}
