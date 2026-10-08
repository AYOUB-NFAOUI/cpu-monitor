import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// Reproduit l'en-tête de section vu sur les maquettes :
/// une pastille verte verticale de chaque côté du titre.
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _pill(),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              S.tr(title),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
            ),
          ),
          if (trailing != null) trailing!,
          SizedBox(width: 10),
          _pill(),
        ],
      ),
    );
  }

  Widget _pill() => Container(
        width: 6,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.accentGreen,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

/// Ligne clé/valeur utilisée pour "Cpu Hardware", "Cpu Cores", etc.
/// [valueColor] permet de changer la couleur de la valeur (par défaut vert),
/// par exemple pour afficher "No" en sombre dans "Hardware Supported".
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;
  final Color? valueColor;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.multiline = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? AppColors.accentGreen;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: multiline
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labelRow(context),
                SizedBox(height: 4),
                Text(
                  S.tr(value),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _labelRow(context),
                SizedBox(width: 12),
                Flexible(
                  child: Text(
                    S.tr(value),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _labelRow(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: AppColors.trackGrey,
            shape: BoxShape.circle,
          ),
        ),
        Text(S.tr(label), style: TextStyle(color: AppColors.darkText, fontSize: 15)),
      ],
    );
  }
}

/// Bouton de navigation type "onglet arrondi" (Cpu / Floating / System).
class TopTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const TopTab({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.pillDark : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : AppColors.darkText),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
