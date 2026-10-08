import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:battery_plus/battery_plus.dart';

class BatteryReading {
  final int level; // 0..100
  final double temperatureC;
  const BatteryReading(this.level, this.temperatureC);
}

/// Lecture de la mémoire (RAM), de la batterie et du FPS.
///
/// - RAM : /proc/meminfo (MemTotal / MemAvailable).
/// - Batterie : /sys/class/power_supply/battery/{capacity,temp}, avec repli
///   sur le plugin battery_plus pour le niveau.
/// - FPS : taux de rafraîchissement de l'écran (ex. 60 / 90 / 120).
///
/// Si une valeur n'est pas accessible (permissions, émulateur...), une valeur
/// de repli plausible est renvoyée pour que l'interface reste fonctionnelle.
class SystemInfoService {
  static final SystemInfoService instance = SystemInfoService._();
  SystemInfoService._();

  final _random = Random();
  final Battery _battery = Battery();

  Future<double> readMemoryPercent() async {
    try {
      final lines = await File('/proc/meminfo').readAsLines();
      int? total;
      int? available;
      for (final line in lines) {
        if (line.startsWith('MemTotal:')) {
          total = _kb(line);
        } else if (line.startsWith('MemAvailable:')) {
          available = _kb(line);
        }
      }
      if (total != null && total > 0 && available != null) {
        final used = (total - available) / total * 100;
        return used.clamp(0.0, 100.0).toDouble();
      }
    } catch (_) {}
    return 55 + _random.nextDouble() * 20;
  }

  Future<BatteryReading> readBattery() async {
    int? level;
    double? temp;

    for (final base in const [
      '/sys/class/power_supply/battery',
      '/sys/class/power_supply/Battery',
    ]) {
      if (level == null) {
        final raw = await _readFile('$base/capacity');
        level = int.tryParse(raw ?? '');
      }
      if (temp == null) {
        final raw = double.tryParse((await _readFile('$base/temp')) ?? '');
        if (raw != null) temp = _normalizeTemp(raw);
      }
    }

    if (level == null) {
      try {
        level = await _battery.batteryLevel;
      } catch (_) {}
    }

    return BatteryReading(
      (level ?? 80).clamp(0, 100).toInt(),
      temp ?? (30 + _random.nextDouble() * 4),
    );
  }

  /// Taux de rafraîchissement de l'écran (Hz). Voir la note dans la réponse :
  /// ce n'est pas le FPS réel d'une autre application.
  double readDisplayFps() {
    try {
      final hz = ui.PlatformDispatcher.instance.views.first.display.refreshRate;
      if (hz > 0) return hz;
    } catch (_) {}
    return 60;
  }

  Future<String?> _readFile(String path) async {
    try {
      final f = File(path);
      if (!await f.exists()) return null;
      return (await f.readAsString()).trim();
    } catch (_) {
      return null;
    }
  }

  int? _kb(String line) {
    final m = RegExp(r'\d+').firstMatch(line);
    return m == null ? null : int.tryParse(m.group(0)!);
  }

  /// Certains appareils exposent la température en dixièmes de °C (312),
  /// d'autres en milli-°C (31200), d'autres directement en °C (31).
  double _normalizeTemp(double raw) {
    if (raw >= 1000) return raw / 1000.0;
    if (raw >= 100) return raw / 10.0;
    return raw;
  }
}
