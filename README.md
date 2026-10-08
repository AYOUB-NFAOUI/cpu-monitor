# CPU Monitor - Temperature

Application Flutter (Android + iOS) reproduisant le style des maquettes fournies :
écran de démarrage (page 0), puis un écran principal défilant qui réunit les
« page 1 » (infos CPU, température, GPU) et « page 2 » (usage par cœur,
fréquences par cœur) en une seule page continue.

## Contenu du projet

```
lib/
  main.dart                 -> point d'entrée
  theme/app_theme.dart      -> couleurs / styles
  screens/splash_screen.dart-> page 0 (chargement)
  screens/home_screen.dart  -> page 1 + page 2 (une seule page scrollable)
  services/cpu_info_service.dart -> lecture des vraies infos matérielles
  widgets/section_card.dart -> en-têtes de section, lignes info, onglets
  widgets/wave_chart.dart   -> graphique courbe + grille pointillée
assets/icon/app_icon.png    -> logo de l'application
pubspec.yaml
```

## Mise en route

Ce dossier contient uniquement le code source Dart/Flutter (`lib/`, `pubspec.yaml`,
les assets). Comme il a été généré hors d'un environnement Flutter, il faut
d'abord créer les dossiers natifs `android/` et `ios/` :

```bash
cd cpu_monitor_app

# 1. Génère les dossiers natifs Android/iOS (ne touche pas à lib/ ni pubspec.yaml existants)
flutter create . --project-name cpu_monitor_temperature --org com.votresociete

# 2. Installe les dépendances
flutter pub get

# 3. Génère les icônes Android/iOS à partir de assets/icon/app_icon.png
dart run flutter_launcher_icons

# 4. Lance l'application (émulateur ou appareil branché)
flutter run
```

## Nom de l'application affiché sur l'appareil

Après `flutter create .`, mettez à jour le nom affiché :

- **Android** — `android/app/src/main/AndroidManifest.xml` :
  ```xml
  <application
      android:label="CPU Monitor - Temperature"
      ...>
  ```
- **iOS** — `ios/Runner/Info.plist` :
  ```xml
  <key>CFBundleDisplayName</key>
  <string>CPU Monitor - Temperature</string>
  ```

## Fonctionnement

- **Page 0** : `splash_screen.dart` affiche le logo, un indicateur de
  chargement et le texte « LOADING... », puis bascule automatiquement vers
  l'écran principal après ~1,6 s (transition en fondu).
- **Page 1 + Page 2** : `home_screen.dart` est un unique `ListView` : la
  partie haute correspond à la « page 1 » (matériel CPU, courbe de
  température, résumé GPU) et en continuant à défiler on arrive à la
  « page 2 » (répartition de charge par cœur, courbes de fréquence par
  cœur). Un `Timer` rafraîchit les mesures toutes les 2 secondes.

## Données réelles vs. estimées

`CpuInfoService` tente de lire les vraies informations système :

- **Modèle CPU / cœurs / ABIs** : via `device_info_plus` (Android/iOS) et
  `/sys/devices/system/cpu/`.
- **Fréquence par cœur** : `/sys/devices/system/cpu/cpuN/cpufreq/scaling_cur_freq`
  (et `cpuinfo_min_freq` / `cpuinfo_max_freq`).
- **Température CPU** : `/sys/class/thermal/thermal_zoneN/{type,temp}`,
  zone dont le type contient « cpu », « soc » ou « tsens » en priorité.
- **Usage par cœur** : estimé à partir du ratio fréquence courante / plage
  min-max de chaque cœur (Android ne fournit pas d'API haut niveau fiable
  et multi-constructeur pour l'usage instantané sans lecture de
  `/proc/stat`, qui est elle aussi une source best-effort).

Sur certains appareils (permissions SELinux renforcées, iOS, émulateurs),
ces fichiers ne sont pas lisibles : le service bascule alors silencieusement
sur des valeurs simulées réalistes, afin que l'interface reste toujours
fonctionnelle et fidèle aux maquettes.

Le **renderer GPU réel** (ex. « Mali-G78 ») nécessite la création d'un
contexte OpenGL ES natif (canal de plateforme Kotlin/Swift dédié), non
inclus ici pour rester dans un projet Flutter pur. Un champ générique est
affiché à la place ; il peut être remplacé plus tard par un plugin dédié ou
un `MethodChannel` natif si vous voulez la valeur exacte.

## Personnalisation rapide

- Couleurs : `lib/theme/app_theme.dart`
- Logo : remplacez `assets/icon/app_icon.png` puis relancez
  `dart run flutter_launcher_icons`
- Intervalle de rafraîchissement : `Timer.periodic` dans `home_screen.dart`
