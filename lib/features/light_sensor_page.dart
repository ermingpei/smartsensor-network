import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ambient_light/ambient_light.dart';
import '../core/app_strings.dart';

/// Light Sensor Page - Real-time ambient light measurement
class LightSensorPage extends StatefulWidget {
  const LightSensorPage({super.key});

  @override
  State<LightSensorPage> createState() => _LightSensorPageState();
}

class _LightSensorPageState extends State<LightSensorPage> {
  StreamSubscription<double>? _subscription;
  double _lux = 0.0;
  double _maxLux = 0.0;
  double _minLux = 9999.0;
  final List<double> _recentReadings = [];
  static const int _maxReadings = 50;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    try {
      _subscription = AmbientLight().ambientLightStream.listen(
        (double lux) {
          setState(() {
            _lux = lux;
            if (_lux > _maxLux) _maxLux = _lux;
            if (_lux < _minLux && _lux > 0) _minLux = _lux;

            _recentReadings.add(_lux);
            if (_recentReadings.length > _maxReadings) {
              _recentReadings.removeAt(0);
            }
          });
        },
        onError: (e) {
          debugPrint('Light sensor error: $e');
        },
      );
    } catch (e) {
      debugPrint('Light sensor not available: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _getLightLevel(double lux) {
    final isZh = AppStrings.languageCode == 'zh';
    if (lux < 10) return isZh ? '非常暗' : 'Very Dark';
    if (lux < 50) return isZh ? '昏暗' : 'Dim';
    if (lux < 200) return isZh ? '室内正常' : 'Indoor Normal';
    if (lux < 500) return isZh ? '明亮室内' : 'Bright Indoor';
    if (lux < 1000) return isZh ? '阴天室外' : 'Cloudy Outdoor';
    if (lux < 10000) return isZh ? '晴天阴影' : 'Sunny Shade';
    if (lux < 50000) return isZh ? '阳光直射' : 'Direct Sunlight';
    return isZh ? '极强光照' : 'Extreme Bright';
  }

  Color _getLuxColor(double lux) {
    if (lux < 50) return Colors.indigo;
    if (lux < 200) return Colors.blue;
    if (lux < 500) return Colors.cyan;
    if (lux < 1000) return Colors.green;
    if (lux < 10000) return Colors.yellow;
    if (lux < 50000) return Colors.orange;
    return Colors.red;
  }

  IconData _getLuxIcon(double lux) {
    if (lux < 50) return Icons.nightlight_round;
    if (lux < 500) return Icons.lightbulb_outline;
    if (lux < 5000) return Icons.wb_cloudy;
    return Icons.wb_sunny;
  }

  @override
  Widget build(BuildContext context) {
    final isZh = AppStrings.languageCode == 'zh';
    final luxColor = _getLuxColor(_lux);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isZh ? '光照传感器' : 'Light Sensor'),
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
              // Main Lux Display
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        luxColor.withValues(alpha: 0.2),
                        const Color(0xFF1E1E3F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: luxColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_getLuxIcon(_lux), size: 56, color: luxColor),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _lux.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                            color: luxColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const Text(
                        'lux',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: luxColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getLightLevel(_lux),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: luxColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
                    painter: LuxTrendPainter(
                      readings: _recentReadings,
                      color: luxColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '最低' : 'Min',
                      _minLux < 9999
                          ? '${_minLux.toStringAsFixed(0)} lux'
                          : '--',
                      Icons.arrow_downward,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '最高' : 'Max',
                      _maxLux > 0 ? '${_maxLux.toStringAsFixed(0)} lux' : '--',
                      Icons.arrow_upward,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '平均' : 'Avg',
                      _recentReadings.isNotEmpty
                          ? '${(_recentReadings.reduce((a, b) => a + b) / _recentReadings.length).toStringAsFixed(0)} lux'
                          : '--',
                      Icons.equalizer,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reference Guide
              _buildReferenceGuide(),
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
          const SizedBox(height: 6),
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

  Widget _buildReferenceGuide() {
    final isZh = AppStrings.languageCode == 'zh';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '光照参考' : 'Light Reference',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRefItem('🌙', '<50', isZh ? '昏暗' : 'Dim'),
              _buildRefItem('💡', '200', isZh ? '室内' : 'Indoor'),
              _buildRefItem('⛅', '1000', isZh ? '阴天' : 'Cloudy'),
              _buildRefItem('☀️', '>10k', isZh ? '阳光' : 'Sunny'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefItem(String emoji, String range, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        Text(range, style: const TextStyle(color: Colors.white, fontSize: 10)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}

/// Custom painter for lux trend visualization
class LuxTrendPainter extends CustomPainter {
  final List<double> readings;
  final Color color;

  LuxTrendPainter({required this.readings, required this.color});

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

    // Find min/max for scaling (use log scale for large ranges)
    final maxVal = readings.reduce((a, b) => a > b ? a : b) + 10;
    final minVal = readings.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    final path = Path();
    final fillPath = Path();
    final width = size.width / readings.length;

    for (int i = 0; i < readings.length; i++) {
      final x = i * width;
      final normalizedValue = range > 0 ? (readings[i] - minVal) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);

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
  bool shouldRepaint(covariant LuxTrendPainter oldDelegate) {
    return oldDelegate.readings != readings;
  }
}
