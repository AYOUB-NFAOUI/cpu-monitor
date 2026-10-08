import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/floating_settings.dart';
import '../services/cpu_info_service.dart';
import '../services/overlay_service.dart';
import '../services/system_info_service.dart';

/// Point d'entrée de la fenêtre flottante SYSTÈME (moteur Flutter séparé).
/// Il ne partage aucune mémoire avec `main.dart` :
/// - au démarrage, il relit la config via SharedPreferences ;
/// - ensuite il reçoit les changements via `overlayListener` ;
/// - il lit lui-même CPU / RAM / batterie / FPS.
///
/// NB : `overlayMain` (@pragma('vm:entry-point')) est défini dans `main.dart`.
void runOverlayApp() {
  runApp(const _OverlayApp());
}

class _OverlayApp extends StatelessWidget {
  const _OverlayApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.transparent,
        child: _OverlayBody(),
      ),
    );
  }
}

/// Dernières mesures connues.
class _Metrics {
  double cpuTemp = 0;
  double cpuAvg = 0;
  List<double> perCore = const [];
  List<List<double>> coreHistory = [];
  double mem = 0;
  int battery = 0;
  double batteryTemp = 0;
  double fps = 60;
}

const Set<FloatingFeature> _cpuFeatures = {
  FloatingFeature.cpuTemperature,
  FloatingFeature.cpuUsage,
  FloatingFeature.cpuUsageArc,
  FloatingFeature.cpuPercent,
  FloatingFeature.cpuPercentArc,
  FloatingFeature.cpuMultiCore,
  FloatingFeature.systemMonitor,
};
const Set<FloatingFeature> _memFeatures = {
  FloatingFeature.memoryInfo,
  FloatingFeature.memoryUsageArc,
  FloatingFeature.systemMonitor,
};
const Set<FloatingFeature> _batteryFeatures = {
  FloatingFeature.batteryLevel,
  FloatingFeature.batteryLevelArc,
  FloatingFeature.batteryTemperature,
  FloatingFeature.systemMonitor,
};

class _OverlayBody extends StatefulWidget {
  const _OverlayBody();

  @override
  State<_OverlayBody> createState() => _OverlayBodyState();
}

class _OverlayBodyState extends State<_OverlayBody> {
  final _cpu = CpuInfoService.instance;
  final _sys = SystemInfoService.instance;
  final _m = _Metrics();

  Timer? _pollTimer;
  Duration _period = const Duration(seconds: 2);
  bool _polling = false;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FlutterOverlayWindow.overlayListener.listen(_onData);
    _loadPersistedConfig();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPersistedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(OverlayService.prefsKey);
      if (raw != null) {
        _applyConfig(jsonDecode(raw) as Map<String, dynamic>);
        return;
      }
    } catch (_) {}
    _restartTimer();
  }

  void _onData(dynamic event) {
    try {
      final map = event is String ? jsonDecode(event) : event;
      if (map is Map) _applyConfig(Map<String, dynamic>.from(map));
    } catch (_) {}
  }

  void _applyConfig(Map<String, dynamic> map) {
    if (!mounted) return;
    for (final f in FloatingFeature.values) {
      final j = map[f.name];
      if (j is Map) settingsOf(f).applyJson(Map<String, dynamic>.from(j));
    }
    setState(() {});
    _restartTimer();
  }

  /// Le timer suit la fréquence la plus rapide parmi les fonctionnalités
  /// activées, et s'arrête si aucune n'est activée.
  void _restartTimer() {
    var period = const Duration(seconds: 5);
    var any = false;
    for (final f in FloatingFeature.values) {
      final s = settingsOf(f);
      if (!s.enabled) continue;
      any = true;
      if (s.refreshRate.duration < period) period = s.refreshRate.duration;
    }
    if (!any) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    if (_pollTimer != null && period == _period) return;
    _period = period;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(period, (_) => _poll());
    _poll();
  }

  bool _needs(Set<FloatingFeature> features) =>
      features.any((f) => settingsOf(f).enabled);

  Future<void> _poll() async {
    if (_polling) return;
    _polling = true;
    try {
      double? cpuTemp;
      double? cpuAvg;
      List<double>? perCore;
      double? mem;
      BatteryReading? battery;
      double? fps;

      if (_needs(_cpuFeatures)) {
        final snapshot = await _cpu.readSnapshot();
        final usage = estimateUsage(snapshot);
        cpuTemp = snapshot.temperatureC;
        cpuAvg = usage.averagePercent;
        perCore = usage.perCorePercent;
      }
      if (_needs(_memFeatures)) mem = await _sys.readMemoryPercent();
      if (_needs(_batteryFeatures)) battery = await _sys.readBattery();
      if (settingsOf(FloatingFeature.fps).enabled) fps = _sys.readDisplayFps();

      if (!mounted) return;
      setState(() {
        if (cpuTemp != null) _m.cpuTemp = cpuTemp;
        if (cpuAvg != null) _m.cpuAvg = cpuAvg;
        if (perCore != null) {
          _m.perCore = perCore;
          while (_m.coreHistory.length < perCore.length) {
            _m.coreHistory.add(<double>[]);
          }
          for (var i = 0; i < perCore.length; i++) {
            _m.coreHistory[i] =
                _cpu.pushHistory(_m.coreHistory[i], perCore[i], length: 20);
          }
        }
        if (mem != null) _m.mem = mem;
        if (battery != null) {
          _m.battery = battery.level;
          _m.batteryTemp = battery.temperatureC;
        }
        if (fps != null) _m.fps = fps;
      });
    } catch (_) {
      // On garde les dernières valeurs.
    } finally {
      _polling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    for (final f in FloatingFeature.values) {
      final s = settingsOf(f);
      if (!s.enabled) continue;
      if (blocks.isNotEmpty) blocks.add(const SizedBox(height: 8));
      blocks.add(_FeatureBlock(feature: f, settings: s, metrics: _m));
    }
    if (blocks.isEmpty) return const SizedBox.shrink();

    // FittedBox : si la fenêtre est plus petite que le contenu (écran étroit,
    // taille XXL...), tout est réduit proportionnellement au lieu d'être coupé.
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(mainAxisSize: MainAxisSize.min, children: blocks),
      ),
    );
  }
}

const Color _darkText = Color(0xFF2B2F38);
const Color _warningRed = Color(0xFFE5484D);

/// Un bloc = une fonctionnalité (bulle simple ou grille).
class _FeatureBlock extends StatelessWidget {
  final FloatingFeature feature;
  final FeatureSettings settings;
  final _Metrics metrics;

  const _FeatureBlock({
    required this.feature,
    required this.settings,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final spec = featureSpecs[feature]!;
    final size = feature.blockSize(s.size);
    final d = s.size.diameter;

    final tempValue = feature == FloatingFeature.batteryTemperature
        ? metrics.batteryTemp
        : metrics.cpuTemp;
    final hot = spec.hasHighTemp && tempValue >= s.highTempWarningC;
    final color = hot ? _warningRed : s.windowColor;
    final fg = color.computeLuminance() > 0.6 ? _darkText : Colors.white;

    final grid = feature.gridMetrics(s.size);
    final circle = switch (feature) {
      FloatingFeature.cpuUsageArc ||
      FloatingFeature.batteryLevelArc ||
      FloatingFeature.memoryUsageArc =>
        true,
      FloatingFeature.cpuTemperature ||
      FloatingFeature.cpuUsage ||
      FloatingFeature.batteryTemperature ||
      FloatingFeature.memoryInfo =>
        s.shape == FloatingWindowShape.circle,
      _ => false,
    };

    final BorderRadius radius;
    if (feature == FloatingFeature.systemMonitor) {
      radius = BorderRadius.circular(size.height / 2);
    } else if (grid != null) {
      radius = BorderRadius.circular(18);
    } else if (spec.hasShape) {
      radius = s.shape.borderRadius(d);
    } else {
      radius = FloatingWindowShape.round.borderRadius(d);
    }

    final opacity =
        ((100 - s.transparencyPercent) / 100).clamp(0.25, 1.0).toDouble();

    return Opacity(
      opacity: opacity,
      child: Container(
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : radius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.16),
            width: math.min(3.0, size.shortestSide * 0.04),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _content(fg, d, grid),
        ),
      ),
    );
  }

  double _core(int i) => i < metrics.perCore.length ? metrics.perCore[i] : 0.0;

  Widget _content(Color fg, double d, GridMetrics? g) {
    final m = metrics;
    return switch (feature) {
      FloatingFeature.cpuTemperature => _label('${m.cpuTemp.round()}°', fg, d),
      FloatingFeature.cpuUsage => _label('${m.cpuAvg.round()}%', fg, d),
      FloatingFeature.cpuUsageArc => _ArcGauge(
          size: d * 0.82, value: m.cpuAvg, color: fg, icon: Icons.memory_rounded),
      FloatingFeature.cpuPercent => _percentBars(g!, fg),
      FloatingFeature.cpuPercentArc => _buildGrid(
          g!,
          overlayCoreCount,
          (i) => _ArcGauge(size: g.cellW, value: _core(i), color: fg),
        ),
      FloatingFeature.cpuMultiCore => _buildGrid(
          g!,
          overlayCoreCount,
          (i) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: fg.withValues(alpha: 0.10),
              child: CustomPaint(
                size: Size.infinite,
                painter: _MiniChartPainter(
                  values: i < m.coreHistory.length ? m.coreHistory[i] : const [],
                  color: fg,
                ),
              ),
            ),
          ),
        ),
      FloatingFeature.batteryLevel => _label('${m.battery}', fg, d),
      FloatingFeature.batteryLevelArc => _ArcGauge(
          size: d * 0.82,
          value: m.battery.toDouble(),
          color: fg,
          icon: Icons.bolt_rounded),
      FloatingFeature.batteryTemperature =>
        _label('${m.batteryTemp.round()}°', fg, d),
      FloatingFeature.fps => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'fps',
              style: TextStyle(
                color: fg.withValues(alpha: 0.8),
                fontSize: d * 0.20,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
            SizedBox(height: d * 0.03),
            Text(
              '${m.fps.round()}',
              softWrap: false,
              style: TextStyle(
                color: fg,
                fontSize: d * 0.34,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ],
        ),
      FloatingFeature.systemMonitor => _buildGrid(
          g!,
          3,
          (i) => switch (i) {
            0 => _ArcGauge(
                size: g.cellW, value: m.cpuAvg, color: fg, icon: Icons.memory_rounded),
            1 => _ArcGauge(
                size: g.cellW, value: m.mem, color: fg, icon: Icons.storage_rounded),
            _ => _ArcGauge(
                size: g.cellW,
                value: m.battery.toDouble(),
                color: fg,
                icon: Icons.bolt_rounded),
          },
        ),
      FloatingFeature.memoryInfo => Text.rich(
          TextSpan(
            text: '${m.mem.round()}',
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w800,
              fontSize: d * 0.30,
              height: 1.0,
            ),
            children: [
              TextSpan(
                text: '%',
                style: TextStyle(fontSize: d * 0.18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          softWrap: false,
        ),
      FloatingFeature.memoryUsageArc => _ArcGauge(
          size: d * 0.82,
          value: m.mem,
          color: fg,
          icon: Icons.storage_rounded),
    };
  }

  Widget _label(String text, Color fg, double d) {
    return Padding(
      padding: EdgeInsets.all(d * 0.10),
      child: Text(
        text,
        softWrap: false,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: d * 0.30,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _percentBars(GridMetrics g, Color fg) {
    return _buildGrid(g, overlayCoreCount, (i) {
      final v = _core(i);
      return Row(
        children: [
          Expanded(
            child: _Bar(value: v / 100, color: fg, height: g.cellH * 0.55),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: g.cellW * 0.30,
            child: Text(
              '${v.round()}%',
              textAlign: TextAlign.right,
              softWrap: false,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: g.cellH * 0.62,
                height: 1.0,
              ),
            ),
          ),
        ],
      );
    });
  }
}

/// Grille de cellules de taille fixe (mêmes dimensions que `GridMetrics`).
Widget _buildGrid(GridMetrics g, int count, Widget Function(int i) cell) {
  final rows = <Widget>[];
  for (var r = 0; r < g.rows; r++) {
    final cells = <Widget>[];
    for (var c = 0; c < g.cols; c++) {
      final i = r * g.cols + c;
      if (c > 0) cells.add(SizedBox(width: g.gap));
      cells.add(
        SizedBox(
          width: g.cellW,
          height: g.cellH,
          child: i < count ? cell(i) : null,
        ),
      );
    }
    if (r > 0) rows.add(SizedBox(height: g.gap));
    rows.add(Row(mainAxisSize: MainAxisSize.min, children: cells));
  }
  return Padding(
    padding: EdgeInsets.all(g.pad),
    child: Column(mainAxisSize: MainAxisSize.min, children: rows),
  );
}

/// Barre de progression horizontale (Cpu Percent).
class _Bar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;

  const _Bar({required this.value, required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    final f = value.clamp(0.0, 1.0).toDouble();
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        widthFactor: f,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    );
  }
}

/// Jauge en arc (270°) avec icône optionnelle et valeur.
class _ArcGauge extends StatelessWidget {
  final double size;
  final double value; // 0..100
  final Color color;
  final IconData? icon;

  const _ArcGauge({
    required this.size,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final hasIcon = icon != null;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _ArcPainter(
              fraction: value / 100,
              color: color,
              stroke: size * 0.11,
            ),
          ),
          if (hasIcon)
            Align(
              alignment: const Alignment(0, -0.22),
              child: Icon(icon, size: size * 0.30, color: color),
            ),
          Align(
            alignment: Alignment(0, hasIcon ? 0.60 : 0.0),
            child: Text(
              value.round().toString(),
              softWrap: false,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: size * (hasIcon ? 0.22 : 0.30),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double fraction;
  final Color color;
  final double stroke;

  const _ArcPainter({
    required this.fraction,
    required this.color,
    required this.stroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2 + size.width * 0.06);
    const start = 0.75 * math.pi;
    const sweep = 1.5 * math.pi;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.30);
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect, start, sweep, false, track);
    final f = fraction.clamp(0.0, 1.0).toDouble();
    if (f > 0) canvas.drawArc(rect, start, sweep * f, false, progress);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.fraction != fraction || old.color != color || old.stroke != stroke;
}

/// Mini courbe quadrillée (Cpu Multi Core Usage). Valeurs attendues : 0..100.
class _MiniChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;

  const _MiniChartPainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..strokeWidth = 0.6;
    const step = 5.0;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    if (values.length < 2) return;
    final stepX = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final n = (values[i] / 100).clamp(0.0, 1.0).toDouble();
      final x = i * stepX;
      final y = size.height - n * size.height * 0.9 - size.height * 0.05;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _MiniChartPainter old) =>
      old.values != values || old.color != color;
}
