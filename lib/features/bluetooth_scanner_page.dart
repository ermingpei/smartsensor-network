import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/sensor_manager.dart';
import '../core/app_strings.dart';

/// Bluetooth Scanner Page - Shows nearby Bluetooth device count
/// Works on both iOS and Android
class BluetoothScannerPage extends StatefulWidget {
  const BluetoothScannerPage({super.key});

  @override
  State<BluetoothScannerPage> createState() => _BluetoothScannerPageState();
}

class _BluetoothScannerPageState extends State<BluetoothScannerPage> {
  Timer? _updateTimer;
  int _deviceCount = 0;
  int _minCount = 9999;
  int _maxCount = 0;
  final List<int> _recentCounts = [];
  static const int _maxReadings = 30;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _updateData();
    _updateTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _updateData());
  }

  void _updateData() {
    final manager = Provider.of<SensorManager>(context, listen: false);
    setState(() {
      _deviceCount = manager.bluetoothDensity;

      if (_deviceCount > 0) {
        if (_deviceCount < _minCount) _minCount = _deviceCount;
        if (_deviceCount > _maxCount) _maxCount = _deviceCount;

        _recentCounts.add(_deviceCount);
        if (_recentCounts.length > _maxReadings) {
          _recentCounts.removeAt(0);
        }
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Color _getDensityColor(int count) {
    if (count >= 20) return Colors.redAccent;
    if (count >= 10) return Colors.orangeAccent;
    if (count >= 5) return Colors.cyanAccent;
    if (count >= 1) return Colors.greenAccent;
    return Colors.grey;
  }

  String _getDensityLabel(int count, bool isZh) {
    if (count >= 20) return isZh ? '非常拥挤' : 'Very Crowded';
    if (count >= 10) return isZh ? '拥挤' : 'Crowded';
    if (count >= 5) return isZh ? '中等' : 'Moderate';
    if (count >= 1) return isZh ? '稀疏' : 'Sparse';
    return isZh ? '无设备' : 'No Devices';
  }

  @override
  Widget build(BuildContext context) {
    final isZh = AppStrings.languageCode == 'zh';
    final densityColor = _getDensityColor(_deviceCount);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isZh ? '蓝牙扫描' : 'Bluetooth Scanner'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Main Display
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        densityColor.withValues(alpha: 0.3),
                        const Color(0xFF1E1E3F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: densityColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_searching,
                          size: 48, color: densityColor),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$_deviceCount',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: densityColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      Text(
                        isZh ? '设备' : 'devices',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: densityColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getDensityLabel(_deviceCount, isZh),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: densityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Trend Graph
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E3F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomPaint(
                    painter: BluetoothTrendPainter(
                      readings: _recentCounts,
                      color: densityColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '最少' : 'Min',
                      _minCount < 9999 ? '$_minCount' : '--',
                      Icons.arrow_downward,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '最多' : 'Max',
                      _maxCount > 0 ? '$_maxCount' : '--',
                      Icons.arrow_upward,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '平均' : 'Avg',
                      _recentCounts.isNotEmpty
                          ? (_recentCounts.reduce((a, b) => a + b) ~/
                                  _recentCounts.length)
                              .toString()
                          : '--',
                      Icons.analytics,
                      Colors.purpleAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.cyanAccent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isZh
                            ? '蓝牙设备密度可以反映周围环境的人流量和拥挤程度'
                            : 'Bluetooth density reflects crowd level and traffic in your area',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for bluetooth trend visualization
class BluetoothTrendPainter extends CustomPainter {
  final List<int> readings;
  final Color color;

  BluetoothTrendPainter({required this.readings, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final maxVal = (readings.reduce((a, b) => a > b ? a : b) + 5).toDouble();
    const minVal = 0.0;
    final range = maxVal - minVal;

    final path = Path();
    final fillPath = Path();
    final width = size.width / readings.length;

    for (int i = 0; i < readings.length; i++) {
      final x = i * width;
      final normalizedValue = range > 0 ? (readings[i] - minVal) / range : 0.5;
      final y = size.height - (normalizedValue.clamp(0.0, 1.0) * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BluetoothTrendPainter oldDelegate) {
    return oldDelegate.readings != readings;
  }
}
