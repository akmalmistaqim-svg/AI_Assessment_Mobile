import 'package:flutter/material.dart';

/// Tema visual resmi Dexa Assessment Mobile.
/// Menggunakan palet putih, biru langit, dan biru tua dengan kontras tinggi.
class AppTheme {
  AppTheme._();

  // Warna Utama
  static const Color navyDark = Color(0xFF0A2540);
  static const Color navyPrimary = Color(0xFF0F2C59);
  static const Color skyBlue = Color(0xFF0284C7);
  static const Color skyBlueLight = Color(0xFFE0F2FE);
  static const Color skyBlueBorder = Color(0xFFBAE6FD);

  // Warna Netral & Permukaan
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color chipBackground = Color(0xFFF1F5F9);

  // Warna Teks Kontras Tinggi
  static const Color textDark = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textMuted = Color(0xFF64748B);

  // Warna Status
  static const Color statusUnread = Color(0xFF0284C7);
  static const Color statusRead = Color(0xFF64748B);
  static const Color statusBadgeBg = Color(0xFFFEE2E2);
  static const Color statusBadgeText = Color(0xFFDC2626);
  static const Color demoBadgeBg = Color(0xFFFEF3C7);
  static const Color demoBadgeText = Color(0xFF92400E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: navyPrimary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: navyPrimary,
        onPrimary: surfaceWhite,
        primaryContainer: skyBlueLight,
        onPrimaryContainer: navyDark,
        secondary: skyBlue,
        onSecondary: surfaceWhite,
        surface: surfaceWhite,
        onSurface: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: navyPrimary,
        foregroundColor: surfaceWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: surfaceWhite,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
        ),
        iconTheme: IconThemeData(color: surfaceWhite),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceWhite,
        selectedItemColor: navyPrimary,
        unselectedItemColor: textMuted,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textDark,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: textSecondary,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textMuted,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
