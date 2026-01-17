import 'dart:async';
import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import 'network_service.dart';

/// Network Quality Page - Real-time latency, jitter, and packet loss monitoring
/// Works on both iOS and Android
class NetworkQualityPage extends StatefulWidget {
  const NetworkQualityPage({super.key});

  @override
  State<NetworkQualityPage> createState() => _NetworkQualityPageState();
}

class _NetworkQualityPageState extends State<NetworkQualityPage> {
  final NetworkService _networkService = NetworkService();
  Timer? _updateTimer;

  int _latency = 0;
  int _jitter = 0;
  double _packetLoss = 0;
  String _networkType = 'Unknown';
  int _minLatency = 9999;
  int _maxLatency = 0;
  final List<int> _recentLatencies = [];
  static const int _maxReadings = 30;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _startTesting();
  }

  void _startTesting() {
    _runTest();
    _updateTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _runTest());
  }

  Future<void> _runTest() async {
    if (_isTesting) return;
    setState(() => _isTesting = true);

    try {
      _networkType = await _networkService.getNetworkType();
      final quality = await _networkService.measureNetworkQuality(pingCount: 3);

      setState(() {
        _latency = quality['latencyMs'] ?? 0;
        _jitter = quality['jitterMs'] ?? 0;
        _packetLoss = (quality['packetLossPercent'] ?? 0).toDouble();

        if (_latency > 0) {
          if (_latency < _minLatency) _minLatency = _latency;
          if (_latency > _maxLatency) _maxLatency = _latency;

          _recentLatencies.add(_latency);
          if (_recentLatencies.length > _maxReadings) {
            _recentLatencies.removeAt(0);
          }
        }
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Color _getLatencyColor(int latency) {
    if (latency <= 50) return Colors.greenAccent;
    if (latency <= 100) return Colors.cyanAccent;
    if (latency <= 200) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String _getQualityLabel(int latency, bool isZh) {
    if (latency <= 50) return isZh ? '极佳' : 'Excellent';
    if (latency <= 100) return isZh ? '良好' : 'Good';
    if (latency <= 200) return isZh ? '一般' : 'Fair';
    return isZh ? '较差' : 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final isZh = AppStrings.languageCode == 'zh';
    final latencyColor = _getLatencyColor(_latency);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isZh ? '网络质量' : 'Network Quality'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isTesting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Main Latency Display
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
                        latencyColor.withValues(alpha: 0.2),
                        const Color(0xFF1E1E3F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: latencyColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.speed, size: 40, color: latencyColor),
                      const SizedBox(height: 16),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _latency > 0 ? '$_latency' : '--',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: latencyColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const Text(
                        'ms',
                        style: TextStyle(
                          fontSize: 20,
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
                          color: latencyColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _getQualityLabel(_latency, isZh),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: latencyColor,
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
                    painter: LatencyTrendPainter(
                      readings: _recentLatencies,
                      color: latencyColor,
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
                      isZh ? '网络' : 'Network',
                      _networkType,
                      Icons.wifi,
                      Colors.cyanAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '抖动' : 'Jitter',
                      '$_jitter ms',
                      Icons.swap_vert,
                      Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '丢包' : 'Loss',
                      '${_packetLoss.toStringAsFixed(0)}%',
                      Icons.error_outline,
                      _packetLoss > 0 ? Colors.redAccent : Colors.greenAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '最低' : 'Min',
                      _minLatency < 9999 ? '$_minLatency ms' : '--',
                      Icons.arrow_downward,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '最高' : 'Max',
                      _maxLatency > 0 ? '$_maxLatency ms' : '--',
                      Icons.arrow_upward,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Reference Guide
              _buildReferenceGuide(isZh),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isZh ? '延迟参考' : 'Latency Reference',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRefItem('🟢', '<50ms', isZh ? '极佳' : 'Excellent'),
              _buildRefItem('🔵', '<100ms', isZh ? '良好' : 'Good'),
              _buildRefItem('🟠', '<200ms', isZh ? '一般' : 'Fair'),
              _buildRefItem('🔴', '>200ms', isZh ? '较差' : 'Poor'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRefItem(String emoji, String range, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        Text(range, style: const TextStyle(color: Colors.white, fontSize: 9)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 8)),
      ],
    );
  }
}

/// Custom painter for latency trend visualization
class LatencyTrendPainter extends CustomPainter {
  final List<int> readings;
  final Color color;

  LatencyTrendPainter({required this.readings, required this.color});

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

    // Latency range: 0 to 500ms
    const minVal = 0.0;
    const maxVal = 500.0;
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
  bool shouldRepaint(covariant LatencyTrendPainter oldDelegate) {
    return oldDelegate.readings != readings;
  }
}
