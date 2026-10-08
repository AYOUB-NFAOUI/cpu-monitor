import 'dart:io' show Platform;
import 'package:flutter/material.dart';

/// Taille de la fenêtre flottante.
enum FloatingWindowSize { s, m, l, xl, xxl }

extension FloatingWindowSizeX on FloatingWindowSize {
  String get label => switch (this) {
        FloatingWindowSize.s => 'S',
        FloatingWindowSize.m => 'M',
        FloatingWindowSize.l => 'L',
        FloatingWindowSize.xl => 'XL',
        FloatingWindowSize.xxl => 'XXL',
      };

  /// Diamètre approximatif en logical pixels.
  double get diameter => switch (this) {
        FloatingWindowSize.s => 44,
        FloatingWindowSize.m => 56,
        FloatingWindowSize.l => 68,
        FloatingWindowSize.xl => 80,
        FloatingWindowSize.xxl => 92,
      };
}

/// Forme de la fenêtre flottante.
enum FloatingWindowShape { circle, round }

extension FloatingWindowShapeX on FloatingWindowShape {
  String get label => switch (this) {
        FloatingWindowShape.circle => 'Circle',
        FloatingWindowShape.round => 'Round',
      };

  BorderRadius borderRadius(double size) => switch (this) {
        FloatingWindowShape.circle => BorderRadius.circular(size / 2),
        FloatingWindowShape.round => BorderRadius.circular(size * 0.28),
      };
}

/// Fréquence de rafraîchissement des données affichées dans la fenêtre.
enum RefreshRate { half, one, two, five }

extension RefreshRateX on RefreshRate {
  String get label => switch (this) {
        RefreshRate.half => '0.5s',
        RefreshRate.one => '1s',
        RefreshRate.two => '2s',
        RefreshRate.five => '5s',
      };

  Duration get duration => switch (this) {
        RefreshRate.half => const Duration(milliseconds: 500),
        RefreshRate.one => const Duration(seconds: 1),
        RefreshRate.two => const Duration(seconds: 2),
        RefreshRate.five => const Duration(seconds: 5),
      };
}

/// Palette de couleurs proposée pour la fenêtre flottante.
const List<Color> floatingWindowColors = [
  Color(0xFF2B2F38), // sombre (défaut)
  Color(0xFFD9DCE3), // gris clair
  Color(0xFF27C281), // vert
  Color(0xFF3E8BFF), // bleu
  Color(0xFFF5B25B), // orange
  Color(0xFFE879C6), // rose
];

// ---------------------------------------------------------------------------
// Fonctionnalités Floating
// ---------------------------------------------------------------------------

/// Les 13 fonctionnalités de l'onglet Floating. L'ordre de cet enum est
/// aussi l'ordre d'empilement des bulles dans la fenêtre système.
enum FloatingFeature {
  // Cpu Monitor
  cpuTemperature,
  cpuUsage,
  cpuUsageArc,
  cpuPercent,
  cpuPercentArc,
  cpuMultiCore,
  // Battery Monitor
  batteryLevel,
  batteryLevelArc,
  batteryTemperature,
  // System Monitor
  fps,
  systemMonitor,
  memoryInfo,
  memoryUsageArc,
}

/// Description statique d'une fonctionnalité (titre, icône, réglages
/// disponibles dans sa feuille de réglages).
class FeatureSpec {
  final String title;
  final String description;
  final IconData icon;

  /// Affiche la ligne "Floating window Shape".
  final bool hasShape;

  /// Affiche la ligne "High temperature warning".
  final bool hasHighTemp;

  const FeatureSpec({
    required this.title,
    required this.description,
    required this.icon,
    this.hasShape = false,
    this.hasHighTemp = false,
  });
}

const Map<FloatingFeature, FeatureSpec> featureSpecs = {
  FloatingFeature.cpuTemperature: FeatureSpec(
    title: 'Cpu Temperature',
    description: 'Show the cpu temperature curve',
    icon: Icons.autorenew_rounded,
    hasShape: true,
    hasHighTemp: true,
  ),
  FloatingFeature.cpuUsage: FeatureSpec(
    title: 'Cpu Usage',
    description: 'Show the cpu usage curve',
    icon: Icons.show_chart_rounded,
    hasShape: true,
  ),
  FloatingFeature.cpuUsageArc: FeatureSpec(
    title: 'Cpu Usage Arc',
    description: 'Show the cpu usage with arc',
    icon: Icons.donut_large_rounded,
  ),
  FloatingFeature.cpuPercent: FeatureSpec(
    title: 'Cpu Percent',
    description: 'Show the cpu usage percent',
    icon: Icons.grid_view_rounded,
  ),
  FloatingFeature.cpuPercentArc: FeatureSpec(
    title: 'CPU Percent Arc',
    description: 'Show the cpu usage percent with arc',
    icon: Icons.group_work_rounded,
  ),
  FloatingFeature.cpuMultiCore: FeatureSpec(
    title: 'Cpu Multi Core Usage',
    description: 'Show the cpu multi core usage curve',
    icon: Icons.apps_rounded,
  ),
  FloatingFeature.batteryLevel: FeatureSpec(
    title: 'Battery Level',
    description: 'Show the battery level percent',
    icon: Icons.battery_std_rounded,
  ),
  FloatingFeature.batteryLevelArc: FeatureSpec(
    title: 'Battery Level Arc',
    description: 'Show the battery level with arc',
    icon: Icons.bolt_rounded,
  ),
  FloatingFeature.batteryTemperature: FeatureSpec(
    title: 'Battery Temperature',
    description: 'Show the battery temperature curve',
    icon: Icons.device_thermostat_rounded,
    hasShape: true,
    hasHighTemp: true,
  ),
  FloatingFeature.fps: FeatureSpec(
    title: 'FPS Monitor',
    description: 'Show the fps(frames per second) realtime',
    icon: Icons.speed_rounded,
  ),
  FloatingFeature.systemMonitor: FeatureSpec(
    title: 'System Monitor',
    description: 'Show the [cpu] [ram] [battery] info',
    icon: Icons.dashboard_customize_rounded,
  ),
  FloatingFeature.memoryInfo: FeatureSpec(
    title: 'Memory Information',
    description: 'Show the memory usage percent',
    icon: Icons.memory_rounded,
    hasShape: true,
  ),
  FloatingFeature.memoryUsageArc: FeatureSpec(
    title: 'Memory Usage Arc',
    description: 'Show the memory usage with arc',
    icon: Icons.donut_small_rounded,
  ),
};

/// Groupes affichés dans l'écran Floating (dans l'ordre).
const Map<String, List<FloatingFeature>> featureGroups = {
  'Cpu Monitor': [
    FloatingFeature.cpuTemperature,
    FloatingFeature.cpuUsage,
    FloatingFeature.cpuUsageArc,
    FloatingFeature.cpuPercent,
    FloatingFeature.cpuPercentArc,
    FloatingFeature.cpuMultiCore,
  ],
  'Battery Monitor': [
    FloatingFeature.batteryLevel,
    FloatingFeature.batteryLevelArc,
    FloatingFeature.batteryTemperature,
  ],
  'System Monitor': [
    FloatingFeature.fps,
    FloatingFeature.systemMonitor,
    FloatingFeature.memoryInfo,
    FloatingFeature.memoryUsageArc,
  ],
};

// ---------------------------------------------------------------------------
// Géométrie des blocs (partagée entre l'app et la fenêtre système)
// ---------------------------------------------------------------------------

/// Nombre de cœurs utilisés pour les grilles multi-cœurs (limité à 12).
int get overlayCoreCount {
  final n = Platform.numberOfProcessors;
  if (n < 1) return 1;
  if (n > 12) return 12;
  return n;
}

/// Métriques d'une grille (cellules de taille fixe).
class GridMetrics {
  final int cols;
  final int rows;
  final double cellW;
  final double cellH;
  final double gap;
  final double pad;

  const GridMetrics({
    required this.cols,
    required this.rows,
    required this.cellW,
    required this.cellH,
    required this.gap,
    required this.pad,
  });

  double get width => pad * 2 + cols * cellW + (cols - 1) * gap;
  double get height => pad * 2 + rows * cellH + (rows - 1) * gap;
}

extension FloatingFeatureLayout on FloatingFeature {
  /// Grille utilisée par la fonctionnalité, ou null si c'est une bulle simple.
  GridMetrics? gridMetrics(FloatingWindowSize size) {
    final d = size.diameter;
    final n = overlayCoreCount;
    return switch (this) {
      FloatingFeature.cpuPercentArc => GridMetrics(
          cols: 4, rows: (n / 4).ceil(), cellW: d * 0.9, cellH: d * 0.9, gap: 4, pad: 6),
      FloatingFeature.cpuPercent => GridMetrics(
          cols: 2, rows: (n / 2).ceil(), cellW: d * 2.0, cellH: d * 0.34, gap: 4, pad: 8),
      FloatingFeature.cpuMultiCore => GridMetrics(
          cols: 2, rows: (n / 2).ceil(), cellW: d * 1.5, cellH: d * 0.8, gap: 4, pad: 6),
      FloatingFeature.systemMonitor => GridMetrics(
          cols: 3, rows: 1, cellW: d * 0.95, cellH: d * 0.95, gap: 4, pad: 6),
      _ => null,
    };
  }

  /// Taille (en dp) du bloc dessiné dans la fenêtre système.
  Size blockSize(FloatingWindowSize size) {
    final g = gridMetrics(size);
    if (g != null) return Size(g.width, g.height);
    final d = size.diameter;
    return Size(d, d);
  }
}

// ---------------------------------------------------------------------------
// Réglages
// ---------------------------------------------------------------------------

/// Réglages d'UNE fonctionnalité. Ce modèle ne dépend plus d'aucun service :
/// c'est `OverlayService.init()` qui écoute les changements et synchronise
/// la fenêtre système.
class FeatureSettings extends ChangeNotifier {
  final FloatingFeature feature;
  FeatureSettings(this.feature);

  bool enabled = false;
  int highTempWarningC = 60; // 30..80
  Color windowColor = floatingWindowColors.first;
  bool dockToEdge = false;
  double transparencyPercent = 40; // 0..100
  FloatingWindowSize size = FloatingWindowSize.m;
  FloatingWindowShape shape = FloatingWindowShape.circle;
  RefreshRate refreshRate = RefreshRate.two;

  void setEnabled(bool value) {
    enabled = value;
    notifyListeners();
  }

  void setHighTempWarning(int value) {
    highTempWarningC = value < 30 ? 30 : (value > 80 ? 80 : value);
    notifyListeners();
  }

  void setWindowColor(Color value) {
    windowColor = value;
    notifyListeners();
  }

  void setDockToEdge(bool value) {
    dockToEdge = value;
    notifyListeners();
  }

  void setTransparency(double value) {
    transparencyPercent = value < 0 ? 0 : (value > 100 ? 100 : value);
    notifyListeners();
  }

  void setSize(FloatingWindowSize value) {
    size = value;
    notifyListeners();
  }

  void setShape(FloatingWindowShape value) {
    shape = value;
    notifyListeners();
  }

  void setRefreshRate(RefreshRate value) {
    refreshRate = value;
    notifyListeners();
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'highTemp': highTempWarningC,
        'color': windowColor.toARGB32(),
        'dock': dockToEdge,
        'transparency': transparencyPercent,
        'size': size.index,
        'shape': shape.index,
        'refresh': refreshRate.index,
      };

  /// Applique une config (venant de SharedPreferences ou de shareData).
  /// Les valeurs absentes ou invalides sont ignorées.
  void applyJson(Map<String, dynamic> j) {
    enabled = j['enabled'] as bool? ?? enabled;
    highTempWarningC = (j['highTemp'] as num?)?.toInt() ?? highTempWarningC;
    final c = j['color'] as num?;
    if (c != null) windowColor = Color(c.toInt());
    dockToEdge = j['dock'] as bool? ?? dockToEdge;
    transparencyPercent =
        (j['transparency'] as num?)?.toDouble() ?? transparencyPercent;

    final si = (j['size'] as num?)?.toInt();
    if (si != null && si >= 0 && si < FloatingWindowSize.values.length) {
      size = FloatingWindowSize.values[si];
    }
    final sh = (j['shape'] as num?)?.toInt();
    if (sh != null && sh >= 0 && sh < FloatingWindowShape.values.length) {
      shape = FloatingWindowShape.values[sh];
    }
    final rr = (j['refresh'] as num?)?.toInt();
    if (rr != null && rr >= 0 && rr < RefreshRate.values.length) {
      refreshRate = RefreshRate.values[rr];
    }
    notifyListeners();
  }
}

/// Registre unique : un objet de réglages par fonctionnalité.
final Map<FloatingFeature, FeatureSettings> floatingSettings = {
  for (final f in FloatingFeature.values) f: FeatureSettings(f),
};

FeatureSettings settingsOf(FloatingFeature f) => floatingSettings[f]!;

// Compatibilité avec l'ancien code (si vous gardez les anciennes sheets).
typedef CpuTemperatureSettings = FeatureSettings;
typedef CpuUsageSettings = FeatureSettings;
final cpuTemperatureSettings = settingsOf(FloatingFeature.cpuTemperature);
final cpuUsageSettings = settingsOf(FloatingFeature.cpuUsage);
