import 'motion_detector.dart';

/// Data quality metadata for sensor readings
/// Attached to every data point to indicate reliability
class QualityMetadata {
  /// Overall confidence score (0.0 - 1.0)
  /// 0.0 = completely unreliable, 1.0 = highly reliable
  final double confidenceScore;

  /// Motion state during measurement
  final MotionState motionState;

  /// Whether the device appears to be indoors
  final bool isIndoor;

  /// Duration of stable sampling in seconds
  final int sampleDurationSec;

  /// GPS accuracy in meters (lower is better)
  final double gpsAccuracyM;

  /// List of potential contamination flags
  final List<String> contaminationFlags;

  /// Timestamp of the measurement
  final DateTime timestamp;

  /// Quality tier for easy filtering
  QualityTier get tier {
    if (confidenceScore >= 0.8) return QualityTier.premium;
    if (confidenceScore >= 0.5) return QualityTier.standard;
    if (confidenceScore >= 0.3) return QualityTier.low;
    return QualityTier.rejected;
  }

  /// Whether this data should be uploaded
  bool get shouldUpload => tier != QualityTier.rejected;

  /// Human-readable quality label
  String get qualityLabel {
    switch (tier) {
      case QualityTier.premium:
        return 'Premium';
      case QualityTier.standard:
        return 'Standard';
      case QualityTier.low:
        return 'Low';
      case QualityTier.rejected:
        return 'Rejected';
    }
  }

  QualityMetadata({
    required this.confidenceScore,
    required this.motionState,
    required this.isIndoor,
    required this.sampleDurationSec,
    required this.gpsAccuracyM,
    required this.contaminationFlags,
    required this.timestamp,
  });

  /// Create from current sensor state
  factory QualityMetadata.fromCurrentState({
    required MotionState motionState,
    required double motionConfidence,
    required bool isIndoor,
    required int sampleDurationSec,
    required double gpsAccuracyM,
    required List<String> contaminationFlags,
  }) {
    double confidence = 1.0;

    // Motion state penalty
    switch (motionState) {
      case MotionState.stationary:
        confidence *= (1.0 * motionConfidence); // Best quality
        break;
      case MotionState.walking:
        confidence *= (0.5 * motionConfidence); // Moderate penalty
        break;
      case MotionState.running:
        confidence *= (0.2 * motionConfidence); // Heavy penalty
        break;
      case MotionState.inVehicle:
        confidence *= (0.1 * motionConfidence); // Severe penalty
        break;
      case MotionState.unknown:
        confidence *= 0.3; // Unknown = uncertain
        break;
    }

    // Sample duration bonus (longer = better)
    if (sampleDurationSec >= 30) {
      confidence *= 1.2; // 20% bonus for long sample
    } else if (sampleDurationSec >= 10) {
      confidence *= 1.0; // Standard
    } else if (sampleDurationSec >= 5) {
      confidence *= 0.8; // Short sample penalty
    } else {
      confidence *= 0.5; // Very short = unreliable
    }

    // GPS accuracy penalty
    if (gpsAccuracyM <= 10) {
      confidence *= 1.0; // Excellent GPS
    } else if (gpsAccuracyM <= 30) {
      confidence *= 0.9; // Good GPS
    } else if (gpsAccuracyM <= 100) {
      confidence *= 0.7; // Poor GPS
    } else {
      confidence *= 0.5; // Very poor GPS
    }

    // Contamination penalty
    confidence *= (1.0 - (contaminationFlags.length * 0.15));

    // Clamp to valid range
    confidence = confidence.clamp(0.0, 1.0);

    return QualityMetadata(
      confidenceScore: confidence,
      motionState: motionState,
      isIndoor: isIndoor,
      sampleDurationSec: sampleDurationSec,
      gpsAccuracyM: gpsAccuracyM,
      contaminationFlags: contaminationFlags,
      timestamp: DateTime.now(),
    );
  }

  /// Convert to JSON for upload
  Map<String, dynamic> toJson() => {
        'confidence_score': confidenceScore,
        'quality_tier': tier.name,
        'motion_state': motionState.name,
        'is_indoor': isIndoor,
        'sample_duration_sec': sampleDurationSec,
        'gps_accuracy_m': gpsAccuracyM,
        'contamination_flags': contaminationFlags,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      'QualityMetadata(score=${confidenceScore.toStringAsFixed(2)}, tier=$tier, motion=$motionState)';
}

/// Quality tier enumeration
enum QualityTier {
  premium, // >= 0.8: High value data, premium pricing
  standard, // >= 0.5: Acceptable quality
  low, // >= 0.3: Usable but weighted down
  rejected, // < 0.3: Not uploaded
}

/// Data quality filter for specific data types
class DataQualityFilter {
  /// Check if noise data should be uploaded
  static QualityMetadata evaluateNoiseData({
    required double decibelValue,
    required double decibelVariance,
    required MotionState motionState,
    required double motionConfidence,
    required int sampleDurationSec,
    required double gpsAccuracyM,
  }) {
    final flags = <String>[];

    // Reject vehicle measurements (engine noise)
    if (motionState == MotionState.inVehicle) {
      flags.add('IN_VEHICLE');
    }

    // High variance suggests user activity (talking, music)
    if (decibelVariance > 15) {
      flags.add('HIGH_VARIANCE');
    }

    // Unrealistic values
    if (decibelValue < 10 || decibelValue > 130) {
      flags.add('UNREALISTIC_VALUE');
    }

    return QualityMetadata.fromCurrentState(
      motionState: motionState,
      motionConfidence: motionConfidence,
      isIndoor: true, // Assume indoor for now
      sampleDurationSec: sampleDurationSec,
      gpsAccuracyM: gpsAccuracyM,
      contaminationFlags: flags,
    );
  }

  /// Check if cellular signal data should be uploaded
  static QualityMetadata evaluateCellularData({
    required int signalStrength,
    required bool cellIdChanged,
    required MotionState motionState,
    required double motionConfidence,
    required int sampleDurationSec,
    required double gpsAccuracyM,
  }) {
    final flags = <String>[];

    // Cell ID changed during sampling = transitional data
    if (cellIdChanged) {
      flags.add('CELL_ID_CHANGED');
    }

    // Moving measurements are less accurate
    if (motionState == MotionState.running) {
      flags.add('HIGH_SPEED_MOVEMENT');
    }

    // Very weak or very strong signals might be anomalies
    if (signalStrength < -120 || signalStrength > -40) {
      flags.add('EXTREME_SIGNAL');
    }

    return QualityMetadata.fromCurrentState(
      motionState: motionState,
      motionConfidence: motionConfidence,
      isIndoor: gpsAccuracyM > 50, // Poor GPS suggests indoor
      sampleDurationSec: sampleDurationSec,
      gpsAccuracyM: gpsAccuracyM,
      contaminationFlags: flags,
    );
  }

  /// Check if network latency data should be uploaded
  static QualityMetadata evaluateNetworkData({
    required int latencyMs,
    required int jitterMs,
    required double packetLoss,
    required MotionState motionState,
    required double motionConfidence,
  }) {
    final flags = <String>[];

    // First measurement after cold start is often high
    if (latencyMs > 500) {
      flags.add('POSSIBLE_COLD_START');
    }

    // Very high packet loss suggests network issue not location issue
    if (packetLoss > 20) {
      flags.add('NETWORK_UNSTABLE');
    }

    return QualityMetadata.fromCurrentState(
      motionState: motionState,
      motionConfidence: motionConfidence,
      isIndoor: true,
      sampleDurationSec: 5, // Network tests are quick
      gpsAccuracyM: 20, // GPS less relevant for network
      contaminationFlags: flags,
    );
  }

  /// Check if Bluetooth density data should be uploaded
  static QualityMetadata evaluateBluetoothData({
    required int deviceCount,
    required int scanDurationSec,
    required Set<String> knownUserDevices,
    required MotionState motionState,
    required double motionConfidence,
    required double gpsAccuracyM,
  }) {
    final flags = <String>[];

    // Very short scan = incomplete picture
    if (scanDurationSec < 5) {
      flags.add('SHORT_SCAN');
    }

    // Anomaly: too many devices at unusual hours
    final hour = DateTime.now().hour;
    if (deviceCount > 20 && (hour < 6 || hour > 23)) {
      flags.add('ANOMALY_TIME_COUNT');
    }

    return QualityMetadata.fromCurrentState(
      motionState: motionState,
      motionConfidence: motionConfidence,
      isIndoor: gpsAccuracyM > 30,
      sampleDurationSec: scanDurationSec,
      gpsAccuracyM: gpsAccuracyM,
      contaminationFlags: flags,
    );
  }
}
