import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF334A68);
  static const Color primarySoft = Color(0xFFEAF0F7);
  static const Color accentMint = Color(0xFFEAF3F6);
  static const Color accentPink = Color(0xFFF4E6DE);
  static const Color accentYellow = Color(0xFFEFD8A5);
  static const Color accentBlue = Color(0xFFDDEAF7);
  static const Color accent = Color(0xFF1E2A3A);
  static const Color surface = Color(0xFFF4F6F9);
  static const Color mutedText = Color(0xFF5D6878);
  static const Color border = Color(0xFFD9E1EC);
  static const Color teal = Color(0xFF4E6F9E);
  static const Color success = Color(0xFF71908A);
  static const Color warning = Color(0xFFE0A24E);
  static const Color error = Color(0xFFB56556);

  static ThemeData get lightTheme {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: warning,
          onSecondary: accent,
          surface: Colors.white,
          onSurface: accent,
          onSurfaceVariant: mutedText,
          error: error,
        );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surface,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: accent,
        titleTextStyle: TextStyle(
          color: accent,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: accent,
          fontSize: 30,
          fontWeight: FontWeight.w800,
        ),
        headlineLarge: TextStyle(
          color: accent,
          fontWeight: FontWeight.w800,
          fontSize: 30,
        ),
        headlineMedium: TextStyle(
          color: accent,
          fontWeight: FontWeight.w700,
          fontSize: 25,
        ),
        headlineSmall: TextStyle(
          color: accent,
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: accent,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: accent,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: accent,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: accent),
        bodyMedium: TextStyle(color: mutedText),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: const BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      drawerTheme: const DrawerThemeData(backgroundColor: Colors.white),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
