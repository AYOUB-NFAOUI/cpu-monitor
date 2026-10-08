import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

const String _na = 'N/A';
const String _nativeNeeded = 'N/A (détection native requise)';

/// Toutes les informations affichées dans l'onglet "System".
class DeviceDetails {
  // Appareil
  final String title;
  final String model;
  final String manufacturer;
  final String brand;
  final String hardware;
  final String device;
  final String board;

  // Système
  final String versionName;
  final String apiLevel;
  final String buildNumber;
  final String buildId;
  final String securityPatch;
  final String language;
  final String vmLabel; // "Java VM" (natif) ou "Dart VM" (repli)
  final String vm;
  final String timeZone;
  final String kernel;

  // Écran
  final String resolution;
  final String dpi;
  final String density;
  final String screenSize;
  final String aspectRatio;
  final String displayBucket;
  final String refreshRate;
  final String supportedRefreshRate;
  final String hdr;

  // Matériel supporté (libellé -> oui/non)
  final List<MapEntry<String, bool>> hardwareSupported;

  const DeviceDetails({
    this.title = _na,
    this.model = _na,
    this.manufacturer = _na,
    this.brand = _na,
    this.hardware = _na,
    this.device = _na,
    this.board = _na,
    this.versionName = _na,
    this.apiLevel = _na,
    this.buildNumber = _na,
    this.buildId = _na,
    this.securityPatch = _na,
    this.language = _na,
    this.vmLabel = 'Java VM',
    this.vm = _na,
    this.timeZone = _na,
    this.kernel = _na,
    this.resolution = _na,
    this.dpi = _na,
    this.density = _na,
    this.screenSize = _na,
    this.aspectRatio = _na,
    this.displayBucket = _na,
    this.refreshRate = _na,
    this.supportedRefreshRate = _na,
    this.hdr = _na,
    this.hardwareSupported = const [],
  });
}

/// Lit les informations de l'appareil.
///
/// Sources : device_info_plus, Flutter (`Display`), /proc/version, et un
/// canal natif OPTIONNEL (`cpu_monitor/device`, voir MainActivity.kt) qui
/// fournit xdpi/ydpi, les fréquences d'écran supportées, le HDR, la VM Java
/// et le fuseau horaire complet. Sans ce canal, ces champs affichent "N/A".
///
/// Le résultat est mis en cache : changer d'onglet ne relance pas la lecture.
class DeviceDetailsService {
  DeviceDetailsService._();

  static const MethodChannel _channel = MethodChannel('cpu_monitor/device');
  static Future<DeviceDetails>? _cached;

  static Future<DeviceDetails> load() => _cached ??= _load();

  static Future<Map<String, dynamic>?> _nativeInfo() async {
    try {
      return await _channel.invokeMapMethod<String, dynamic>('getDisplayInfo');
    } catch (_) {
      return null; // canal absent : on utilise les valeurs de repli
    }
  }

  static double? _num(Object? v) => v is num ? v.toDouble() : null;

  static Future<DeviceDetails> _load() async {
    if (!Platform.isAndroid) return const DeviceDetails();
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      final native = await _nativeInfo();

      // ---- Matériel supporté (FEATURE_* du PackageManager) ----
      final features = info.systemFeatures.toSet();
      bool has(List<String> names) => names.any(features.contains);
      final hardwareSupported = <MapEntry<String, bool>>[
        MapEntry('USB Host Support', has(['android.hardware.usb.host'])),
        MapEntry('USB Accessory Support', has(['android.hardware.usb.accessory'])),
        MapEntry('Low Latency Audio', has(['android.hardware.audio.low_latency'])),
        MapEntry('Pro Audio Support', has(['android.hardware.audio.pro'])),
        MapEntry('Bluetooth', has(['android.hardware.bluetooth'])),
        MapEntry('Bluetooth Low Energy', has(['android.hardware.bluetooth_le'])),
        MapEntry('Fingerprint', has(['android.hardware.fingerprint'])),
        MapEntry('Face Detection',
            has(['android.hardware.biometrics.face', 'android.hardware.face'])),
        MapEntry('Infrared Transmitter', has(['android.hardware.consumerir'])),
        MapEntry('UWB Support', has(['android.hardware.uwb'])),
        MapEntry('NFC Support', has(['android.hardware.nfc'])),
        MapEntry('GPS Support', has(['android.hardware.location.gps'])),
      ];

      // ---- Écran : valeurs Flutter, remplacées par le natif si dispo ----
      var wPx = 0.0;
      var hPx = 0.0;
      var densityDpi = 0;
      var refreshHz = 0.0;
      try {
        final display = ui.PlatformDispatcher.instance.views.first.display;
        wPx = display.size.width;
        hPx = display.size.height;
        densityDpi = (display.devicePixelRatio * 160).round();
        refreshHz = display.refreshRate;
      } catch (_) {}

      var xdpi = 0.0;
      var ydpi = 0.0;
      if (native != null) {
        wPx = _num(native['widthPx']) ?? wPx;
        hPx = _num(native['heightPx']) ?? hPx;
        xdpi = _num(native['xdpi']) ?? 0;
        ydpi = _num(native['ydpi']) ?? 0;
        final nd = _num(native['densityDpi']);
        if (nd != null && nd > 0) densityDpi = nd.round();
      }
      final shortSide = math.min(wPx, hPx);
      final longSide = math.max(wPx, hPx);

      // ---- Fréquences supportées / HDR / VM (natif uniquement) ----
      var supportedRates = _nativeNeeded;
      final rates = native?['refreshRates'];
      if (rates is List) {
        final list = rates.whereType<num>().map((e) => e.round()).toSet().toList()
          ..sort((a, b) => b.compareTo(a));
        if (list.isNotEmpty) supportedRates = list.map((e) => '$e Hz').join(', ');
      }

      var hdr = _nativeNeeded;
      final hdrList = native?['hdr'];
      if (hdrList is List) {
        final names = hdrList.whereType<String>().toList();
        hdr = names.isEmpty ? 'Not supported' : names.join(', ');
      }

      final jvm = native?['jvm'];
      final hasJvm = jvm is String && jvm.isNotEmpty;

      return DeviceDetails(
        title: '${_capitalize(info.manufacturer)} ${info.model}',
        model: info.model,
        manufacturer: info.manufacturer,
        brand: info.brand,
        hardware: info.hardware,
        device: info.device,
        board: info.board,
        versionName: 'Android ${info.version.release}',
        apiLevel: '${info.version.sdkInt}',
        buildNumber: info.display,
        buildId: info.id,
        securityPatch: info.version.securityPatch ?? _na,
        language: _languageName(),
        vmLabel: hasJvm ? 'Java VM' : 'Dart VM',
        vm: hasJvm ? jvm : _dartVm(),
        timeZone: _timeZone(native),
        kernel: await _kernelVersion(),
        resolution: shortSide > 0
            ? '${shortSide.round()} x ${longSide.round()} Pixels'
            : _na,
        dpi: densityDpi > 0 ? '$densityDpi dpi' : _na,
        density: (xdpi > 0 && ydpi > 0)
            ? 'x: ${xdpi.round()} dpi | y: ${ydpi.round()} dpi'
            : _nativeNeeded,
        screenSize: _screenInches(wPx, hPx, xdpi, ydpi),
        aspectRatio: _aspectRatio(shortSide, longSide),
        displayBucket: densityDpi > 0 ? _bucket(densityDpi) : _na,
        refreshRate: refreshHz > 0 ? '${refreshHz.round()} Hz' : _na,
        supportedRefreshRate: supportedRates,
        hdr: hdr,
        hardwareSupported: hardwareSupported,
      );
    } catch (_) {
      return const DeviceDetails();
    }
  }

  // ------------------------------------------------------------------ utils

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _screenInches(double w, double h, double xdpi, double ydpi) {
    if (xdpi <= 0 || ydpi <= 0 || w <= 0 || h <= 0) return _nativeNeeded;
    final inches = math.sqrt(math.pow(w / xdpi, 2) + math.pow(h / ydpi, 2));
    return '${inches.toStringAsFixed(2)} Inches';
  }

  static String _aspectRatio(double shortSide, double longSide) {
    if (shortSide <= 0) return _na;
    final r = longSide / shortSide;
    const known = <String, double>{
      '4:3': 4 / 3,
      '16:10': 1.6,
      '16:9': 16 / 9,
      '18:9': 2.0,
      '18.5:9': 18.5 / 9,
      '19:9': 19 / 9,
      '19.5:9': 19.5 / 9,
      '20:9': 20 / 9,
      '21:9': 21 / 9,
    };
    for (final e in known.entries) {
      if ((r - e.value).abs() < 0.015) return e.key;
    }
    final a = longSide.round();
    final b = shortSide.round();
    final g = _gcd(a, b);
    return '${a ~/ g}:${b ~/ g}';
  }

  static int _gcd(int a, int b) {
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a == 0 ? 1 : a;
  }

  static String _bucket(int dpi) {
    if (dpi < 140) return 'ldpi';
    if (dpi < 200) return 'mdpi';
    if (dpi < 280) return 'hdpi';
    if (dpi < 400) return 'xhdpi';
    if (dpi < 560) return 'xxhdpi';
    return 'xxxhdpi';
  }

  static const Map<String, String> _languages = {
    'en': 'English',
    'fr': 'French',
    'ar': 'Arabic',
    'es': 'Spanish',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'tr': 'Turkish',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'nl': 'Dutch',
    'hi': 'Hindi',
  };

  static const Map<String, String> _countries = {
    'US': 'United States',
    'GB': 'United Kingdom',
    'FR': 'France',
    'MA': 'Morocco',
    'DZ': 'Algeria',
    'TN': 'Tunisia',
    'EG': 'Egypt',
    'SA': 'Saudi Arabia',
    'AE': 'United Arab Emirates',
    'ES': 'Spain',
    'DE': 'Germany',
    'IT': 'Italy',
    'BE': 'Belgium',
    'CA': 'Canada',
    'CH': 'Switzerland',
    'PT': 'Portugal',
    'BR': 'Brazil',
    'TR': 'Turkey',
  };

  static String _languageName() {
    try {
      final locale = ui.PlatformDispatcher.instance.locale;
      final lang = _languages[locale.languageCode] ?? locale.languageCode;
      final code = locale.countryCode;
      if (code == null || code.isEmpty) return lang;
      return '$lang(${_countries[code] ?? code})';
    } catch (_) {
      return _na;
    }
  }

  static String _dartVm() {
    // Ex. "3.7.0 (stable) (...)" -> "3.7.0"
    final v = Platform.version.split(' ').first;
    return v.isEmpty ? _na : v;
  }

  static String _offset(int minutes) {
    final sign = minutes < 0 ? '-' : '+';
    final h = (minutes.abs() ~/ 60).toString().padLeft(2, '0');
    final m = (minutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$h:$m';
  }

  static String _timeZone(Map<String, dynamic>? native) {
    if (native != null) {
      final id = native['tzId'];
      final name = native['tzName'];
      final off = native['tzOffsetMinutes'];
      if (id is String && name is String && off is num) {
        return '$name $id(GMT${_offset(off.toInt())})';
      }
    }
    final now = DateTime.now();
    return '${now.timeZoneName} (GMT${_offset(now.timeZoneOffset.inMinutes)})';
  }

  static Future<String> _kernelVersion() async {
    try {
      final raw = await File('/proc/version').readAsString();
      final m = RegExp(r'Linux version (\S+)').firstMatch(raw);
      if (m != null) return m.group(1)!;
    } catch (_) {}
    return Platform.operatingSystemVersion;
  }
}
