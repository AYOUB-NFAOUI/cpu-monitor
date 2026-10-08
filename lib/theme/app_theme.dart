import 'package:flutter/material.dart';

/// Palette et styles communs. Les couleurs de fond / texte changent selon
/// le mode (clair / sombre) ; l'accent change selon Settings > Theme color.
///
/// ATTENTION : ces couleurs sont maintenant des GETTERS (pas des constantes),
/// donc on ne peut plus les utiliser dans une expression `const`.
class AppColors {
  AppColors._();

  static Color _accent = const Color(0xFF27C281);
  static Color _primary = const Color(0xFF1EA05A);
  static bool _dark = false;

  static Color get accentGreen => _accent;
  static Color get primaryGreen => _primary;

  static void setAccent(Color accent, Color primary) {
    _accent = accent;
    _primary = primary;
  }

  static bool get isDark => _dark;
  static void setDark(bool value) => _dark = value;

  static Color get background =>
      _dark ? const Color(0xFF121316) : const Color(0xFFFFFFFF);
  static Color get surface =>
      _dark ? const Color(0xFF1D2026) : const Color(0xFFF4F6F8);

  /// Petite boîte posée SUR une surface (avant : Colors.white).
  static Color get card =>
      _dark ? const Color(0xFF2A2E36) : const Color(0xFFFFFFFF);

  /// Fond des popups / dialogues.
  static Color get dialogBg =>
      _dark ? const Color(0xFF23262D) : const Color(0xFFFFFFFF);

  static Color get darkText =>
      _dark ? const Color(0xFFEDEFF3) : const Color(0xFF2B2F38);
  static Color get mutedText =>
      _dark ? const Color(0xFF9AA3B2) : const Color(0xFF8A93A3);
  static Color get pillDark =>
      _dark ? const Color(0xFF3A3F4A) : const Color(0xFF2B2F38);
  static Color get trackGrey =>
      _dark ? const Color(0xFF3A3F4A) : const Color(0xFFE7EAF0);
  static Color get gridDot =>
      _dark ? const Color(0xFFB8BFCC) : const Color(0xFF2B2F38);
  static Color get divider =>
      _dark ? const Color(0xFF2E323B) : const Color(0xFFE6E8EC);

  static const Color chartFill = Color(0x3327C281);
}

class AppTheme {
  AppTheme._();

  /// ThemeData construit à partir de l'état courant de [AppColors].
  static ThemeData get current {
    final brightness = AppColors.isDark ? Brightness.dark : Brightness.light;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      fontFamily: 'Roboto',
      dividerTheme: DividerThemeData(color: AppColors.divider, thickness: 1),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: brightness,
        primary: AppColors.primaryGreen,
        surface: AppColors.background,
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.darkText,
          letterSpacing: 0.5,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.darkText,
        ),
        bodyMedium: TextStyle(color: AppColors.darkText),
      ),
    );
  }

  /// Compatibilité avec l'ancien code.
  static ThemeData get light => current;
}
