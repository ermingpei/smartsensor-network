import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Motion state enumeration
enum MotionState {
  stationary, // 静止不动
  walking, // 步行
  running, // 跑步
  inVehicle, // 在车辆中
  unknown, // 未知
}

/// Motion detection result with confidence
class MotionResult {
  final MotionState state;
  final double confidence; // 0.0 - 1.0
  final double accelerationMagnitude;
  final double accelerationVariance;
  final DateTime timestamp;

  MotionResult({
    required this.state,
    required this.confidence,
    required this.accelerationMagnitude,
    required this.accelerationVariance,
    required this.timestamp,
  });

  bool get isStationary => state == MotionState.stationary;
  bool get isHighConfidence => confidence >= 0.7;

  @override
  String toString() =>
      'MotionResult($state, conf=${confidence.toStringAsFixed(2)})';
}

/// Motion detector service using accelerometer data
/// Uses statistical analysis of acceleration variance to detect motion state
class MotionDetector extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  // Circular buffer for recent acceleration samples
  final List<double> _accelerationHistory = [];
  static const int _historySize = 50; // ~1 second at 50Hz

  // Current state
  MotionState _currentState = MotionState.unknown;
  double _currentConfidence = 0.0;
  double _currentMagnitude = 0.0;
  double _currentVariance = 0.0;
  DateTime? _stationarySince;

  // Thresholds (empirically tuned)
  // Based on research: https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6806223/
  static const double _stationaryVarianceThreshold = 0.15; // m/s²
  static const double _walkingVarianceMin = 0.3;
  static const double _walkingVarianceMax = 2.5;
  static const double _runningVarianceThreshold = 3.0;
  static const double _vehicleVarianceRange =
      0.1; // Low variance but non-stationary pattern

  // Getters
  MotionState get currentState => _currentState;
  double get currentConfidence => _currentConfidence;
  bool get isStationary => _currentState == MotionState.stationary;
  Duration get stationaryDuration {
    if (_stationarySince == null) return Duration.zero;
    return DateTime.now().difference(_stationarySince!);
  }

  /// Get current motion result
  MotionResult get currentResult => MotionResult(
        state: _currentState,
        confidence: _currentConfidence,
        accelerationMagnitude: _currentMagnitude,
        accelerationVariance: _currentVariance,
        timestamp: DateTime.now(),
      );

  /// Start motion detection
  void startDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20), // 50Hz
    ).listen(_onAccelerometerEvent);

    debugPrint('📱 MotionDetector started');
  }

  /// Stop motion detection
  void stopDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    debugPrint('📱 MotionDetector stopped');
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Calculate acceleration magnitude (removing gravity is complex, use raw for variance)
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    // Add to history
    _accelerationHistory.add(magnitude);
    if (_accelerationHistory.length > _historySize) {
      _accelerationHistory.removeAt(0);
    }

    // Need enough samples for analysis
    if (_accelerationHistory.length < 20) return;

    // Calculate statistics
    _currentMagnitude = _calculateMean(_accelerationHistory);
    _currentVariance = _calculateVariance(_accelerationHistory);

    // Classify motion state
    final previousState = _currentState;
    _classifyMotionState();

    // Track stationary duration
    if (_currentState == MotionState.stationary &&
        previousState != MotionState.stationary) {
      _stationarySince = DateTime.now();
    } else if (_currentState != MotionState.stationary) {
      _stationarySince = null;
    }

    // Notify listeners periodically (every 10 samples to avoid spam)
    if (_accelerationHistory.length % 10 == 0) {
      notifyListeners();
    }
  }

  void _classifyMotionState() {
    final variance = _currentVariance;
    final magnitude = _currentMagnitude;

    // Classification logic based on acceleration variance
    // Reference: Activity recognition using accelerometer data

    if (variance < _stationaryVarianceThreshold) {
      // Very low variance = stationary
      _currentState = MotionState.stationary;
      _currentConfidence = 1.0 - (variance / _stationaryVarianceThreshold);
      _currentConfidence = _currentConfidence.clamp(0.7, 1.0);
    } else if (variance >= _walkingVarianceMin &&
        variance <= _walkingVarianceMax) {
      // Moderate rhythmic variance = walking
      _currentState = MotionState.walking;
      // Confidence based on how "typical" the variance is for walking
      final walkingCenter = (_walkingVarianceMin + _walkingVarianceMax) / 2;
      _currentConfidence =
          1.0 - (variance - walkingCenter).abs() / walkingCenter;
      _currentConfidence = _currentConfidence.clamp(0.5, 0.9);
    } else if (variance > _runningVarianceThreshold) {
      // High variance = running
      _currentState = MotionState.running;
      _currentConfidence = (variance / 5.0).clamp(0.6, 0.95);
    } else if (variance > _stationaryVarianceThreshold &&
        variance < _walkingVarianceMin) {
      // Low but non-stationary variance might indicate vehicle
      // Vehicles have smooth acceleration/deceleration
      if (magnitude > 9.5 && magnitude < 10.5) {
        // Close to gravity + slight vehicle motion
        _currentState = MotionState.inVehicle;
        _currentConfidence = 0.6; // Vehicle detection is less certain
      } else {
        _currentState = MotionState.unknown;
        _currentConfidence = 0.3;
      }
    } else {
      _currentState = MotionState.unknown;
      _currentConfidence = 0.2;
    }
  }

  double _calculateMean(List<double> data) {
    if (data.isEmpty) return 0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  double _calculateVariance(List<double> data) {
    if (data.length < 2) return 0;
    final mean = _calculateMean(data);
    final squaredDiffs = data.map((x) => pow(x - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / data.length;
  }

  @override
  void dispose() {
    stopDetection();
    super.dispose();
  }
}
