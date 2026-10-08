import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../l10n/app_strings.dart';

/// Une ligne "icône + titre + description + chevron", comme chaque item de
/// la page Floating (Cpu Temperature, Cpu Usage, Battery Level...).
class FeatureListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const FeatureListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.darkText, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.tr(title),
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    S.tr(description),
                    style: TextStyle(color: AppColors.mutedText, fontSize: 13),
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

/// En-tête de groupe ("Cpu Monitor", "Battery Monitor", "System Monitor")
/// avec un séparateur en dessous, comme dans les maquettes.
class FeatureGroupHeader extends StatelessWidget {
  final String title;
  const FeatureGroupHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 18, bottom: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.accentGreen,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(width: 10),
          Text(
            S.tr(title),
            style: TextStyle(
              color: AppColors.darkText,
              fontWeight: FontWeight.w800,
              fontSize: 19,
            ),
          ),
        ],
      ),
    );
  }
}
