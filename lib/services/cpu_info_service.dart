import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Représente une lecture instantanée du CPU (une valeur par cœur).
class CpuSnapshot {
  final List<double> frequenciesMhz; // fréquence actuelle par cœur
  final List<double> minFreqMhz; // fréquence min par cœur
  final List<double> maxFreqMhz; // fréquence max par cœur
  final double temperatureC;

  CpuSnapshot({
    required this.frequenciesMhz,
    required this.minFreqMhz,
    required this.maxFreqMhz,
    required this.temperatureC,
  });
}

class HardwareInfo {
  final String cpuHardware;
  final int cpuCores;
  final List<String> supportedAbis;
  final String gpuVendor;
  final String gpuRenderer;
  final String openGlVersion;

  HardwareInfo({
    required this.cpuHardware,
    required this.cpuCores,
    required this.supportedAbis,
    required this.gpuVendor,
    required this.gpuRenderer,
    required this.openGlVersion,
  });
}

/// Service central : tente de lire les vraies données système (Android,
/// via les nœuds sysfs habituellement lisibles sans root : /proc/cpuinfo,
/// /sys/devices/system/cpu/cpuN/cpufreq/*, /sys/class/thermal/*).
/// Si une valeur n'est pas accessible (permissions, iOS, émulateur...),
/// une valeur réaliste de repli est utilisée afin que l'interface reste
/// toujours fonctionnelle et cohérente avec les maquettes fournies.
class CpuInfoService {
  static final CpuInfoService instance = CpuInfoService._();
  CpuInfoService._();

  final _random = Random();
  int? _coreCountCache;
  List<double>? _minFreqCache;
  List<double>? _maxFreqCache;

  Future<HardwareInfo> getHardwareInfo() async {
    String hardware = 'Inconnu';
    List<String> abis = const ['arm64-v8a'];
    int cores = Platform.numberOfProcessors;

    try {
      if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        hardware = info.hardware.isNotEmpty
            ? info.hardware
            : (info.board.isNotEmpty ? info.board : info.model);
        if (hardware.toLowerCase() == 'unknown' || hardware.isEmpty) {
          hardware = '${info.manufacturer} ${info.model}';
        }
        abis = info.supportedAbis.isNotEmpty
            ? info.supportedAbis
            : ['arm64-v8a', 'armeabi-v7a', 'armeabi'];
      } else if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        hardware = info.utsname.machine;
        abis = ['arm64'];
      }
    } catch (_) {
      // Repli silencieux, l'app reste utilisable.
    }

    final detectedCores = await _detectCoreCount();
    if (detectedCores != null) cores = detectedCores;

    return HardwareInfo(
      cpuHardware: hardware,
      cpuCores: cores,
      supportedAbis: abis,
      // La lecture du renderer GPU réel nécessite un contexte OpenGL natif
      // (canal de plateforme dédié). On expose ici les informations
      // disponibles côté Dart et une estimation raisonnable du reste.
      gpuVendor: Platform.isIOS ? 'Apple' : 'ARM',
      gpuRenderer: Platform.isIOS ? 'Apple GPU' : 'Mali / Adreno (détection native requise)',
      openGlVersion: 'OpenGL ES 3.2',
    );
  }

  Future<int?> _detectCoreCount() async {
    if (_coreCountCache != null) return _coreCountCache;
    if (!Platform.isAndroid) return null;
    try {
      final dir = Directory('/sys/devices/system/cpu');
      if (!await dir.exists()) return null;
      final entries = await dir.list().toList();
      final count = entries
          .whereType<Directory>()
          .where((d) => RegExp(r'cpu[0-9]+$').hasMatch(d.path))
          .length;
      if (count > 0) {
        _coreCountCache = count;
        return count;
      }
    } catch (_) {}
    return null;
  }

  Future<CpuSnapshot> readSnapshot() async {
    final cores = await _detectCoreCount() ?? Platform.numberOfProcessors;

    List<double>? freqs;
    List<double>? minFreqs;
    List<double>? maxFreqs;
    if (Platform.isAndroid) {
      freqs = await _readFrequencies(cores, 'scaling_cur_freq');
      _minFreqCache ??= await _readFrequencies(cores, 'cpuinfo_min_freq');
      _maxFreqCache ??= await _readFrequencies(cores, 'cpuinfo_max_freq');
      minFreqs = _minFreqCache;
      maxFreqs = _maxFreqCache;
    }

    freqs ??= _simulatedFrequencies(cores);
    minFreqs ??= List.generate(cores, (_) => 400);
    maxFreqs ??= List.generate(cores, (i) => i < cores / 2 ? 2210 : 2910);

    final temperature = await _readTemperature() ?? _simulatedTemperature();

    return CpuSnapshot(
      frequenciesMhz: freqs,
      minFreqMhz: minFreqs,
      maxFreqMhz: maxFreqs,
      temperatureC: temperature,
    );
  }

  Future<List<double>?> _readFrequencies(int cores, String fileName) async {
    try {
      final values = <double>[];
      for (var i = 0; i < cores; i++) {
        final file = File('/sys/devices/system/cpu/cpu$i/cpufreq/$fileName');
        if (!await file.exists()) return null;
        final content = (await file.readAsString()).trim();
        final khz = double.tryParse(content);
        if (khz == null) return null;
        values.add(khz / 1000.0); // kHz -> MHz
      }
      return values;
    } catch (_) {
      return null;
    }
  }

  Future<double?> _readTemperature() async {
    try {
      final base = Directory('/sys/class/thermal');
      if (!await base.exists()) return null;
      final zones = (await base.list().toList())
          .whereType<Directory>()
          .where((d) => RegExp(r'thermal_zone[0-9]+$').hasMatch(d.path))
          .toList();

      // On privilégie une zone dont le "type" évoque le CPU/SoC.
      for (final zone in zones) {
        try {
          final typeFile = File('${zone.path}/type');
          final tempFile = File('${zone.path}/temp');
          if (!await typeFile.exists() || !await tempFile.exists()) continue;
          final type = (await typeFile.readAsString()).toLowerCase();
          if (type.contains('cpu') || type.contains('soc') || type.contains('tsens')) {
            final raw = double.tryParse((await tempFile.readAsString()).trim());
            if (raw != null) {
              return raw > 1000 ? raw / 1000.0 : raw; // certains SoC exposent en milli-°C
            }
          }
        } catch (_) {
          continue;
        }
      }

      // À défaut, on prend la première zone lisible.
      if (zones.isNotEmpty) {
        final tempFile = File('${zones.first.path}/temp');
        if (await tempFile.exists()) {
          final raw = double.tryParse((await tempFile.readAsString()).trim());
          if (raw != null) return raw > 1000 ? raw / 1000.0 : raw;
        }
      }
    } catch (_) {}
    return null;
  }

  List<double> _simulatedFrequencies(int cores) {
    return List.generate(cores, (i) {
      final base = i < cores / 2 ? 700.0 : 1400.0;
      return base + _random.nextDouble() * 500;
    });
  }

  double _simulatedTemperature() {
    return 34 + _random.nextDouble() * 10;
  }

  /// Historique glissant utilisé pour tracer les courbes (température,
  /// fréquence globale...). On construit une fenêtre de [length] points,
  /// mise à jour à chaque tick en décalant les valeurs et en ajoutant la
  /// nouvelle mesure à la fin, comme les graphes des maquettes.
  List<double> pushHistory(List<double> history, double newValue, {int length = 24}) {
    final updated = List<double>.from(history)..add(newValue);
    if (updated.length > length) {
      updated.removeRange(0, updated.length - length);
    }
    return updated;
  }
}

@immutable
class UsageEstimate {
  final List<double> perCorePercent;
  final double averagePercent;
  const UsageEstimate(this.perCorePercent, this.averagePercent);
}

/// Estime la charge de chaque cœur à partir du ratio fréquence
/// courante / fréquence max (méthode utilisée en l'absence d'API
/// `/proc/stat` fiable multi-OEM sans permissions supplémentaires).
UsageEstimate estimateUsage(CpuSnapshot snapshot) {
  final percents = <double>[];
  for (var i = 0; i < snapshot.frequenciesMhz.length; i++) {
    final min = snapshot.minFreqMhz[i];
    final max = snapshot.maxFreqMhz[i];
    final cur = snapshot.frequenciesMhz[i];
    final ratio = max > min ? ((cur - min) / (max - min)).clamp(0.0, 1.0) : 0.0;
    percents.add(ratio * 100);
  }
  final avg = percents.isEmpty ? 0.0 : percents.reduce((a, b) => a + b) / percents.length;
  return UsageEstimate(percents, avg);
}
