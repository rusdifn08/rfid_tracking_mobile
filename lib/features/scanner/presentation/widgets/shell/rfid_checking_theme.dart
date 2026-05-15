import 'package:flutter/material.dart';

/// Palet visual halaman Checking RFID — selaras dengan shell app, aksen teal.
abstract final class RfidCheckingTheme {
  static const Color canvas = Color(0xFFF0F4F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF0F172A);
  static const Color inkSecondary = Color(0xFF475467);
  static const Color inkMuted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);

  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);

  static const Color accentBlue = Color(0xFF3155FF);
  static const Color accentBlueSoft = Color(0xFFEEF2FF);

  static const Color found = Color(0xFF059669);
  static const Color foundSoft = Color(0xFFECFDF5);
  static const Color notFound = Color(0xFFE11D48);
  static const Color notFoundSoft = Color(0xFFFFF1F2);
  static const Color totalSoft = Color(0xFFEEF2FF);

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scanCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF0FDFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> cardShadow({Color? tint}) => [
    BoxShadow(
      color: (tint ?? const Color(0xFF0F172A)).withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.8),
      blurRadius: 0,
      offset: const Offset(0, -1),
    ),
  ];

  static BoxDecoration surfaceCard({
    Color? borderColor,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      gradient: gradient,
      color: gradient == null ? surface : null,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: borderColor ?? border,
        width: 1,
      ),
      boxShadow: cardShadow(),
    );
  }
}
