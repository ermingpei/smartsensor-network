import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../core/app_strings.dart';

/// Magnetometer/Metal Detector Page - Real-time magnetic field detection
class MagnetometerPage extends StatefulWidget {
  const MagnetometerPage({super.key});

  @override
  State<MagnetometerPage> createState() => _MagnetometerPageState();
}

class _MagnetometerPageState extends State<MagnetometerPage> {
  StreamSubscription<MagnetometerEvent>? _subscription;
  double _magnitude = 0.0;
  double _maxMagnitude = 0.0;
  double _baseline = 50.0; // Earth's magnetic field is ~25-65 µT
  bool _isCalibrated = false;
  final List<double> _recentReadings = [];
  static const int _maxReadings = 30;
  bool _sensorAvailable = true;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    try {
      _subscription = magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          final magnitude =
              sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

          setState(() {
            _magnitude = magnitude;
            if (magnitude > _maxMagnitude) _maxMagnitude = magnitude;

            _recentReadings.add(magnitude);
            if (_recentReadings.length > _maxReadings) {
              _recentReadings.removeAt(0);
            }

            // Auto-calibrate baseline from first readings
            if (!_isCalibrated && _recentReadings.length >= 10) {
              _baseline = _recentReadings.take(10).reduce((a, b) => a + b) / 10;
              _isCalibrated = true;
            }
          });
        },
        onError: (e) {
          debugPrint('Magnetometer error: $e');
          setState(() => _sensorAvailable = false);
        },
      );
    } catch (e) {
      debugPrint('Magnetometer not available: $e');
      setState(() => _sensorAvailable = false);
    }
  }

  void _calibrate() {
    if (_recentReadings.length >= 5) {
      setState(() {
        _baseline = _recentReadings.take(5).reduce((a, b) => a + b) / 5;
        _maxMagnitude = _baseline;
        _isCalibrated = true;
      });
      // Show feedback to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${AppStrings.t('calibrate')}: ${_baseline.toStringAsFixed(1)} µT'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // Not enough readings yet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.languageCode == 'zh'
              ? '请稍等，正在收集数据...'
              : 'Please wait, collecting data...'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  double get _detection => (_magnitude - _baseline).abs();

  // Use smoothed detection from recent readings
  double get _smoothedDetection {
    if (_recentReadings.length < 5) return _detection;
    final recentAvg = _recentReadings
            .skip(_recentReadings.length - 5)
            .reduce((a, b) => a + b) /
        5;
    return (recentAvg - _baseline).abs();
  }

  // Hysteresis: higher threshold to trigger, lower to clear
  // This prevents flickering between detected/not detected states
  bool _metalDetectedState = false;

  bool get _isMetalDetected {
    if (!_isCalibrated || _magnitude <= 0) return false;

    final detection = _smoothedDetection;

    // Hysteresis: 30 to trigger on, 15 to trigger off
    if (_metalDetectedState) {
      // Currently detected - need to drop below 15 to clear
      if (detection < 15) {
        _metalDetectedState = false;
      }
    } else {
      // Currently not detected - need to rise above 30 to detect
      if (detection > 30) {
        _metalDetectedState = true;
      }
    }

    return _metalDetectedState;
  }

  Color get _indicatorColor {
    final detection = _smoothedDetection;
    if (detection < 10) return Colors.green;
    if (detection < 30) return Colors.yellow;
    if (detection < 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppStrings.t('magnetometer')),
        actions: [
          TextButton.icon(
            onPressed: _calibrate,
            icon: const Icon(Icons.tune, color: Colors.cyanAccent, size: 18),
            label: Text(
              AppStrings.t('calibrate'),
              style: const TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Main Detection Display
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        _indicatorColor.withValues(alpha: 0.3),
                        const Color(0xFF1E1E3F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: _indicatorColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Metal Detection Indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 120 + (_detection * 0.5).clamp(0, 80),
                        height: 120 + (_detection * 0.5).clamp(0, 80),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _indicatorColor,
                              _indicatorColor.withValues(alpha: 0.3),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _indicatorColor.withValues(alpha: 0.5),
                              blurRadius: 30 + _detection,
                              spreadRadius: _detection * 0.2,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isMetalDetected ? Icons.warning : Icons.explore,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Magnitude Display
                      Text(
                        _magnitude.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: _indicatorColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Text(
                        'µT',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Status Text
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _indicatorColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _isMetalDetected
                              ? AppStrings.t('metal_detected')
                              : AppStrings.t('no_metal'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _indicatorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Detection Meter
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3F),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.t('detection_level'),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        Text(
                          '${_detection.toStringAsFixed(1)} µT',
                          style: TextStyle(
                            color: _indicatorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (_detection / 100).clamp(0, 1),
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation(_indicatorColor),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      AppStrings.t('baseline'),
                      '${_baseline.toStringAsFixed(1)} µT',
                      Icons.straighten,
                      Colors.cyan,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      AppStrings.t('max_value'),
                      '${_maxMagnitude.toStringAsFixed(1)} µT',
                      Icons.arrow_upward,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Usage Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E3F),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t('magnetometer_tips'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.t('magnetometer_tips_desc'),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                Text(
                  value,
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
