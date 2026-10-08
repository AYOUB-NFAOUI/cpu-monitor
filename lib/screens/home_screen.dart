import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../ads/multi_ads.dart';
import '../ads/src/widgets/custom_native.dart';
import '../const.dart';
import '../models/app_settings.dart';
import '../models/floating_settings.dart' show RefreshRate, RefreshRateX;
import '../services/cpu_info_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/wave_chart.dart';
import 'floating_screen.dart';
import 'settings_screen.dart';
import 'system_screen.dart';
import '../l10n/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = CpuInfoService.instance;
  final _settings = AppSettings.instance;

  HardwareInfo? _hardware;
  CpuSnapshot? _snapshot;
  UsageEstimate? _usage;

  List<double> _tempHistory = [];
  List<double> _freqHistory = [];
  List<List<double>> _perCoreHistory = [];

  Timer? _timer;
  RefreshRate _timerRate = RefreshRate.two;
  bool _refreshing = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsChanged);
    _bootstrap();
  }

  void _onSettingsChanged() {
    if (_timer != null && _settings.refreshRate != _timerRate) _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timerRate = _settings.refreshRate;
    _timer = Timer.periodic(_timerRate.duration, (_) => _refresh());
  }

  Future<void> _bootstrap() async {
    final hardware = await _service.getHardwareInfo();
    final snapshot = await _service.readSnapshot();
    final usage = estimateUsage(snapshot);
    if (!mounted) return;

    setState(() {
      _hardware = hardware;
      _snapshot = snapshot;
      _usage = usage;
      _tempHistory = seedHistory(snapshot.temperatureC, spread: 6);
      _freqHistory = seedHistory(
        snapshot.frequenciesMhz.reduce((a, b) => a + b) / snapshot.frequenciesMhz.length,
        spread: 300,
      );
      _perCoreHistory = List.generate(
        hardware.cpuCores,
        (i) => seedHistory(
          snapshot.frequenciesMhz.length > i ? snapshot.frequenciesMhz[i] : 800,
          spread: 250,
        ),
      );
    });

    _startTimer();
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      await _readAndUpdate();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _readAndUpdate() async {
    final snapshot = await _service.readSnapshot();
    final usage = estimateUsage(snapshot);
    if (!mounted) return;
    setState(() {
      _snapshot = snapshot;
      _usage = usage;
      _tempHistory = _service.pushHistory(_tempHistory, snapshot.temperatureC);
      final avgFreq = snapshot.frequenciesMhz.reduce((a, b) => a + b) / snapshot.frequenciesMhz.length;
      _freqHistory = _service.pushHistory(_freqHistory, avgFreq);
      for (var i = 0; i < _perCoreHistory.length && i < snapshot.frequenciesMhz.length; i++) {
        _perCoreHistory[i] = _service.pushHistory(_perCoreHistory[i], snapshot.frequenciesMhz[i]);
      }
    });
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChanged);
    _timer?.cancel();
    super.dispose();
  }

  void _openSettings() {
    try {
      gAds?.interInstance.showInterstitialAd();
    } catch (e) {
      debugPrint('Erreur inter ad : $e');
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildTabs(),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      bottomNavigationBar: gAds != null
          ? SafeArea(
              child: SizedBox(
                height: 50,
                child: CustomBanner(
                  key: const Key('home_banner_ad'),
                  ads: gAds!.bannerInstance,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 1:
        return const FloatingScreen();
      case 2:
        return const SystemScreen();
      default:
        return _buildCpuDashboard();
    }
  }

  Widget _buildCpuDashboard() {
    final hardware = _hardware;
    final snapshot = _snapshot;
    final usage = _usage;

    if (hardware == null || snapshot == null || usage == null) {
      return Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionHeader(title: hardware.cpuHardware),
          InfoRow(label: 'Cpu Hardware', value: hardware.cpuHardware),
          InfoRow(label: 'Cpu Cores', value: '${hardware.cpuCores}'),
          InfoRow(
            label: 'Supported ABIs',
            value: hardware.supportedAbis.join(', '),
            multiline: true,
          ),
          InfoRow(
            label: 'Cpu Frequency',
            value: _formatCoreFrequencies(snapshot),
            multiline: true,
          ),
          const SizedBox(height: 6),
          _procInfoPill(),

          const SizedBox(height: 22),
          SectionHeader(
            title: 'Cpu Temperature',
            trailing: Text(
              '${snapshot.temperatureC.toStringAsFixed(0)}°C',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ),
          WaveChart(
            values: _tempHistory,
            minValue: 25,
            maxValue: 55,
          ),

          if (gAds != null) ...[
            const SizedBox(height: 20),
            CustomNative(
              key: const Key('cpu_native_ad'),
              ads: gAds!.nativeInstance,
              templateType: TemplateType.medium,
            ),
          ],

          const SizedBox(height: 22),
          SectionHeader(title: 'Gpu Summary'),
          InfoRow(label: 'Gpu Vendor', value: hardware.gpuVendor),
          InfoRow(label: 'Gpu Renderer', value: hardware.gpuRenderer),
          InfoRow(
            label: 'OpenGL Version',
            value: hardware.openGlVersion,
            multiline: true,
          ),

          const SizedBox(height: 28),
          SectionHeader(title: 'Cpu Usage'),
          _buildUsageGrid(snapshot, usage),

          const SizedBox(height: 22),
          SectionHeader(
            title: 'Cpu Frequency',
            trailing: Text(
              '${usage.averagePercent.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.darkText,
              ),
            ),
          ),
          WaveChart(
            values: _freqHistory,
            minValue: snapshot.minFreqMhz.reduce((a, b) => a < b ? a : b),
            maxValue: snapshot.maxFreqMhz.reduce((a, b) => a > b ? a : b),
            height: 130,
          ),
          const SizedBox(height: 14),
          _buildPerCoreCharts(snapshot, usage),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              S.appTitle,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 1,
                color: AppColors.darkText,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _headerIcon(Icons.bookmark_rounded),
        const SizedBox(width: 10),
        _headerIcon(
          Icons.settings_rounded,
          onTap: _openSettings,
        ),
      ],
    );
  }

  Widget _headerIcon(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: AppColors.darkText),
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [
      (icon: Icons.memory_rounded, label: S.cpu),
      (icon: Icons.blur_circular_rounded, label: S.floating),
      (icon: Icons.phone_android_rounded, label: S.system),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (i) {
          final t = tabs[i];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: TopTab(
              icon: t.icon,
              label: t.label,
              selected: _selectedTab == i,
              onTap: () {
                if (_selectedTab != i) {
                  // Afficher la publicité lors du clic sur un nouvel onglet (Floating ou System)
                  try {
                    gAds?.interInstance.showInterstitialAd();
                  } catch (e) {
                    debugPrint('Erreur lors de l\'affichage de l\'interstitiel : $e');
                  }
                  setState(() => _selectedTab = i);
                }
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _procInfoPill() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('/proc/cpuinfo', style: TextStyle(color: AppColors.mutedText, fontWeight: FontWeight.w600)),
          Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
        ],
      ),
    );
  }

  String _formatCoreFrequencies(CpuSnapshot snapshot) {
    final grouped = <String, int>{};
    for (final f in snapshot.frequenciesMhz) {
      final ghz = (f / 1000).toStringAsFixed(f >= 1000 ? 2 : 0);
      final label = f >= 1000 ? '$ghz GHz' : '${f.toStringAsFixed(0)} MHz';
      grouped[label] = (grouped[label] ?? 0) + 1;
    }
    return grouped.entries.map((e) => '${e.value} x ${e.key}').join(', ');
  }

  Widget _buildUsageGrid(CpuSnapshot snapshot, UsageEstimate usage) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: usage.perCorePercent.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 20,
        childAspectRatio: 3.6,
      ),
      itemBuilder: (context, i) {
        final freqLabel = _freqLabel(snapshot.frequenciesMhz[i]);
        final percent = usage.perCorePercent[i] / 100;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${i + 1}. $freqLabel',
                  style: TextStyle(color: AppColors.accentGreen, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            LinearPercentIndicator(
              lineHeight: 8,
              percent: percent.clamp(0.0, 1.0),
              padding: EdgeInsets.zero,
              barRadius: const Radius.circular(6),
              backgroundColor: AppColors.trackGrey,
              progressColor: AppColors.accentGreen,
              animation: true,
              animateFromLastPercent: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildPerCoreCharts(CpuSnapshot snapshot, UsageEstimate usage) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _perCoreHistory.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, i) {
        final double min = snapshot.minFreqMhz.length > i ? snapshot.minFreqMhz[i] : 400.0;
        final double max = snapshot.maxFreqMhz.length > i ? snapshot.maxFreqMhz[i] : 2200.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${i + 1}. ${_freqLabel(min)} – ${_freqLabel(max)}   ${usage.perCorePercent[i].toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 12, color: AppColors.accentGreen, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: WaveChart(
                values: _perCoreHistory[i],
                minValue: min,
                maxValue: max,
                height: 90,
              ),
            ),
          ],
        );
      },
    );
  }

  String _freqLabel(double mhz) {
    if (mhz >= 1000) return '${(mhz / 1000).toStringAsFixed(2)} GHz';
    return '${mhz.toStringAsFixed(0)} MHz';
  }
}