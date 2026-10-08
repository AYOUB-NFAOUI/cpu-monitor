import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// Base commune : petite boîte blanche arrondie, centrée à l'écran, avec
/// une ombre douce - reproduit le style des popups des maquettes (images
/// "0.5s/1s/2s/5s", "Circle/Round", "Yes/No"...).
Future<T?> showFloatingPopup<T>({
  required BuildContext context,
  required Widget child,
  double maxWidth = 340,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'dismiss',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: Duration(milliseconds: 180),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 28),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dialogBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim, secondary, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

/// Popup "liste" : une option par ligne, l'option sélectionnée est mise en
/// évidence en vert avec une coche. Utilisé pour "Data refresh rate",
/// "Floating window Shape", "Automatically dock to the edge" (Yes/No)...
Future<void> showListPicker<T>({
  required BuildContext context,
  required List<T> options,
  required T selected,
  required String Function(T) labelBuilder,
  required ValueChanged<T> onSelected,
}) {
  return showFloatingPopup(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        final isSelected = option == selected;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: _PickerRow(
            label: labelBuilder(option),
            selected: isSelected,
            onTap: () {
              onSelected(option);
              Navigator.of(context).pop();
            },
          ),
        );
      }).toList(),
    ),
  );
}

class _PickerRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickerRow({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentGreen : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.tr(label),
              style: TextStyle(
                color: selected ? Colors.white : AppColors.darkText,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (selected) Icon(Icons.check_rounded, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Popup "couleurs" : une seule ligne de pastilles colorées (image
/// "Floating window color").
Future<void> showColorRowPicker({
  required BuildContext context,
  required List<Color> options,
  required Color selected,
  required ValueChanged<Color> onSelected,
}) {
  return showFloatingPopup(
    context: context,
    maxWidth: 380,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options.map((color) {
          final isSelected = color == selected;
          return GestureDetector(
            onTap: () {
              onSelected(color);
              Navigator.of(context).pop();
            },
            child: Container(
              width: 40,
              height: 40,
              margin: EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: isSelected ? Border.all(color: AppColors.accentGreen, width: 3) : null,
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

/// Popup "segments" : une seule ligne de pilules (image "S / M / L / XL / XXL").
Future<void> showSegmentedPicker<T>({
  required BuildContext context,
  required List<T> options,
  required T selected,
  required String Function(T) labelBuilder,
  required ValueChanged<T> onSelected,
}) {
  return showFloatingPopup(
    context: context,
    maxWidth: 420,
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options.map((option) {
          final isSelected = option == selected;
          return GestureDetector(
            onTap: () {
              onSelected(option);
              Navigator.of(context).pop();
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: 150),
              width: 46,
              height: 46,
              alignment: Alignment.center,
              margin: EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentGreen : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Text(
                labelBuilder(option),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.darkText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

/// Popup "slider" : barre de progression glissable (image "Floating window
/// transparency"). La valeur est appliquée en direct pendant le glissement.
Future<void> showSliderPicker({
  required BuildContext context,
  required double value,
  double min = 0,
  double max = 100,
  required ValueChanged<double> onChanged,
}) {
  return showFloatingPopup(
    context: context,
    maxWidth: 380,
    child: StatefulBuilder(
      builder: (context, setLocalState) {
        // variable locale pour que le slider se mette à jour visuellement
        double localValue = value;
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: StatefulBuilder(
            builder: (context, setInnerState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 22,
                      activeTrackColor: AppColors.pillDark,
                      inactiveTrackColor: AppColors.trackGrey,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 11),
                      thumbColor: Colors.white,
                      overlayColor: AppColors.pillDark.withValues(alpha: 0.12),
                      trackShape: _CapsuleTrackShape(),
                    ),
                    child: Slider(
                      value: localValue,
                      min: min,
                      max: max,
                      onChanged: (v) {
                        setInnerState(() => localValue = v);
                        onChanged(v);
                      },
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '${localValue.toStringAsFixed(0)}%',
                    style: TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            },
          ),
        );
      },
    ),
  );
}

class _CapsuleTrackShape extends RoundedRectSliderTrackShape {
  const _CapsuleTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 22;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}

/// Dialogue numérique avec explication + Cancel/OK (image "High temperature
/// warning").
Future<void> showNumberInputDialog({
  required BuildContext context,
  required String description,
  required int value,
  required int min,
  required int max,
  required ValueChanged<int> onConfirm,
}) {
  final controller = TextEditingController(text: '$value');
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.tr(description),
                style: TextStyle(color: AppColors.darkText, fontSize: 15, height: 1.35),
              ),
              SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: S.cancel,
                      background: AppColors.surface,
                      textColor: AppColors.darkText,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _DialogButton(
                      label: 'OK',
                      background: AppColors.accentGreen,
                      textColor: Colors.white,
                      onTap: () {
                        final parsed = int.tryParse(controller.text.trim());
                        if (parsed != null) {
                          onConfirm(parsed.clamp(min, max));
                        }
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  const _DialogButton({
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
        padding: EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(14)),
        child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

/// Petit dialogue d'information générique (image "Floating window
/// disappear?").
Future<void> showInfoDialog({
  required BuildContext context,
  required String title,
  required String message,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(S.tr(title),
                  style: TextStyle(
                      color: AppColors.accentGreen, fontWeight: FontWeight.w800, fontSize: 16)),
              SizedBox(height: 10),
              Text(S.tr(message), style: TextStyle(color: AppColors.darkText, height: 1.4)),
              SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: _DialogButton(
                  label: S.tr('Got it'),
                  background: AppColors.accentGreen,
                  textColor: Colors.white,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
