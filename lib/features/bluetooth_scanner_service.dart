import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothScannerService {
  bool _isScanning = false;

  /// Start a scan and return the number of unique devices found
  Future<int> scanForDevices() async {
    if (_isScanning) return 0;

    // Check if Bluetooth is supported
    if (await FlutterBluePlus.isSupported == false) {
      debugPrint("❌ Bluetooth not supported");
      return 0;
    }

    // Turn on Bluetooth if needed (Android only, iOS prompts user)
    // await FlutterBluePlus.turnOn(); // Optional, better to let user manage

    _isScanning = true;
    int deviceCount = 0;
    Set<String> uniqueIds = {};

    try {
      debugPrint("🔵 Starting Bluetooth Scan...");

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      // Note: scanResults is a Stream, but since we set a timeout,
      // we can also just wait for the timeout and check the latest snapshot?
      // Actually, listen is better.

      var subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult r in results) {
          if (!uniqueIds.contains(r.device.remoteId.str)) {
            uniqueIds.add(r.device.remoteId.str);
            // debugPrint("🔵 Found BLE Device: ${r.device.remoteId} (${r.rssi} dBm)");
          }
        }
      });

      // Wait for the scan to complete (based on timeout)
      await Future.delayed(const Duration(seconds: 4));

      await FlutterBluePlus.stopScan();
      await subscription.cancel();

      deviceCount = uniqueIds.length;
      debugPrint("🔵 Bluetooth Scan Complete. Found: $deviceCount devices.");
    } catch (e) {
      debugPrint("❌ Bluetooth scan error: $e");
    } finally {
      _isScanning = false;
    }

    return deviceCount;
  }
}
