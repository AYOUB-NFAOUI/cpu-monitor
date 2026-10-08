import 'package:flutter/material.dart';
import '../models/floating_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/picker_sheets.dart';
import '../l10n/app_strings.dart';

/// Feuille de réglages générique, utilisée par TOUTES les fonctionnalités
/// de l'onglet Floating (Cpu Temperature, Cpu Usage, arcs, batterie, FPS...).
/// Les lignes affichées dépendent de [FeatureSpec] :
/// - `hasHighTemp` -> "High temperature warning"
/// - `hasShape`    -> "Floating window Shape"
Future<void> showFeatureSettingsSheet(
  BuildContext context,
  FloatingFeature feature,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    builder: (context) => _FeatureSheet(feature: feature),
  );
}

class _FeatureSheet extends StatelessWidget {
  final FloatingFeature feature;
  const _FeatureSheet({required this.feature});

  @override
  Widget build(BuildContext context) {
    final s = settingsOf(feature);
    final spec = featureSpecs[feature]!;

    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        return DraggableScrollableSheet(
          initialChildSize: spec.hasHighTemp ? 0.86 : (spec.hasShape ? 0.8 : 0.72),
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(18, 14, 18, 32),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.trackGrey,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  _headerCard(spec, s),
                  SizedBox(height: 14),
                  _settingsCard(context, spec, s),
                  SizedBox(height: 14),
                  _disappearCard(context),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _headerCard(FeatureSpec spec, FeatureSettings s) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(spec.icon, color: AppColors.darkText),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.tr(spec.title),
                  style: TextStyle(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  S.tr(spec.description),
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: s.enabled,
            activeThumbColor: AppColors.accentGreen,
            onChanged: s.setEnabled,
          ),
        ],
      ),
    );
  }

  Widget _settingsCard(BuildContext context, FeatureSpec spec, FeatureSettings s) {
    final rows = <Widget>[
      if (spec.hasHighTemp)
        _row(
          label: 'High temperature warning',
          value: '${s.highTempWarningC}°C',
          onTap: () => showNumberInputDialog(
            context: context,
            description:
                'When the temperature exceeds the set threshold, the floating window '
                'color will turn red and display a high-temperature alert. Threshold '
                'in the range of 30 celsius to 80 celsius',
            value: s.highTempWarningC,
            min: 30,
            max: 80,
            onConfirm: s.setHighTempWarning,
          ),
        ),
      _row(
        label: 'Floating window color',
        valueWidget: Container(
          width: 44,
          height: 26,
          decoration: BoxDecoration(
            color: s.windowColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onTap: () => showColorRowPicker(
          context: context,
          options: floatingWindowColors,
          selected: s.windowColor,
          onSelected: s.setWindowColor,
        ),
      ),
      _row(
        label: 'Automatically dock to the edge',
        value: s.dockToEdge ? 'Yes' : 'No',
        onTap: () => showListPicker<bool>(
          context: context,
          options: [true, false],
          selected: s.dockToEdge,
          labelBuilder: (v) => v ? 'Yes' : 'No',
          onSelected: s.setDockToEdge,
        ),
      ),
      _row(
        label: 'Floating window transparency',
        value: '${s.transparencyPercent.toStringAsFixed(0)}%',
        onTap: () => showSliderPicker(
          context: context,
          value: s.transparencyPercent,
          onChanged: s.setTransparency,
        ),
      ),
      _row(
        label: 'Floating window size',
        value: s.size.label,
        onTap: () => showSegmentedPicker<FloatingWindowSize>(
          context: context,
          options: FloatingWindowSize.values,
          selected: s.size,
          labelBuilder: (v) => v.label,
          onSelected: s.setSize,
        ),
      ),
      if (spec.hasShape)
        _row(
          label: 'Floating window Shape',
          value: s.shape.label,
          onTap: () => showListPicker<FloatingWindowShape>(
            context: context,
            options: FloatingWindowShape.values,
            selected: s.shape,
            labelBuilder: (v) => v.label,
            onSelected: s.setShape,
          ),
        ),
      _row(
        label: 'Data refresh rate',
        value: s.refreshRate.label,
        isLast: true,
        onTap: () => showListPicker<RefreshRate>(
          context: context,
          options: RefreshRate.values,
          selected: s.refreshRate,
          labelBuilder: (v) => v.label,
          onSelected: s.setRefreshRate,
        ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(children: rows),
    );
  }

  Widget _row({
    required String label,
    String? value,
    Widget? valueWidget,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: AppColors.mutedText,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    S.tr(label),
                    style: TextStyle(color: AppColors.darkText, fontSize: 14.5),
                  ),
                ),
                if (valueWidget != null)
                  valueWidget
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      S.tr(value ?? ''),
                      style: TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isLast) Divider(height: 1, color: AppColors.background),
        ],
      ),
    );
  }

  Widget _disappearCard(BuildContext context) {
    return InkWell(
      onTap: () => showInfoDialog(
        context: context,
        title: 'Floating window disappear ?',
        message:
            'On some phones (MIUI, ColorOS, EMUI...), the system may close floating windows automatically to save battery. Allow display over other apps and disable battery optimization for this app in the system settings so the window stays active in the background.',
      ),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.help_outline_rounded, color: AppColors.darkText),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.tr('Floating window disappear ?'),
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    S.tr('Floating window may close due to system restrictions. Click to optimize.'),
                    style: TextStyle(color: AppColors.darkText, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }
}
