import 'dart:ui';
import 'package:cpu_monitor_temperature/ads/src/multi_ads_factory.dart';

class Constants {
  // Votre lien Google Drive direct
  static const jsonConfigUrl =
      'https://drive.google.com/uc?export=download&id=1pWC9zYL6fbgbKJwbuhS3XmIMUxIOR8dc';

  static Color mainColor = const Color(0xff33FD24);
}

// Variable globale des publicités (initialisée après téléchargement depuis Drive)
MultiAds? gAds;
bool isInterShowed = false;