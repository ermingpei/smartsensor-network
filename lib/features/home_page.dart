import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_strings.dart';
import '../core/sensor_manager.dart';
import '../core/motion_detector.dart';
import 'widgets/tool_card.dart';
import 'widgets/qbit_icon.dart';
import 'noise_meter_page.dart';
import 'wifi_analyzer_page.dart';
import 'magnetometer_page.dart';
import 'hex_map_page.dart';

/// Home Page - Main dashboard with sensing control and live readings
/// Matches SmartVibes app design: top tabs + main control button + live metrics
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Deep gradient background matching reference design
    const bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0D0D1A),
        Color(0xFF1A1A3E),
        Color(0xFF0D0D1A),
      ],
    );

    return Container(
      decoration: const BoxDecoration(gradient: bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Top AppBar
            _buildAppBar(),
            // Top Tab Bar
            _buildTabBar(),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildForYouTab(),
                  _buildLiveDataTab(),
                  _buildHowToTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/icon/icon.png', width: 36, height: 36),
            ),
            const SizedBox(width: 10),
            Image.asset(
              'assets/icon/smartsensor_title.png',
              height: 48,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  "SmartSensor",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.cyanAccent.withValues(alpha: 0.5),
                      )
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.purpleAccent.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: [
          Tab(text: AppStrings.t('tab_for_you')),
          Tab(text: AppStrings.t('tab_live_data')),
          Tab(text: AppStrings.t('tab_how_to')),
        ],
      ),
    );
  }

  /// "For You" tab - Main control + weekly report + quick tools
  Widget _buildForYouTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Main Control Banner (Start/Pause Sensing)
          _buildMainControlBanner(),
          const SizedBox(height: 20),
          // Data Quality Card
          _buildDataQualityCard(),
          const SizedBox(height: 20),
          // Weekly Report Summary
          _buildWeeklyReportCard(),
          const SizedBox(height: 20),
          // Quick Tools Section
          _buildQuickToolsSection(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  /// Main control banner with prominent START/PAUSE button
  Widget _buildMainControlBanner() {
    return Consumer<SensorManager>(
      builder: (context, manager, _) {
        final isActive = manager.isSampling;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isActive
                  ? [const Color(0xFF1A5A1A), const Color(0xFF0D3D0D)]
                  : [const Color(0xFF3D2D8C), const Color(0xFF2D1D6C)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? Colors.greenAccent.withValues(alpha: 0.5)
                  : Colors.purpleAccent.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? Colors.greenAccent.withValues(alpha: 0.2)
                    : Colors.purpleAccent.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isActive ? Icons.sensors : Icons.sensors_off,
                        color: isActive ? Colors.greenAccent : Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.t('toolbox_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Status indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.greenAccent : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Main Control Button
              GestureDetector(
                onTap: () async {
                  if (isActive) {
                    manager.stopSampling();
                  } else {
                    // Request permissions and start sampling
                    final hasPermission = await manager.requestPermissions();
                    if (hasPermission) {
                      // Generate a device ID (simplified - in production use a proper unique ID)
                      manager.startRealSampling(
                          deviceId:
                              'device_${DateTime.now().millisecondsSinceEpoch}');
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isActive
                          ? [Colors.orangeAccent, Colors.deepOrange]
                          : [Colors.greenAccent, Colors.green],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isActive ? Colors.orange : Colors.green)
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive
                            ? AppStrings.t('pause_sensing')
                            : AppStrings.t('start_sensing'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Contribution and QBIT display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isActive
                        ? AppStrings.t('contribution_on')
                        : AppStrings.t('contribution_off'),
                    style: TextStyle(
                      color: isActive ? Colors.greenAccent : Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  Row(
                    children: [
                      const QBitIcon(size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${manager.totalEarnings.toStringAsFixed(2)} QBit',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Weekly report summary card with progress rings
  Widget _buildWeeklyReportCard() {
    return Consumer<SensorManager>(
      builder: (context, manager, _) {
        // Calculate progress values (7 days target, 100 points target, 50 hexes target)
        final daysActive = 7; // TODO: Track actual active days
        final daysProgress = (daysActive / 7).clamp(0.0, 1.0);
        final pointsProgress = (manager.totalEarnings / 100).clamp(0.0, 1.0);
        final hexProgress = (manager.uniqueHexCount / 50).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E3F),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.t('weekly_report'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white38, size: 14),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildProgressRing(
                    progress: daysProgress,
                    value: '$daysActive',
                    label: AppStrings.t('active_days'),
                    color: Colors.cyanAccent,
                  ),
                  _buildProgressRing(
                    progress: pointsProgress,
                    value: '${manager.totalEarnings.toInt()}',
                    label: AppStrings.t('data_points'),
                    color: Colors.purpleAccent,
                  ),
                  _buildProgressRing(
                    progress: hexProgress,
                    value: '${manager.uniqueHexCount}',
                    label: AppStrings.t('coverage_areas'),
                    color: Colors.greenAccent,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Circular progress ring widget
  Widget _buildProgressRing({
    required double progress,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    color.withValues(alpha: 0.2),
                  ),
                ),
              ),
              // Progress ring
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              // Value text
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Data Quality Statistics Card
  Widget _buildDataQualityCard() {
    final isZh = AppStrings.languageCode == 'zh';

    return Consumer<SensorManager>(
      builder: (context, manager, _) {
        final premium = manager.premiumDataCount;
        final standard = manager.standardDataCount;
        final rejected = manager.rejectedDataCount;
        final total = premium + standard + rejected;
        final qualityRatio = manager.dataQualityRatio;

        // Motion state
        final motionState = manager.motionDetector.currentState;

        String motionLabel;
        Color motionColor;
        IconData motionIcon;

        switch (motionState) {
          case MotionState.stationary:
            motionLabel = isZh ? '静止' : 'Stationary';
            motionColor = Colors.greenAccent;
            motionIcon = Icons.person_pin;
            break;
          case MotionState.walking:
            motionLabel = isZh ? '步行' : 'Walking';
            motionColor = Colors.amber;
            motionIcon = Icons.directions_walk;
            break;
          case MotionState.running:
            motionLabel = isZh ? '跑步' : 'Running';
            motionColor = Colors.orange;
            motionIcon = Icons.directions_run;
            break;
          case MotionState.inVehicle:
            motionLabel = isZh ? '车内' : 'In Vehicle';
            motionColor = Colors.redAccent;
            motionIcon = Icons.directions_car;
            break;
          case MotionState.unknown:
            motionLabel = isZh ? '未知' : 'Unknown';
            motionColor = Colors.grey;
            motionIcon = Icons.help_outline;
            break;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E3F),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics,
                          color: Colors.cyanAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isZh ? '数据质量' : 'Data Quality',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  // Motion Status Chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: motionColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: motionColor.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(motionIcon, color: motionColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          motionLabel,
                          style: TextStyle(color: motionColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quality Bars
              _buildQualityBar(
                label: 'Premium',
                count: premium,
                total: total,
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 8),
              _buildQualityBar(
                label: 'Standard',
                count: standard,
                total: total,
                color: Colors.amber,
              ),
              const SizedBox(height: 8),
              _buildQualityBar(
                label: 'Rejected',
                count: rejected,
                total: total,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),

              // Quality Score
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isZh ? '优质数据比例' : 'Quality Ratio',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    '${(qualityRatio * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: qualityRatio >= 0.7
                          ? Colors.greenAccent
                          : Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // Tip
              if (motionState != MotionState.stationary)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb,
                            color: Colors.amber, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isZh
                                ? '保持静止可获得更高质量数据'
                                : 'Stay still for higher quality data',
                            style: const TextStyle(
                                color: Colors.amber, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityBar({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final ratio = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Quick Tools Section
  Widget _buildQuickToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.t('quick_tools').toUpperCase(),
          style: TextStyle(
            color: Colors.cyanAccent.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildQuickToolItem(
              icon: Icons.graphic_eq,
              label: AppStrings.t('noise_meter'),
              color: Colors.purpleAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NoiseMeterPage()),
              ),
            ),
            _buildQuickToolItem(
              icon: Icons.wifi,
              label: 'WiFi',
              color: Colors.cyanAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WiFiAnalyzerPage()),
              ),
            ),
            _buildQuickToolItem(
              icon: Icons.explore,
              label: AppStrings.t('magnetometer'),
              color: Colors.redAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MagnetometerPage()),
              ),
            ),
            _buildQuickToolItem(
              icon: Icons.map,
              label: AppStrings.t('coverage_map'),
              color: Colors.greenAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HexMapPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickToolItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E3F),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Live Data" tab - Real-time sensor readings
  Widget _buildLiveDataTab() {
    return Consumer<SensorManager>(
      builder: (context, manager, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.t('live_readings').toUpperCase(),
                style: TextStyle(
                  color: Colors.cyanAccent.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              // Primary Metrics
              Row(
                children: [
                  Expanded(
                    child: LiveMetricCard(
                      value: manager.decibel.toStringAsFixed(0),
                      unit: 'dB',
                      label: AppStrings.t('noise'),
                      icon: Icons.graphic_eq,
                      accentColor: Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LiveMetricCard(
                      value: manager.pressure.toStringAsFixed(0),
                      unit: 'hPa',
                      label: AppStrings.t('pressure'),
                      icon: Icons.speed,
                      accentColor: Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LiveMetricCard(
                      value: manager.latency > 0 ? '${manager.latency}' : '--',
                      unit: 'ms',
                      label: AppStrings.t('latency'),
                      icon: Icons.bolt,
                      accentColor: Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Secondary Metrics
              Row(
                children: [
                  Expanded(
                    child: LiveMetricCard(
                      value: '${manager.bluetoothDensity}',
                      unit: '',
                      label: AppStrings.t('bluetooth'),
                      icon: Icons.bluetooth,
                      accentColor: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LiveMetricCard(
                      value: manager.cellSignal != 0
                          ? '${manager.cellSignal}'
                          : '--',
                      unit: 'dBm',
                      label: AppStrings.t('cell_signal'),
                      icon: Icons.signal_cellular_alt,
                      accentColor: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LiveMetricCard(
                      value: manager.jitter > 0
                          ? '${manager.jitter.toStringAsFixed(0)}'
                          : '--',
                      unit: 'ms',
                      label: AppStrings.t('jitter'),
                      icon: Icons.timeline,
                      accentColor: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  /// "How To" tab - Tips and tutorials
  Widget _buildHowToTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTipCard(
            icon: Icons.lightbulb_outline,
            titleKey: 'tip_maximize_title',
            contentKey: 'tip_maximize_content',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            icon: Icons.battery_charging_full,
            titleKey: 'tip_battery_title',
            contentKey: 'tip_battery_content',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            icon: Icons.people,
            titleKey: 'tip_invite_title',
            contentKey: 'tip_invite_content',
          ),
          const SizedBox(height: 12),
          _buildTipCard(
            icon: Icons.star,
            titleKey: 'tip_prime_title',
            contentKey: 'tip_prime_content',
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String titleKey,
    required String contentKey,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.cyanAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.t(titleKey),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.t(contentKey),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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
