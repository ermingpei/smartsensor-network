import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// WiFi fingerprint data with anonymized BSSID
class WifiFingerprint {
  final String bssidHash; // SHA256 hash of BSSID
  final int signalLevel; // RSSI in dBm
  final int frequency; // MHz
  final DateTime timestamp;

  WifiFingerprint({
    required this.bssidHash,
    required this.signalLevel,
    required this.frequency,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'bssid_hash': bssidHash,
        'signal': signalLevel,
        'freq': frequency,
        'ts': timestamp.toIso8601String(),
      };
}

/// Location fingerprint containing multiple WiFi readings
class LocationFingerprint {
  final String fingerprintId;
  final List<WifiFingerprint> wifiReadings;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;

  LocationFingerprint({
    required this.fingerprintId,
    required this.wifiReadings,
    this.latitude,
    this.longitude,
    required this.timestamp,
  });

  /// Calculate fingerprint similarity (for location matching)
  double similarityTo(LocationFingerprint other) {
    int matches = 0;
    int totalRssiDiff = 0;

    for (final wifi in wifiReadings) {
      final matching = other.wifiReadings.where(
        (w) => w.bssidHash == wifi.bssidHash,
      );
      if (matching.isNotEmpty) {
        matches++;
        totalRssiDiff += (wifi.signalLevel - matching.first.signalLevel).abs();
      }
    }

    if (matches == 0) return 0.0;

    // Similarity based on matching APs and RSSI difference
    final matchRatio = matches / wifiReadings.length;
    final avgRssiDiff = totalRssiDiff / matches;
    final rssiSimilarity = 1.0 - (avgRssiDiff / 50).clamp(0.0, 1.0);

    return matchRatio * 0.6 + rssiSimilarity * 0.4;
  }

  Map<String, dynamic> toJson() => {
        'id': fingerprintId,
        'wifi': wifiReadings.map((w) => w.toJson()).toList(),
        'lat': latitude,
        'lng': longitude,
        'ts': timestamp.toIso8601String(),
      };
}

/// Service for creating privacy-compliant WiFi fingerprints
class WifiFingerprintService {
  // Salt for additional hash security (could be device-specific)
  static const String _salt = 'smartsensor_v1_';

  /// Hash a BSSID for privacy compliance
  /// Uses SHA256 with salt, returns first 16 chars
  static String hashBssid(String bssid) {
    // Normalize BSSID (uppercase, remove colons)
    final normalized = bssid.toUpperCase().replaceAll(':', '');
    final bytes = utf8.encode('$_salt$normalized');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  /// Create a WiFi fingerprint from scan results
  static WifiFingerprint createFingerprint({
    required String bssid,
    required int signalLevel,
    required int frequency,
  }) {
    return WifiFingerprint(
      bssidHash: hashBssid(bssid),
      signalLevel: signalLevel,
      frequency: frequency,
      timestamp: DateTime.now(),
    );
  }

  /// Create a location fingerprint from multiple WiFi readings
  static LocationFingerprint createLocationFingerprint({
    required List<WifiFingerprint> wifiReadings,
    double? latitude,
    double? longitude,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    return LocationFingerprint(
      fingerprintId: id,
      wifiReadings: wifiReadings,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );
  }

  /// Log fingerprint collection for debugging (hashed data only)
  static void logFingerprint(LocationFingerprint fingerprint) {
    debugPrint('📡 WiFi Fingerprint: ${fingerprint.wifiReadings.length} APs');
    for (final wifi in fingerprint.wifiReadings.take(3)) {
      debugPrint(
          '   - ${wifi.bssidHash.substring(0, 8)}... ${wifi.signalLevel}dBm');
    }
  }
}
