import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_strings.dart';
import '../core/sensor_manager.dart';
import '../core/auth_service.dart';
import 'widgets/tool_card.dart';
import 'widgets/qbit_icon.dart';
import 'debug_dashboard.dart';
import 'hex_map_page.dart';
import 'noise_meter_page.dart';
import 'wifi_analyzer_page.dart';
import 'magnetometer_page.dart';
import 'barometer_page.dart';
import 'light_sensor_page.dart';
import 'step_counter_page.dart';
import 'about_page.dart';
import 'onboarding_page.dart';
import 'auth_page.dart';

/// Toolbox Home Page - Main entry point showing sensor tools as cards
class ToolboxHomePage extends StatefulWidget {
  const ToolboxHomePage({super.key});

  @override
  State<ToolboxHomePage> createState() => _ToolboxHomePageState();
}

class _ToolboxHomePageState extends State<ToolboxHomePage> {
  @override
  Widget build(BuildContext context) {
    // Deep gradient background matching reference design
    const bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0D0D1A), // Deep navy
        Color(0xFF1A1A3E), // Purple tint
        Color(0xFF0D0D1A),
      ],
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(child: _buildAppBar()),

              // Status Banner (Sensing ON/OFF)
              SliverToBoxAdapter(child: _buildStatusBanner()),

              // Live Sensor Readings
              SliverToBoxAdapter(child: _buildLiveSensorSection()),

              // Tool Cards Grid
              SliverToBoxAdapter(child: _buildToolsSection()),

              // Device Sensors Showcase
              SliverToBoxAdapter(child: _buildSensorShowcase()),

              // Earnings Quick Access
              SliverToBoxAdapter(child: _buildEarningsCard()),

              // Bottom Padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + Title
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    Image.asset('assets/icon/icon.png', width: 36, height: 36),
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
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Consumer<SensorManager>(
      builder: (context, manager, _) {
        final isActive = manager.isSampling;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [const Color(0xFF2E5B2E), const Color(0xFF1A3D1A)]
                  : [const Color(0xFF2D2D4A), const Color(0xFF1E1E3F)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Colors.greenAccent.withValues(alpha: 0.5)
                  : Colors.purpleAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isActive ? Icons.sensors : Icons.sensors_off,
                    color: isActive ? Colors.greenAccent : Colors.white54,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t('toolbox_title'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${AppStrings.t('data_contribution')}: ${isActive ? "ON" : "OFF"}',
                        style: TextStyle(
                          color: isActive ? Colors.greenAccent : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Quick toggle indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? Colors.greenAccent : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'IDLE',
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveSensorSection() {
    return Consumer<SensorManager>(
      builder: (context, manager, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.t('tools').toUpperCase(),
            style: TextStyle(
              color: Colors.cyanAccent.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          // 2x2 Grid of tools
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ToolCard(
                    titleKey: 'noise_meter',
                    descKey: 'noise_meter_desc',
                    icon: Icons.graphic_eq,
                    gradientColors: const [
                      Color(0xFF6B48FF),
                      Color(0xFF3D2B8C)
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NoiseMeterPage()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ToolCard(
                    titleKey: 'wifi_analyzer',
                    descKey: 'wifi_analyzer_desc',
                    icon: Icons.wifi,
                    gradientColors: const [
                      Color(0xFF2E7D9B),
                      Color(0xFF1A4A5E)
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WiFiAnalyzerPage()),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ToolCard(
                    titleKey: 'magnetometer',
                    descKey: 'magnetometer_desc',
                    icon: Icons.explore,
                    gradientColors: const [
                      Color(0xFFB44D4D),
                      Color(0xFF6B2D2D)
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MagnetometerPage()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ToolCard(
                    titleKey: 'coverage_map',
                    descKey: 'map_desc',
                    icon: Icons.map,
                    gradientColors: const [
                      Color(0xFF3D8B3D),
                      Color(0xFF1F4D1F)
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => HexMapPage()),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 3rd row: Barometer
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ToolCard(
                    titleKey: 'barometer',
                    descKey: 'barometer_desc',
                    icon: Icons.speed,
                    gradientColors: const [
                      Color(0xFF4A9D9A),
                      Color(0xFF2D5F5E)
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BarometerPage()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Light Sensor
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ToolCard(
                    titleKey: 'light_sensor',
                    descKey: 'light_sensor_desc',
                    icon: Icons.wb_sunny,
                    gradientColors: const [
                      Color(0xFFFFB347),
                      Color(0xFFD68F00)
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LightSensorPage()),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 4th row: Step Counter
              Row(
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1.1,
                      child: ToolCard(
                        titleKey: 'step_counter',
                        descKey: 'step_counter_desc',
                        icon: Icons.directions_walk,
                        gradientColors: const [
                          Color(0xFF4CAF50),
                          Color(0xFF2E7D32)
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const StepCounterPage()),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Empty space for future tool
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorShowcase() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.memory, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                AppStrings.t('your_sensors').toUpperCase(),
                style: TextStyle(
                  color: Colors.cyanAccent.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.t('sensors_idle_hint'),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Accelerometer
                StreamBuilder<AccelerometerEvent>(
                  stream: accelerometerEventStream(),
                  builder: (context, snapshot) {
                    return SensorStatusChip(
                      label: AppStrings.t('sensor_accelerometer'),
                      icon: Icons.vibration,
                      color: Colors.orange,
                      status: snapshot.hasData ? 'Active' : 'Ready',
                    );
                  },
                ),
                const SizedBox(width: 8),
                SensorStatusChip(
                  label: AppStrings.t('sensor_gyroscope'),
                  icon: Icons.rotate_right,
                  color: Colors.blue,
                  status: 'Ready',
                ),
                const SizedBox(width: 8),
                SensorStatusChip(
                  label: AppStrings.t('sensor_magnetometer'),
                  icon: Icons.explore,
                  color: Colors.red,
                  status: 'Ready',
                ),
                const SizedBox(width: 8),
                SensorStatusChip(
                  label: AppStrings.t('sensor_pressure'),
                  icon: Icons.speed,
                  color: Colors.cyan,
                  status: 'Ready',
                ),
                const SizedBox(width: 8),
                SensorStatusChip(
                  label: AppStrings.t('sensor_audio'),
                  icon: Icons.mic,
                  color: Colors.purple,
                  status: 'Ready',
                ),
                const SizedBox(width: 8),
                SensorStatusChip(
                  label: AppStrings.t('sensor_gps'),
                  icon: Icons.location_on,
                  color: Colors.green,
                  status: 'Ready',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard() {
    return Consumer<SensorManager>(
      builder: (context, manager, _) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DebugDashboard()),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D2D4A), Color(0xFF1E1E3F)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                // QBit Icon
                const QBitIcon(size: 48),
                const SizedBox(width: 16),
                // Earnings Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t('earning_dashboard'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${manager.totalEarnings.toStringAsFixed(2)} QBit',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        AppStrings.t('earning_dashboard_desc'),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white38, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(AppStrings.t('settings_title'),
            style: const TextStyle(color: Colors.white)),
        children: [
          ListTile(
            leading: const Icon(Icons.info, color: Colors.cyanAccent),
            title: Text(AppStrings.t('about'),
                style: const TextStyle(color: Colors.white70)),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => AboutPage()));
            },
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '...';
              return ListTile(
                leading: const Icon(Icons.verified, color: Colors.cyanAccent),
                title: Text(AppStrings.t('version'),
                    style: const TextStyle(color: Colors.white70)),
                subtitle: Text("v$version",
                    style: const TextStyle(color: Colors.white54)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Colors.cyanAccent),
            title: Text(AppStrings.t('privacy_policy'),
                style: const TextStyle(color: Colors.white70)),
            onTap: () async {
              Navigator.pop(ctx);
              final Uri url = Uri.parse(
                  'https://smartsensor.yourcompany.com/dashboard/privacy.html');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restart_alt, color: Colors.orangeAccent),
            title: Text(AppStrings.t('replay_tutorial'),
                style: const TextStyle(color: Colors.white70)),
            onTap: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('seenOnboarding', false);
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => OnboardingPage()));
            },
          ),
          // Auth Status & Logout
          Consumer<AuthService>(
            builder: (context, authService, _) {
              if (authService.isLoggedIn) {
                return ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: Text(AppStrings.t('logout'),
                      style: const TextStyle(color: Colors.white70)),
                  subtitle: Text(
                    authService.currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthPage(
                            onAuthSuccess: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ToolboxHomePage(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  },
                );
              } else if (authService.isAnonymous) {
                return ListTile(
                  leading: const Icon(Icons.login, color: Colors.cyanAccent),
                  title: Text(AppStrings.t('login_to_sync'),
                      style: const TextStyle(color: Colors.white70)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthPage(
                          onAuthSuccess: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}
