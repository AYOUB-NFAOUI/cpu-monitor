import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../ads/src/multi_ads_factory.dart';
import '../const.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _fetchDriveConfigAndNavigate();
  }

  /// Récupère la configuration 100% Google Drive puis effectue la transition
  Future<void> _fetchDriveConfigAndNavigate() async {
    final delayFuture = Future.delayed(const Duration(milliseconds: 1500));

    try {
      // 1. Téléchargement exclusif depuis votre URL Google Drive
      final response = await http.get(Uri.parse(Constants.jsonConfigUrl));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        // 2. Instanciation de gAds uniquement avec le contenu du Drive
        gAds = MultiAds(response.body);
        await gAds!.init();
        await gAds!.loadAds();
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération du JSON Drive : $e');
    }

    // 3. Attente du temps d'animation minimal du splash
    await delayFuture;

    if (!mounted || _navigated) return;

    // 4. Affichage de la publicité de démarrage
    try {
      if (gAds != null) {
        gAds!.openAdsInstance.showAdIfAvailableOpenAds();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'affichage de l\'open ad : $e');
    }

    // 5. Navigation vers HomeScreen
    _navigateToHome();
  }

  void _navigateToHome() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: RotationTransition(
                turns: _spinController,
                child: Icon(
                  Icons.refresh_rounded,
                  size: 64,
                  color: AppColors.darkText,
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 48, top: 32),
            decoration: BoxDecoration(
              color: AppColors.surface,
            ),
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.memory_rounded, color: Colors.white, size: 34),
                        Text(
                          'CPU',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  S.tr('LOADING...'),
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}