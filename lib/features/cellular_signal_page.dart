import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/sensor_manager.dart';
import '../core/app_strings.dart';

/// Cellular Signal Page - Real-time signal strength monitoring
class CellularSignalPage extends StatefulWidget {
  const CellularSignalPage({super.key});

  @override
  State<CellularSignalPage> createState() => _CellularSignalPageState();
}

class _CellularSignalPageState extends State<CellularSignalPage> {
  Timer? _updateTimer;
  int _signalStrength = 0;
  String _networkType = 'Unknown';
  int _minSignal = 9999;
  int _maxSignal = -9999;
  final List<int> _recentReadings = [];
  static const int _maxReadings = 50;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final manager = Provider.of<SensorManager>(context, listen: false);
      setState(() {
        _signalStrength = manager.cellSignal;
        _networkType = manager.cellType;

        if (_signalStrength > 0) {
          if (_signalStrength < _minSignal) _minSignal = _signalStrength;
          if (_signalStrength > _maxSignal) _maxSignal = _signalStrength;

          _recentReadings.add(_signalStrength);
          if (_recentReadings.length > _maxReadings) {
            _recentReadings.removeAt(0);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Color _getSignalColor(int signal) {
    if (signal >= -50) return Colors.greenAccent;
    if (signal >= -70) return Colors.cyanAccent;
    if (signal >= -85) return Colors.orangeAccent;
    if (signal >= -100) return Colors.deepOrangeAccent;
    return Colors.redAccent;
  }

  String _getSignalQuality(int signal, bool isZh) {
    if (signal >= -50) return isZh ? '优秀' : 'Excellent';
    if (signal >= -70) return isZh ? '良好' : 'Good';
    if (signal >= -85) return isZh ? '一般' : 'Fair';
    if (signal >= -100) return isZh ? '较弱' : 'Weak';
    return isZh ? '很差' : 'Poor';
  }

  int _getSignalBars(int signal) {
    if (signal >= -50) return 5;
    if (signal >= -70) return 4;
    if (signal >= -85) return 3;
    if (signal >= -100) return 2;
    if (signal >= -110) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isZh = AppStrings.languageCode == 'zh';
    final signalColor = _getSignalColor(_signalStrength);
    final bars = _getSignalBars(_signalStrength);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isZh ? '蜂窝信号' : 'Cellular Signal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: !Platform.isAndroid
            ? _buildIOSLimitationMessage(isZh)
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Main Signal Display
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
                              signalColor.withValues(alpha: 0.2),
                              const Color(0xFF1E1E3F),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: signalColor.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Signal Bars
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(5, (index) {
                                final height = 12.0 + (index * 8);
                                final active = index < bars;
                                return Container(
                                  width: 12,
                                  height: height,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color:
                                        active ? signalColor : Colors.white24,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 24),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _signalStrength == 0
                                    ? '--'
                                    : '$_signalStrength',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: signalColor,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const Text(
                              'dBm',
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
                                color: signalColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getSignalQuality(_signalStrength, isZh),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: signalColor,
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
                          painter: SignalTrendPainter(
                            readings: _recentReadings,
                            color: signalColor,
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
                            isZh ? '网络类型' : 'Type',
                            _networkType.isEmpty ? '--' : _networkType,
                            Icons.cell_tower,
                            Colors.cyanAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            isZh ? '最弱' : 'Weakest',
                            _minSignal < 9999 ? '$_minSignal dBm' : '--',
                            Icons.arrow_downward,
                            Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            isZh ? '最强' : 'Strongest',
                            _maxSignal > -9999 ? '$_maxSignal dBm' : '--',
                            Icons.arrow_upward,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Reference Guide
                    _buildReferenceGuide(isZh),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildIOSLimitationMessage(bool isZh) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cell_tower,
              color: Colors.orangeAccent.withValues(alpha: 0.5),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              isZh ? 'iOS 限制' : 'iOS Limitation',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isZh
                  ? 'iOS 系统不允许应用访问原始蜂窝信号数据。此功能仅在 Android 设备上可用。'
                  : 'iOS does not allow apps to access raw cellular signal data. This feature is only available on Android devices.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb,
                      color: Colors.cyanAccent, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      isZh
                          ? '提示：您仍可以在设置中查看信号强度'
                          : 'Tip: You can view signal in Settings',
                      style: const TextStyle(
                          color: Colors.cyanAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildReferenceGuide(bool isZh) {
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
            isZh ? '信号强度参考' : 'Signal Reference',
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
              _buildRefItem('📶', '>-50', isZh ? '优秀' : 'Excellent'),
              _buildRefItem('📶', '-70', isZh ? '良好' : 'Good'),
              _buildRefItem('📶', '-85', isZh ? '一般' : 'Fair'),
              _buildRefItem('📶', '<-100', isZh ? '较差' : 'Poor'),
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

/// Custom painter for signal trend visualization
class SignalTrendPainter extends CustomPainter {
  final List<int> readings;
  final Color color;

  SignalTrendPainter({required this.readings, required this.color});

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

    // dBm range: -120 (weak) to -50 (strong)
    const minVal = -120.0;
    const maxVal = -30.0;
    const range = maxVal - minVal;

    final path = Path();
    final fillPath = Path();
    final width = size.width / readings.length;

    for (int i = 0; i < readings.length; i++) {
      final x = i * width;
      final normalizedValue = (readings[i] - minVal) / range;
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
  bool shouldRepaint(covariant SignalTrendPainter oldDelegate) {
    return oldDelegate.readings != readings;
  }
}
