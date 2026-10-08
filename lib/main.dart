import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_settings.dart';
import 'screens/splash_screen.dart';
import 'services/overlay_service.dart';
import 'theme/app_theme.dart';
import 'overlay/overlay_main.dart' as overlay;

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
void overlayMain() => overlay.runOverlayApp();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation des préférences locales et du service Overlay
  await AppSettings.instance.load();
  await OverlayService.init();

  runApp(const CpuMonitorApp());
}

class CpuMonitorApp extends StatefulWidget {
  const CpuMonitorApp({super.key});

  @override
  State<CpuMonitorApp> createState() => _CpuMonitorAppState();
}

class _CpuMonitorAppState extends State<CpuMonitorApp> with WidgetsBindingObserver {
  final _settings = AppSettings.instance;
  late String _signature = _settings.signature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _settings.refreshFromSystem();

  @override
  void didChangeLocales(List<Locale>? locales) => _settings.refreshFromSystem();

  void _onSettingsChanged() {
    if (_settings.signature == _signature) return;
    setState(() => _signature = _settings.signature);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _rebuildAll();
    });
  }

  void _rebuildAll() {
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'CPU Monitor - Temperature',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.current,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor: AppColors.background,
            systemNavigationBarIconBrightness:
                dark ? Brightness.light : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}