import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/floating_settings.dart';

/// Centralise tout ce qui touche à la fenêtre flottante SYSTÈME.
///
/// À appeler UNE fois au démarrage : `await OverlayService.init();`
/// - recharge les réglages sauvegardés,
/// - écoute chaque [FeatureSettings] et resynchronise la fenêtre
///   système à chaque changement,
/// - relance l'overlay si des fonctionnalités étaient activées.
class OverlayService {
  OverlayService._();

  /// Clé SharedPreferences partagée avec `overlay_main.dart`.
  static const prefsKey = 'floating_settings_v1';

  static int? _lastWidth;
  static int? _lastHeight;
  static bool? _lastDock;

  // Verrou anti-rafale : un seul sync() à la fois, les appels reçus pendant
  // qu'il tourne sont regroupés en UNE resynchro finale.
  static bool _syncing = false;
  static bool _pendingResync = false;
  static bool _initialized = false;

  static bool get _anyEnabled =>
      floatingSettings.values.any((s) => s.enabled);

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _loadSettings();
    for (final s in floatingSettings.values) {
      s.addListener(sync);
    }
    // Ne pas attendre : la demande de permission ne doit pas bloquer runApp.
    if (_anyEnabled) unawaited(sync());
  }

  static Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final f in FloatingFeature.values) {
        final j = map[f.name];
        if (j is Map) {
          settingsOf(f).applyJson(Map<String, dynamic>.from(j));
        }
      }
    } catch (_) {
      // Pas de config sauvegardée : valeurs par défaut.
    }
  }

  static Future<bool> ensurePermission() async {
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (granted) return true;
    final result = await FlutterOverlayWindow.requestPermission();
    return result == true;
  }

  /// Config complète : { nomFonctionnalité: {réglages} }.
  static Map<String, dynamic> currentConfig() => {
        for (final f in FloatingFeature.values) f.name: settingsOf(f).toJson(),
      };

  /// Calcule la taille de la fenêtre overlay (pixels PHYSIQUES attendus par
  /// le plugin). Toutes les fonctionnalités activées sont empilées
  /// verticalement avec 8 dp d'écart. La taille est plafonnée à l'écran ;
  /// si le contenu est plus grand, l'overlay le réduit automatiquement.
  static ({int width, int height, bool dock}) _computeGeometry() {
    final enabled = FloatingFeature.values
        .where((f) => settingsOf(f).enabled)
        .toList();

    if (enabled.isEmpty) {
      return (width: 120, height: 120, dock: false);
    }

    double maxWidth = 0;
    double totalHeight = 0;
    for (final f in enabled) {
      final size = f.blockSize(settingsOf(f).size);
      maxWidth = math.max(maxWidth, size.width);
      totalHeight += size.height;
    }
    totalHeight += 8.0 * (enabled.length - 1);

    const safetyMarginDp = 8.0;
    var widthLogical = maxWidth + 24 + safetyMarginDp;
    var heightLogical = totalHeight + 24 + safetyMarginDp;

    final view = ui.PlatformDispatcher.instance.views.first;
    final ratio = view.devicePixelRatio;
    final screen = view.physicalSize / ratio;
    widthLogical = math.min(widthLogical, screen.width);
    heightLogical = math.min(heightLogical, screen.height * 0.9);

    final dock = enabled.any((f) => settingsOf(f).dockToEdge);

    return (
      width: (widthLogical * ratio).round(),
      height: (heightLogical * ratio).round(),
      dock: dock,
    );
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(currentConfig()));
  }

  /// Point d'entrée public : protégé par le verrou anti-rafale.
  static Future<void> sync() async {
    if (_syncing) {
      _pendingResync = true;
      return;
    }

    _syncing = true;
    try {
      await _doSync();
    } catch (_) {
      // Mieux vaut un overlay qui ne se met pas à jour qu'un crash de l'app.
    } finally {
      _syncing = false;
      if (_pendingResync) {
        _pendingResync = false;
        unawaited(sync());
      }
    }
  }

  static Future<void> _doSync() async {
    await _persist();

    if (!_anyEnabled) {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        _lastWidth = null;
        _lastHeight = null;
        _lastDock = null;
      }
      return;
    }

    final granted = await ensurePermission();
    if (!granted) return;

    final geometry = _computeGeometry();
    final geometryChanged = geometry.width != _lastWidth ||
        geometry.height != _lastHeight ||
        geometry.dock != _lastDock;

    final isActive = await FlutterOverlayWindow.isActive();

    if (isActive && !geometryChanged) {
      await FlutterOverlayWindow.shareData(jsonEncode(currentConfig()));
      return;
    }

    if (isActive && geometryChanged) {
      await FlutterOverlayWindow.closeOverlay();
    }

    await FlutterOverlayWindow.showOverlay(
      height: geometry.height,
      width: geometry.width,
      alignment: OverlayAlignment.centerRight,
      enableDrag: true,
      positionGravity: geometry.dock ? PositionGravity.auto : PositionGravity.none,
      visibility: NotificationVisibility.visibilitySecret,
      overlayTitle: 'CPU Monitor',
      overlayContent: 'Surveillance active en arrière-plan',
    );
    _lastWidth = geometry.width;
    _lastHeight = geometry.height;
    _lastDock = geometry.dock;

    await Future.delayed(const Duration(milliseconds: 400));
    await FlutterOverlayWindow.shareData(jsonEncode(currentConfig()));
  }
}

/// Remplaçant local de `unawaited` (évite une dépendance supplémentaire).
void unawaited(Future<void> future) {}
