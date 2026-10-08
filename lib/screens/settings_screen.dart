import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/floating_settings.dart' show RefreshRate, RefreshRateX;
import '../theme/app_theme.dart';
import '../widgets/feature_list_tile.dart';
import '../widgets/picker_sheets.dart';
import '../widgets/theme_language_dialogs.dart';

/// Écran "Settings" (ouvert depuis l'icône engrenage de l'en-tête).
///
/// - Data refresh rate : fréquence de rafraîchissement de l'onglet Cpu.
/// - Theme color       : couleur d'accent de toute l'application.
/// - Dark theme        : clair / sombre / thème du système.
/// - Switch language   : langue de l'interface.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              Expanded(
                child: ListenableBuilder(
                  listenable: settings,
                  builder: (context, _) {
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 32),
                      children: [
                        FeatureListTile(
                          icon: Icons.update_rounded,
                          title: S.refresh,
                          description: settings.refreshRate.label,
                          onTap: () => showListPicker<RefreshRate>(
                            context: context,
                            options: RefreshRate.values,
                            selected: settings.refreshRate,
                            labelBuilder: (v) => v.label,
                            onSelected: settings.setRefreshRate,
                          ),
                        ),
                        const Divider(height: 1),
                        _ThemeColorTile(settings: settings),
                        const Divider(height: 1),
                        FeatureListTile(
                          icon: Icons.dark_mode_rounded,
                          title: S.darkSetting,
                          description: S.darkDesc,
                          onTap: () => showThemePicker(context),
                        ),
                        const Divider(height: 1),
                        FeatureListTile(
                          icon: Icons.public_rounded,
                          title: S.language,
                          description: S.languageDesc,
                          onTap: () => showLanguagePicker(context),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.arrow_back_rounded, color: AppColors.darkText),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              S.settings,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 1,
                color: AppColors.darkText,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Ligne "Theme color" avec les pastilles de couleur.
class _ThemeColorTile extends StatelessWidget {
  final AppSettings settings;
  const _ThemeColorTile({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.checkroom_rounded, color: AppColors.darkText, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.themeColor,
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  S.themeColorDesc,
                  style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 6.0;
                    final size = ((constraints.maxWidth - gap * (appPalettes.length - 1)) /
                            appPalettes.length)
                        .clamp(30.0, 46.0)
                        .toDouble();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < appPalettes.length; i++) _swatch(i, size),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _swatch(int index, double size) {
    final selected = settings.paletteIndex == index;
    return GestureDetector(
      onTap: () => settings.setPalette(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: selected
              ? Border.all(color: AppColors.mutedText.withValues(alpha: 0.6), width: 3)
              : null,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: appPalettes[index].accent,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
