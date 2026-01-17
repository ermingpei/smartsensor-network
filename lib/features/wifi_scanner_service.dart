import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';

class WifiScannerService {
  /// Start a WiFi scan if permission is granted.
  /// Returns true if scan was successfully triggered.
  Future<bool> startScan() async {
    // WiFi scanning is primarily for Android.
    if (!Platform.isAndroid) return false;

    try {
      // 1. Check if we can scan
      CanStartScan can = await WiFiScan.instance.canStartScan();
      if (can != CanStartScan.yes) {
        debugPrint("⚠️ Cannot start WiFi scan: $can");
        return false;
      }

      // 2. Start Scan
      final success = await WiFiScan.instance.startScan();
      debugPrint("🚀 WiFi Scan Triggered: $success");
      return success;
    } catch (e) {
      debugPrint("❌ WiFi Scan Error: $e");
      return false;
    }
  }

  /// Get the results of the latest scan.
  /// Returns a list of maps containing key fingerprint data.
  Future<List<Map<String, dynamic>>> getScannedResults() async {
    if (Platform.isIOS) {
      return _getIosCurrentWifi();
    }

    if (!Platform.isAndroid) return [];

    try {
      // 1. Get Scanned Results
      // This reads from the OS cache populated by startScan()
      final results = await WiFiScan.instance.getScannedResults();

      if (results.isEmpty) {
        debugPrint("📡 No WiFi networks found in scan results.");
        return [];
      }

      debugPrint("📡 Found ${results.length} WiFi networks");

      // 2. Map to privacy-preserving structure
      // - BSSID: Keep OUI (vendor prefix) + hash rest for uniqueness without tracking
      // - SSID: Not uploaded (can identify home/work networks)
      // - Keep RSSI and frequency for signal analysis
      return results.map((accessPoint) {
        return {
          'bssid_hash': _anonymizeBssid(accessPoint.bssid),
          'rssi': accessPoint.level, // Signal strength in dBm
          'frequency': accessPoint.frequency, // Channel frequency in MHz
          'timestamp': DateTime.now().toIso8601String(),
        };
      }).toList();
    } catch (e) {
      debugPrint("❌ Failed to get WiFi results: $e");
      return [];
    }
  }

  /// Anonymize BSSID: Keep OUI (vendor bytes) + hash rest
  /// This allows vendor analysis without tracking specific devices
  String _anonymizeBssid(String bssid) {
    final parts = bssid.toUpperCase().split(':');
    if (parts.length != 6)
      return sha256.convert(utf8.encode(bssid)).toString().substring(0, 12);

    // OUI = first 3 bytes (manufacturer identifier, public info)
    final oui = '${parts[0]}:${parts[1]}:${parts[2]}';
    // Hash the NIC (device-specific part) for privacy
    final nicHash = sha256
        .convert(utf8.encode('${parts[3]}:${parts[4]}:${parts[5]}'))
        .toString()
        .substring(0, 6);

    return '$oui:$nicHash';
  }

  /// iOS Fallback: Get current WiFi info (privacy-preserving)
  Future<List<Map<String, dynamic>>> _getIosCurrentWifi() async {
    try {
      final info = NetworkInfo();
      String? bssid = await info.getWifiBSSID();

      if (bssid == null) {
        debugPrint(
            "⚠️ iOS: No WiFi BSSID found (Permission issue or not connected)");
        return [];
      }

      debugPrint("📡 iOS: Found current WiFi connection");

      return [
        {
          'bssid_hash': _anonymizeBssid(bssid),
          'rssi': 0, // Not available on iOS
          'frequency': 0, // Not available on iOS
          'timestamp': DateTime.now().toIso8601String(),
        }
      ];
    } catch (e) {
      debugPrint("❌ iOS WiFi check failed: $e");
      return [];
    }
  }
}
