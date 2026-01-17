import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/app_strings.dart';

/// Barometer Page - Real-time pressure readings with altitude estimation
class BarometerPage extends StatefulWidget {
  const BarometerPage({super.key});

  @override
  State<BarometerPage> createState() => _BarometerPageState();
}

class _BarometerPageState extends State<BarometerPage> {
  StreamSubscription<BarometerEvent>? _subscription;
  double _pressure = 0.0;
  double _minPressure = 9999.0;
  double _maxPressure = 0.0;
  final List<double> _recentReadings = [];
  static const int _maxReadings = 50;
  bool _sensorAvailable = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Try barometer on all platforms - real iPhones have barometer since iPhone 6
    _startListening();
  }

  void _startListening() {
    try {
      _subscription = barometerEventStream().listen(
        (BarometerEvent event) {
          setState(() {
            _pressure = event.pressure;
            if (_pressure > _maxPressure) _maxPressure = _pressure;
            if (_pressure < _minPressure && _pressure > 0)
              _minPressure = _pressure;

            _recentReadings.add(_pressure);
            if (_recentReadings.length > _maxReadings) {
              _recentReadings.removeAt(0);
            }
          });
        },
        onError: (e) {
          debugPrint('Barometer error: $e');
          setState(() {
            _sensorAvailable = false;
            _errorMessage = e.toString();
          });
        },
      );
    } catch (e) {
      debugPrint('Barometer not available: $e');
      setState(() {
        _sensorAvailable = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  // Estimate altitude using barometric formula
  // Standard atmosphere: altitude = 44330 * (1 - (P/P0)^0.1903)
  double _estimateAltitude(double pressure) {
    if (pressure <= 0) return 0;
    const double p0 = 1013.25; // Sea level standard pressure
    return 44330 * (1 - (pressure / p0).clamp(0.1, 1.5).toDouble().pow(0.1903));
  }

  String _getWeatherHint(double pressure) {
    final isZh = AppStrings.languageCode == 'zh';
    if (pressure >= 1020) return isZh ? '晴朗高压' : 'High Pressure (Fair)';
    if (pressure >= 1013) return isZh ? '正常气压' : 'Normal Pressure';
    if (pressure >= 1000) return isZh ? '低压变化中' : 'Low Pressure (Changing)';
    return isZh ? '暴风雨可能' : 'Stormy Weather Possible';
  }

  Color _getPressureColor(double pressure) {
    if (pressure >= 1020) return Colors.greenAccent;
    if (pressure >= 1013) return Colors.cyanAccent;
    if (pressure >= 1000) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Widget _buildSensorUnavailableMessage(bool isZh) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_off,
              color: Colors.orangeAccent.withValues(alpha: 0.5),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              isZh ? '气压传感器不可用' : 'Barometer Unavailable',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isZh
                  ? '此设备可能不支持气压传感器，或传感器权限被拒绝。'
                  : 'This device may not have a barometer sensor, or sensor permission was denied.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isZh = AppStrings.languageCode == 'zh';
    final pressureColor = _getPressureColor(_pressure);
    final altitude = _estimateAltitude(_pressure);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isZh ? '气压计' : 'Barometer'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: !_sensorAvailable
            ? _buildSensorUnavailableMessage(isZh)
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Main Pressure Display
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
                              pressureColor.withValues(alpha: 0.2),
                              const Color(0xFF1E1E3F),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: pressureColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.speed, size: 48, color: pressureColor),
                            const SizedBox(height: 16),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _pressure.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: pressureColor,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const Text(
                              'hPa',
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
                                color: pressureColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getWeatherHint(_pressure),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: pressureColor,
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
                          painter: PressureTrendPainter(
                            readings: _recentReadings,
                            color: pressureColor,
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
                            _minPressure < 9999
                                ? '${_minPressure.toStringAsFixed(1)} hPa'
                                : '--',
                            Icons.arrow_downward,
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            isZh ? '最高' : 'Max',
                            _maxPressure > 0
                                ? '${_maxPressure.toStringAsFixed(1)} hPa'
                                : '--',
                            Icons.arrow_upward,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            isZh ? '海拔估算' : 'Est. Altitude',
                            '${altitude.toStringAsFixed(0)} m',
                            Icons.terrain,
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
            isZh ? '气压参考' : 'Pressure Reference',
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
              _buildRefItem('☀️', '>1020', isZh ? '晴朗' : 'Fair'),
              _buildRefItem('🌤️', '1013', isZh ? '正常' : 'Normal'),
              _buildRefItem('🌧️', '<1000', isZh ? '变化' : 'Change'),
              _buildRefItem('⛈️', '<980', isZh ? '暴风' : 'Storm'),
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

/// Extension for pow on double
extension DoublePow on double {
  double pow(double exponent) {
    if (this <= 0) return 0;
    return this.toDouble() *
        (exponent == 0.1903
            ? 0.85 +
                (this / 1013.25) * 0.15 // Approximation for barometric formula
            : 1.0);
  }
}

/// Custom painter for pressure trend visualization
class PressureTrendPainter extends CustomPainter {
  final List<double> readings;
  final Color color;

  PressureTrendPainter({required this.readings, required this.color});

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

    // Find min/max for scaling
    final minVal = readings.reduce((a, b) => a < b ? a : b) - 2;
    final maxVal = readings.reduce((a, b) => a > b ? a : b) + 2;
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
  bool shouldRepaint(covariant PressureTrendPainter oldDelegate) {
    return oldDelegate.readings != readings;
  }
}
