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
        primary:             C.teal500,
        onPrimary:           C.white,
        primaryContainer:    C.teal50,
        onPrimaryContainer:  C.teal700,
        secondary:           C.navy500,
        onSecondary:         C.white,
        surface:             C.surf0,
        onSurface:           C.textPrimary,
        error:               C.red500,
        onError:             C.white,
      ),

      // ── Typography ────────────────────────────────────────────────────────
      textTheme: TextTheme(
        // stat numbers: Outfit 28/800
        displayLarge: GoogleFonts.outfit(
          fontSize: 28, fontWeight: FontWeight.w800,
          color: C.textPrimary, letterSpacing: -1),
        // welcome/hero heading: Outfit 22/800
        displayMedium: GoogleFonts.outfit(
          fontSize: 22, fontWeight: FontWeight.w800,
          color: C.textPrimary, letterSpacing: -0.5),
        // section heading: Outfit 19/700
        displaySmall: GoogleFonts.outfit(
          fontSize: 19, fontWeight: FontWeight.w700,
          color: C.textPrimary, letterSpacing: -0.4),
        // app bar name: Outfit 18/700
        headlineLarge: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w700,
          color: C.textPrimary, letterSpacing: -0.2),
        // step/display title: Outfit 20/500
        headlineMedium: GoogleFonts.outfit(
          fontSize: 20, fontWeight: FontWeight.w500,
          color: C.textPrimary, letterSpacing: -0.2, height: 1.2),
        // card titles: Inter 16/700
        headlineSmall: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700,
          color: C.textPrimary),
        // primary button label: Inter 15/700
        titleLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w700,
          color: C.textPrimary),
        // button label / step title: Inter 13/700
        titleMedium: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: C.textPrimary),
        // field label / secondary text: Inter 13/500
        titleSmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w500,
          color: C.textSecondary),
        // body text: Inter 15/400
        bodyLarge: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400,
          color: C.textPrimary, height: 1.5),
        // body/card treatment name: Inter 14/600
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w600,
          color: C.textPrimary),
        // small body / subtitle: Inter 12/400
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: C.textSecondary, height: 1.5),
        // stat/pill labels: Inter 11/600
        labelLarge: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: C.textTertiary, letterSpacing: 0.1),
        // filter pills: Inter 12/600
        labelMedium: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: C.textSecondary),
        // hints / step label uppercase: Inter 10/400
        labelSmall: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w400,
          color: C.textTertiary, letterSpacing: 0.2),
      ),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: C.navy800,
        foregroundColor: Colors.white,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white, size: 22),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Cards — zero elevation ────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: C.surf0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),

      // ── Input fields — spec: 52px height, radius 10, surf2 fill ──────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: C.surf2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: C.surf3, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: C.surf3, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: C.teal500, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: C.red500, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: C.red500, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 13, color: C.textSecondary, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(
          fontSize: 14, color: C.textTertiary, fontWeight: FontWeight.w400),
        errorStyle: GoogleFonts.inter(fontSize: 12, color: C.red700),
        prefixIconColor: C.textTertiary,
      ),

      // ── Elevated buttons — spec: 52px, radius 14 ─────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.teal500,
          foregroundColor: Colors.white,
          disabledBackgroundColor: C.teal500.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),

      // ── Outlined buttons ──────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: C.textPrimary,
          backgroundColor: C.surf0,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          side: const BorderSide(color: C.surf3, width: 1),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ── Chips — spec: 30px, radius 8, teal50 bg ──────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: C.surf2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: C.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        side: const BorderSide(color: C.surf3, width: 0.5),
      ),

      // ── Bottom nav ────────────────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: C.surf0,
        elevation: 0,
        selectedItemColor: C.teal500,
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
        backgroundColor: C.teal500,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 4,
        hoverElevation: 6,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── DM Mono text style (editor panes / code output) ──────────────────────
  static TextStyle monoStyle({
    double size = 13,
    Color color = C.teal400,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => GoogleFonts.dmMono(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height ?? 1.55,
  );
}
