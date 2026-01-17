import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import '../core/app_strings.dart';

/// Noise Meter Page - Large display with real-time decibel readings
class NoiseMeterPage extends StatefulWidget {
  const NoiseMeterPage({super.key});

  @override
  State<NoiseMeterPage> createState() => _NoiseMeterPageState();
}

class _NoiseMeterPageState extends State<NoiseMeterPage> {
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  double _currentDecibel = 0.0;
  double _maxDecibel = 0.0;
  double _minDecibel = 999.0;
  final List<double> _recentReadings = [];
  static const int _maxReadings = 50;
  bool _sensorAvailable = true;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    try {
      _noiseMeter = NoiseMeter();
      _noiseSubscription = _noiseMeter!.noise.listen(
        (NoiseReading reading) {
          setState(() {
            _currentDecibel = reading.meanDecibel;
            if (_currentDecibel > _maxDecibel) _maxDecibel = _currentDecibel;
            if (_currentDecibel < _minDecibel && _currentDecibel > 0) {
              _minDecibel = _currentDecibel;
            }
            _recentReadings.add(_currentDecibel);
            if (_recentReadings.length > _maxReadings) {
              _recentReadings.removeAt(0);
            }
          });
        },
        onError: (e) {
          debugPrint('Noise meter error: $e');
          setState(() => _sensorAvailable = false);
        },
      );
    } catch (e) {
      debugPrint('Microphone not available: $e');
      setState(() => _sensorAvailable = false);
    }
  }

  @override
  void dispose() {
    _noiseSubscription?.cancel();
    super.dispose();
  }

  String _getNoiseLevel(double db) {
    if (db < 30) return AppStrings.t('noise_level_quiet');
    if (db < 50) return AppStrings.t('noise_level_normal');
    if (db < 70) return AppStrings.t('noise_level_moderate');
    if (db < 90) return AppStrings.t('noise_level_loud');
    return AppStrings.t('noise_level_dangerous');
  }

  Color _getNoiseLevelColor(double db) {
    if (db < 30) return Colors.green;
    if (db < 50) return Colors.lightGreen;
    if (db < 70) return Colors.yellow;
    if (db < 90) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getNoiseLevelColor(_currentDecibel);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppStrings.t('noise_meter')),
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
              // Main Decibel Display
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
                        levelColor.withValues(alpha: 0.2),
                        const Color(0xFF1E1E3F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: levelColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.graphic_eq,
                        size: 48,
                        color: levelColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _currentDecibel.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Text(
                        'dB',
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
                          color: levelColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getNoiseLevel(_currentDecibel),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: levelColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Waveform Visualization
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
                    painter: WaveformPainter(
                      readings: _recentReadings,
                      color: levelColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Min/Max Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      AppStrings.t('min_value'),
                      _minDecibel < 999
                          ? '${_minDecibel.toStringAsFixed(1)} dB'
                          : '--',
                      Icons.arrow_downward,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      AppStrings.t('max_value'),
                      '${_maxDecibel.toStringAsFixed(1)} dB',
                      Icons.arrow_upward,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Noise Reference Guide
              _buildNoiseReferenceGuide(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text(value,
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoiseReferenceGuide() {
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
            AppStrings.t('noise_reference'),
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRefItem('🤫', '<30dB', AppStrings.t('noise_ref_whisper')),
              _buildRefItem('🗣️', '50-70dB', AppStrings.t('noise_ref_talk')),
              _buildRefItem('🚗', '70-90dB', AppStrings.t('noise_ref_traffic')),
              _buildRefItem('⚠️', '>90dB', AppStrings.t('noise_ref_danger')),
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

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final List<double> readings;
  final Color color;

  WaveformPainter({required this.readings, required this.color});

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

    final path = Path();
    final fillPath = Path();
    final width = size.width / readings.length;

    for (int i = 0; i < readings.length; i++) {
      final x = i * width;
      final normalizedValue = (readings[i].clamp(0, 120) / 120);
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
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.readings != readings;
  }
}
