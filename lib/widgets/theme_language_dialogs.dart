import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';
import 'picker_sheets.dart';

// ---------------------------------------------------------------------------
// Popup "Dark theme setting" : Light / Dark / System's theme
// ---------------------------------------------------------------------------

Future<void> showThemePicker(BuildContext context) {
  final current = AppSettings.instance.themeChoice;
  return showFloatingPopup(
    context: context,
    maxWidth: 380,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ThemeRow(
          icon: Icons.wb_sunny_rounded,
          label: S.light,
          selected: current == ThemeChoice.light,
          onTap: () => _pick(context, ThemeChoice.light),
        ),
        _ThemeRow(
          icon: Icons.dark_mode_rounded,
          label: S.dark,
          selected: current == ThemeChoice.dark,
          onTap: () => _pick(context, ThemeChoice.dark),
        ),
        _ThemeRow(
          icon: Icons.contrast_rounded,
          label: S.systemTheme,
          selected: current == ThemeChoice.system,
          onTap: () => _pick(context, ThemeChoice.system),
        ),
      ],
    ),
  );
}

void _pick(BuildContext context, ThemeChoice choice) {
  Navigator.of(context).pop();
  AppSettings.instance.setThemeChoice(choice);
}

class _ThemeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.darkText, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
            _RadioDot(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  const _RadioDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accentGreen : AppColors.darkText;
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 4),
      ),
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Popup "Switch language" : grille de langues + Cancel / Confirm
// ---------------------------------------------------------------------------

Future<void> showLanguagePicker(BuildContext context) {
  var pending = AppSettings.instance.language;

  return showFloatingPopup(
    context: context,
    maxWidth: 400,
    child: StatefulBuilder(
      builder: (context, setLocal) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
              children: [
                for (final lang in appLanguages)
                  _LanguageChip(
                    label: lang.code == 'system' ? S.system : lang.label,
                    selected: pending == lang.code,
                    onTap: () => setLocal(() => pending = lang.code),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _PopupButton(
                    label: S.cancel,
                    background: AppColors.surface,
                    textColor: AppColors.darkText,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PopupButton(
                    label: S.confirm,
                    background: AppColors.accentGreen,
                    textColor: Colors.white,
                    onTap: () {
                      Navigator.of(context).pop();
                      AppSettings.instance.setLanguage(pending);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _LanguageChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentGreen : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.darkText,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _PopupButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  const _PopupButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
