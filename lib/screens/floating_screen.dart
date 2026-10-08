import 'package:flutter/material.dart';
import '../models/floating_settings.dart';
import '../widgets/feature_list_tile.dart';
import 'feature_settings_sheet.dart';
import '../l10n/app_strings.dart';

/// Page "Floating". La liste est générée depuis `featureGroups` /
/// `featureSpecs` (voir models/floating_settings.dart) : toucher une ligne
/// ouvre la feuille de réglages générique par-dessus cette page.
class FloatingScreen extends StatelessWidget {
  const FloatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(4, 4, 4, 32),
      children: [
        for (final entry in featureGroups.entries)
          ..._group(context, entry.key, entry.value),
      ],
    );
  }

  List<Widget> _group(
    BuildContext context,
    String title,
    List<FloatingFeature> features,
  ) {
    return [
      FeatureGroupHeader(title: S.group(title)),
      for (var i = 0; i < features.length; i++) ...[
        if (i > 0) Divider(height: 1),
        FeatureListTile(
          icon: featureSpecs[features[i]]!.icon,
          title: featureSpecs[features[i]]!.title,
          description: featureSpecs[features[i]]!.description,
          onTap: () => showFeatureSettingsSheet(context, features[i]),
        ),
      ],
    ];
  }
}
