import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'floating_settings.dart' show RefreshRate;

/// Une couleur de thème proposée dans Settings > Theme color.
class ThemePalette {
  final String name;

  /// Couleur d'accent (titres, barres, courbes, boutons).
  final Color accent;

  /// Variante plus foncée (spinner, seed du thème Material).
  final Color primary;

  const ThemePalette(this.name, this.accent, this.primary);
}

const List<ThemePalette> appPalettes = [
  ThemePalette('Green', Color(0xFF27C281), Color(0xFF1EA05A)),
  ThemePalette('Blue', Color(0xFF2E86FF), Color(0xFF1F6FE0)),
  ThemePalette('Yellow', Color(0xFFF2A93B), Color(0xFFE09A2A)),
  ThemePalette('Pink', Color(0xFFE879C6), Color(0xFFD45DB0)),
  ThemePalette('Orange', Color(0xFFFF8A65), Color(0xFFF0703F)),
  ThemePalette('Red', Color(0xFFF9075E), Color(0xFFD9044F)),
];

/// Choix du thème : clair, sombre ou celui du système.
enum ThemeChoice { light, dark, system }

/// Réglages globaux de l'application (écran Settings), sauvegardés dans
/// SharedPreferences. À charger une fois au démarrage :
/// `await AppSettings.instance.load();`
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _prefsKey = 'app_settings_v1';

  RefreshRate _refreshRate = RefreshRate.two;
  int _paletteIndex = 0;
  ThemeChoice _themeChoice = ThemeChoice.light;

  /// 'system' ou un code de langue : en, fr, es, zh, zh-TW, ...
  String _language = 'system';

  /// Fréquence de rafraîchissement des données de l'onglet Cpu.
  RefreshRate get refreshRate => _refreshRate;

  int get paletteIndex => _paletteIndex;
  ThemePalette get palette => appPalettes[_paletteIndex];

  ThemeChoice get themeChoice => _themeChoice;
  String get language => _language;

  /// Le thème sombre est-il actif en ce moment ?
  bool get isDark {
    switch (_themeChoice) {
      case ThemeChoice.light:
        return false;
      case ThemeChoice.dark:
        return true;
      case ThemeChoice.system:
        return ui.PlatformDispatcher.instance.platformBrightness ==
            Brightness.dark;
    }
  }

  /// Code de langue réellement utilisé (résout "system").
  String get effectiveLanguage {
    if (_language != 'system') return _language;
    final l = ui.PlatformDispatcher.instance.locale;
    if (l.languageCode == 'zh') {
      final traditional = l.scriptCode == 'Hant' ||
          l.countryCode == 'TW' ||
          l.countryCode == 'HK' ||
          l.countryCode == 'MO';
      return traditional ? 'zh-TW' : 'zh';
    }
    return l.languageCode;
  }

  /// Signature de tout ce qui nécessite de reconstruire l'interface.
  String get signature =>
      '$_paletteIndex|${_themeChoice.index}|$effectiveLanguage|${AppColors.isDark}';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final r = (map['refresh'] as num?)?.toInt();
        if (r != null && r >= 0 && r < RefreshRate.values.length) {
          _refreshRate = RefreshRate.values[r];
        }
        final p = (map['palette'] as num?)?.toInt();
        if (p != null && p >= 0 && p < appPalettes.length) {
          _paletteIndex = p;
        }
        final t = (map['theme'] as num?)?.toInt();
        if (t != null && t >= 0 && t < ThemeChoice.values.length) {
          _themeChoice = ThemeChoice.values[t];
        }
        final lang = map['lang'];
        if (lang is String && lang.isNotEmpty) _language = lang;
      }
    } catch (_) {
      // Valeurs par défaut.
    }
    _applyPalette();
    _applyTheme();
  }

  void setRefreshRate(RefreshRate value) {
    if (value == _refreshRate) return;
    _refreshRate = value;
    notifyListeners();
    _save();
  }

  void setPalette(int index) {
    if (index < 0 || index >= appPalettes.length || index == _paletteIndex) return;
    _paletteIndex = index;
    _applyPalette();
    notifyListeners();
    _save();
  }

  void setThemeChoice(ThemeChoice value) {
    if (value == _themeChoice) return;
    _themeChoice = value;
    _applyTheme();
    notifyListeners();
    _save();
  }

  void setLanguage(String code) {
    if (code == _language) return;
    _language = code;
    notifyListeners();
    _save();
  }

  /// À appeler quand le système change de luminosité ou de langue.
  void refreshFromSystem() {
    _applyTheme();
    notifyListeners();
  }

  void _applyPalette() {
    AppColors.setAccent(palette.accent, palette.primary);
  }

  void _applyTheme() {
    AppColors.setDark(isDark);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'refresh': _refreshRate.index,
          'palette': _paletteIndex,
          'theme': _themeChoice.index,
          'lang': _language,
        }),
      );
    } catch (_) {}
  }
}
