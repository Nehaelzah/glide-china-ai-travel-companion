import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glide China visual identity.
///
/// Palette: light cyan → teal → green → lime, on a soft off-white canvas.
/// The brand feeling is "smooth flight": airy backgrounds, rounded cards,
/// soft low-contrast shadows, and a single confident teal→lime accent.
class AppColors {
  AppColors._();

  // Core brand ramp
  // Brand ramp (sampled from the mockups): sky blue → cyan → green → lime.
  static const Color sky = Color(0xFF4DB8F0); // button blue (left of gradient)
  static const Color cyan = Color(0xFF3FD0D8); // light cyan
  static const Color teal = Color(0xFF17B0C4); // primary accent (links, icons)
  static const Color tealDeep = Color(0xFF0B7F79); // pressed / dark teal
  static const Color green = Color(0xFF6DD68C); // travel green
  static const Color lime = Color(0xFFC5EB8D); // lime highlight (right of gradient)

  // Soft background wash corners (the signature gradient canvas).
  static const Color bgTopLeft = Color(0xFF9BDCFB); // pale sky blue
  static const Color bgMid = Color(0xFFCFF4F7); // pale cyan
  static const Color bgBottomRight = Color(0xFFE3F7E2); // pale green

  // Canvas & surfaces
  static const Color canvas = Color(0xFFEAF6FB); // fallback flat canvas
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEDF6F8);

  // Text
  static const Color ink = Color(0xFF15304A); // deep navy-teal (matches mockups)
  static const Color inkSoft = Color(0xFF5A7184); // secondary text
  static const Color inkFaint = Color(0xFF97A8B5); // hints, captions

  // Utility
  static const Color danger = Color(0xFFEB5F52);
  static const Color amber = Color(0xFFF2A93B);
  static const Color line = Color(0xFFE3EDF2);

  /// Primary action gradient: blue → cyan → lime (left to right), as on the
  /// Continue / primary buttons in the mockups.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [sky, cyan, lime],
  );

  static const LinearGradient limeGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [green, lime],
  );

  /// The signature app background wash.
  static const LinearGradient canvasGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [bgTopLeft, bgMid, bgBottomRight],
  );

  /// The friendly solid blue used for the user's own chat bubbles.
  static const Color userBubble = Color(0xFF3FA9F5);
}

class AppRadii {
  AppRadii._();
  static const double card = 22;
  static const double chip = 16;
  static const double pill = 999;
  static const double sheet = 28;
}

class AppShadows {
  AppShadows._();
  static List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.teal.withOpacity(0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> lift = [
    BoxShadow(
      color: AppColors.teal.withOpacity(0.18),
      blurRadius: 30,
      offset: const Offset(0, 14),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          displayLarge: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          displayMedium: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          displaySmall: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          headlineLarge: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          headlineMedium: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          headlineSmall: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          titleLarge: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          titleMedium: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          titleSmall: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          bodyLarge: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          bodyMedium: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          bodySmall: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          labelLarge: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          labelMedium: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
          labelSmall: const TextStyle(fontFamilyFallback: ['Segoe UI', 'Arial']),
        );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.teal,
        secondary: AppColors.green,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.ink,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.teal,
          side: const BorderSide(color: AppColors.teal, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.inkFaint),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceAlt,
        labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.ink),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        side: BorderSide.none,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    );
  }
}
