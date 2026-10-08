import 'package:flutter/material.dart';
import '../services/device_details_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

/// Onglet "System" : quatre sections reprenant les maquettes
/// (appareil, System Information, Screen Information, Hardware Supported).
class SystemScreen extends StatefulWidget {
  const SystemScreen({super.key});

  @override
  State<SystemScreen> createState() => _SystemScreenState();
}

class _SystemScreenState extends State<SystemScreen> {
  late final Future<DeviceDetails> _future = DeviceDetailsService.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeviceDetails>(
      future: _future,
      builder: (context, snapshot) {
        final d = snapshot.data;
        if (d == null) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primaryGreen),
          );
        }
        return ListView(
          padding: EdgeInsets.only(bottom: 32),
          children: [
            // ---------- Appareil ----------
            SectionHeader(title: d.title),
            InfoRow(label: 'Model', value: d.model),
            InfoRow(label: 'Manufacturer', value: d.manufacturer),
            InfoRow(label: 'Brand', value: d.brand),
            InfoRow(label: 'Hardware', value: d.hardware),
            InfoRow(label: 'Device', value: d.device),
            InfoRow(label: 'Board', value: d.board),

            // ---------- System Information ----------
            SizedBox(height: 22),
            SectionHeader(title: 'System Information'),
            InfoRow(label: 'Version Name', value: d.versionName),
            InfoRow(label: 'Api Level', value: d.apiLevel),
            InfoRow(label: 'Build Number', value: d.buildNumber),
            InfoRow(label: 'Build ID', value: d.buildId),
            InfoRow(label: 'Security Patch Level', value: d.securityPatch),
            InfoRow(label: 'Language', value: d.language),
            InfoRow(label: d.vmLabel, value: d.vm),
            InfoRow(label: 'Time Zone', value: d.timeZone, multiline: true),
            InfoRow(label: 'Kernel Version', value: d.kernel, multiline: true),

            // ---------- Screen Information ----------
            SizedBox(height: 22),
            SectionHeader(title: 'Screen Information'),
            InfoRow(label: 'Screen Resolution', value: d.resolution),
            InfoRow(label: 'Screen Dpi', value: d.dpi),
            InfoRow(label: 'Screen Density', value: d.density),
            InfoRow(label: 'Screen Size', value: d.screenSize),
            InfoRow(label: 'Aspect Ratio', value: d.aspectRatio),
            InfoRow(label: 'Display bucket', value: d.displayBucket),
            InfoRow(label: 'Refresh Rate', value: d.refreshRate),
            InfoRow(
              label: 'Supported Refresh Rate',
              value: d.supportedRefreshRate,
              multiline: true,
            ),
            InfoRow(label: 'HDR', value: d.hdr, multiline: true),

            // ---------- Hardware Supported ----------
            SizedBox(height: 22),
            SectionHeader(title: 'Hardware Supported'),
            for (final entry in d.hardwareSupported)
              InfoRow(
                label: entry.key,
                value: entry.value ? 'Yes' : 'No',
                valueColor: entry.value ? null : AppColors.darkText,
              ),
          ],
        );
      },
    );
  }
}
