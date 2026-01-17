import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_strings.dart';
import '../core/motion_detector.dart';
import '../core/sensor_manager.dart';

/// Step Counter / Motion Detection Page
class StepCounterPage extends StatefulWidget {
  const StepCounterPage({super.key});

  @override
  State<StepCounterPage> createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  MotionDetector? _motionDetector;
  Timer? _updateTimer;
  int _estimatedSteps = 0;
  double _distanceKm = 0.0;
  Duration _activeTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startMotionDetection();
  }

  void _startMotionDetection() {
    _motionDetector = MotionDetector();
    _motionDetector!.startDetection();

    // Update UI periodically
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _motionDetector != null) {
        setState(() {
          // Estimate steps based on walking/running time
          if (_motionDetector!.currentState == MotionState.walking) {
            _estimatedSteps += 2; // ~2 steps per second while walking
            _activeTime += const Duration(seconds: 1);
          } else if (_motionDetector!.currentState == MotionState.running) {
            _estimatedSteps += 4; // ~4 steps per second while running
            _activeTime += const Duration(seconds: 1);
          }
          // Estimate distance: avg stride = 0.75m
          _distanceKm = (_estimatedSteps * 0.75) / 1000;
        });
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _motionDetector?.dispose();
    super.dispose();
  }

  Color _getStateColor(MotionState state) {
    switch (state) {
      case MotionState.stationary:
        return Colors.blue;
      case MotionState.walking:
        return Colors.green;
      case MotionState.running:
        return Colors.orange;
      case MotionState.inVehicle:
        return Colors.purple;
      case MotionState.unknown:
        return Colors.grey;
    }
  }

  IconData _getStateIcon(MotionState state) {
    switch (state) {
      case MotionState.stationary:
        return Icons.accessibility_new;
      case MotionState.walking:
        return Icons.directions_walk;
      case MotionState.running:
        return Icons.directions_run;
      case MotionState.inVehicle:
        return Icons.directions_car;
      case MotionState.unknown:
        return Icons.help_outline;
    }
  }

  String _getStateName(MotionState state, bool isZh) {
    switch (state) {
      case MotionState.stationary:
        return isZh ? '静止' : 'Stationary';
      case MotionState.walking:
        return isZh ? '步行' : 'Walking';
      case MotionState.running:
        return isZh ? '跑步' : 'Running';
      case MotionState.inVehicle:
        return isZh ? '乘车' : 'In Vehicle';
      case MotionState.unknown:
        return isZh ? '未知' : 'Unknown';
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return "${twoDigits(d.inHours)}:${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    final isZh = AppStrings.languageCode == 'zh';
    final state = _motionDetector?.currentState ?? MotionState.unknown;
    final confidence = _motionDetector?.currentConfidence ?? 0.0;
    final stateColor = _getStateColor(state);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isZh ? '运动检测' : 'Motion Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _estimatedSteps = 0;
                _distanceKm = 0.0;
                _activeTime = Duration.zero;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Main State Display
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
                        stateColor.withValues(alpha: 0.2),
                        const Color(0xFF1E1E3F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: stateColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated icon
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          _getStateIcon(state),
                          key: ValueKey(state),
                          size: 80,
                          color: stateColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getStateName(state, isZh),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: stateColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Confidence bar
                      Container(
                        width: 200,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: confidence,
                          child: Container(
                            decoration: BoxDecoration(
                              color: stateColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(confidence * 100).toStringAsFixed(0)}% ${isZh ? "置信度" : "confidence"}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '估算步数' : 'Est. Steps',
                      _estimatedSteps.toString(),
                      Icons.directions_walk,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '距离' : 'Distance',
                      '${_distanceKm.toStringAsFixed(2)} km',
                      Icons.straighten,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      isZh ? '活动时间' : 'Active',
                      _formatDuration(_activeTime),
                      Icons.timer,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Data Quality Integration
              Consumer<SensorManager>(
                builder: (context, manager, _) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E3F),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: manager.isSampling
                            ? Colors.green.withValues(alpha: 0.5)
                            : Colors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          manager.isSampling
                              ? Icons.cloud_upload
                              : Icons.cloud_off,
                          color:
                              manager.isSampling ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isZh ? '数据采集状态' : 'Data Collection',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                manager.isSampling
                                    ? (isZh
                                        ? '正在采集传感器数据...'
                                        : 'Collecting sensor data...')
                                    : (isZh
                                        ? '数据采集已暂停'
                                        : 'Data collection paused'),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getDataQualityColor(state)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getDataQualityLabel(state, isZh),
                            style: TextStyle(
                              color: _getDataQualityColor(state),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Legend
              _buildLegend(isZh),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDataQualityColor(MotionState state) {
    switch (state) {
      case MotionState.stationary:
        return Colors.green; // Best quality - no motion noise
      case MotionState.walking:
        return Colors.yellow; // OK quality
      case MotionState.running:
        return Colors.orange; // Lower quality due to motion
      case MotionState.inVehicle:
        return Colors.red; // Poor quality - vehicle interference
      case MotionState.unknown:
        return Colors.grey;
    }
  }

  String _getDataQualityLabel(MotionState state, bool isZh) {
    switch (state) {
      case MotionState.stationary:
        return isZh ? '高质量' : 'High Quality';
      case MotionState.walking:
        return isZh ? '良好' : 'Good';
      case MotionState.running:
        return isZh ? '一般' : 'Fair';
      case MotionState.inVehicle:
        return isZh ? '低质量' : 'Low Quality';
      case MotionState.unknown:
        return isZh ? '未知' : 'Unknown';
    }
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(bool isZh) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
              Icons.accessibility_new, isZh ? '静止' : 'Still', Colors.blue),
          _buildLegendItem(
              Icons.directions_walk, isZh ? '步行' : 'Walk', Colors.green),
          _buildLegendItem(
              Icons.directions_run, isZh ? '跑步' : 'Run', Colors.orange),
          _buildLegendItem(
              Icons.directions_car, isZh ? '乘车' : 'Vehicle', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildLegendItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 10)),
      ],
    );
  }
}
