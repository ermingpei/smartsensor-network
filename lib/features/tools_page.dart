import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import 'widgets/tool_card.dart';
import 'noise_meter_page.dart';
import 'wifi_analyzer_page.dart';
import 'magnetometer_page.dart';
import 'barometer_page.dart';
import 'cellular_signal_page.dart';
import 'network_quality_page.dart';
import 'bluetooth_scanner_page.dart';

/// Tools Page - Categorized tool cards with sub-tabs
class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Header
            _buildHeader(),
            // Tab Bar
            _buildTabBar(),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildEnvironmentTools(),
                  _buildNetworkTools(),
                  _buildMagneticTools(),
                  _buildOtherTools(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.handyman_rounded,
              color: Colors.cyanAccent, size: 24),
          const SizedBox(width: 12),
          Text(
            AppStrings.t('nav_tools'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        isScrollable: false,
        tabs: [
          Tab(text: AppStrings.t('tools_environment')),
          Tab(text: AppStrings.t('tools_network')),
          Tab(text: AppStrings.t('tools_magnetic')),
          Tab(text: AppStrings.t('tools_other')),
        ],
      ),
    );
  }

  Widget _buildEnvironmentTools() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
                    titleKey: 'pressure',
                    descKey: 'pressure_desc',
                    icon: Icons.speed,
                    gradientColors: const [
                      Color(0xFF2E7D9B),
                      Color(0xFF1A4A5E)
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BarometerPage()),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildNetworkTools() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ToolCard(
                    titleKey: 'network_quality',
                    descKey: 'network_quality_desc',
                    icon: Icons.speed,
                    gradientColors: const [
                      Color(0xFF7B4397),
                      Color(0xFF3D2451)
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NetworkQualityPage()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ToolCard(
                    titleKey: 'nearby_wifi',
                    descKey: 'nearby_wifi_desc',
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
                    titleKey: 'cell_signal',
                    descKey: 'cell_signal_desc',
                    icon: Icons.signal_cellular_alt,
                    gradientColors: const [
                      Color(0xFF3D8B3D),
                      Color(0xFF1F4D1F)
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CellularSignalPage()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1.1,
                  child: ToolCard(
                    titleKey: 'bluetooth_scanner',
                    descKey: 'bluetooth_scanner_desc',
                    icon: Icons.bluetooth_searching,
                    gradientColors: const [
                      Color(0xFF1E88E5),
                      Color(0xFF0D47A1)
                    ],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BluetoothScannerPage()),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMagneticTools() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
              const Expanded(child: SizedBox()), // Placeholder
            ],
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildOtherTools() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Coming Soon placeholder
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E3F),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.construction,
                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.t('tools_coming_soon'),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
