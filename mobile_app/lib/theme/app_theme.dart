import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// 🎨 AppTheme
/// Sistema de diseño Sweet Models Enterprise con paleta Zinc minimalista
/// Compatible con shadcn_ui ^0.16.3
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════
  // 🎨 Zinc Color Palette (Premium Dark Theme)
  // ═══════════════════════════════════════════════════════════════
  
  /// Background principal - Casi negro
  static const Color background = Color(0xFF09090B);  // zinc-950
  
  /// Superficies elevadas
  static const Color surface = Color(0xFF18181B);     // zinc-900
  static const Color surfaceLight = Color(0xFF27272A); // zinc-800
  
  /// Bordes sutiles
  static const Color border = Color(0xFF3F3F46);      // zinc-700
  static const Color borderLight = Color(0xFF52525B); // zinc-600
  
  /// Texto
  static const Color textPrimary = Color(0xFFFAFAFA);  // zinc-50
  static const Color textSecondary = Color(0xFFA1A1AA); // zinc-400
  static const Color textMuted = Color(0xFF71717A);    // zinc-500
  
  /// Colores de marca
  static const Color accent = Color(0xFFEB1555);       // Pink (Sweet Models brand)
  static const Color accentSecondary = Color(0xFF00D4FF); // Cyan
  
  /// Estados
  static const Color success = Color(0xFF10B981);      // Green
  static const Color error = Color(0xFFEF4444);        // Red
  static const Color warning = Color(0xFFF59E0B);      // Amber
  
  // ═══════════════════════════════════════════════════════════════
  // 📏 Spacing & Radius
  // ═══════════════════════════════════════════════════════════════
  
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // ═══════════════════════════════════════════════════════════════
  // 🖋️ Typography (Inter Font)
  // ═══════════════════════════════════════════════════════════════
  
  static TextTheme get textTheme => GoogleFonts.interTextTheme(
        const TextTheme(
          // Display
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: textPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: textPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: textPrimary,
          ),
          
          // Headlines
          headlineLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.5,
            color: textPrimary,
          ),
          
          // Body
          bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            height: 1.5,
            color: textMuted,
          ),
          
          // Labels
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: textPrimary,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: textSecondary,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: textMuted,
          ),
        ),
      );

  // ═══════════════════════════════════════════════════════════════
  // 🎨 Shadcn Theme Data (shadcn_ui ^0.16.3 compatible)
  // ═══════════════════════════════════════════════════════════════
  
  static ShadThemeData get shadcnTheme => ShadThemeData(
        colorScheme: const ShadZincColorScheme.dark(),
        brightness: Brightness.dark,
      );

  // ═══════════════════════════════════════════════════════════════
  // 📱 Material Theme Fallback
  // ═══════════════════════════════════════════════════════════════
  
  static ThemeData get materialTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accentSecondary,
          surface: surface,
          error: error,
        ),
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: surface,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: textTheme.headlineMedium,
          iconTheme: const IconThemeData(color: textPrimary),
        ),
        cardTheme: CardTheme(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
            side: const BorderSide(color: border, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: textPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            textStyle: textTheme.labelLarge,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: textPrimary,
            side: const BorderSide(color: border),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            textStyle: textTheme.labelLarge,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: const BorderSide(color: accent, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            borderSide: const BorderSide(color: error),
          ),
          labelStyle: textTheme.labelMedium,
          hintStyle: TextStyle(color: textMuted),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 1,
        ),
        iconTheme: const IconThemeData(
          color: textPrimary,
          size: 24,
        ),
        useMaterial3: true,
      );
}
