import 'dart:io';
import 'package:flutter/services.dart';

class CellularScannerService {
  static const platform = MethodChannel('com.smartsensor/cellular');

  Future<List<Map<dynamic, dynamic>>> getCellularData() async {
    if (!Platform.isAndroid) {
      // iOS Limitation: Can't get raw CellInfo.
      // Return empty (or implement basic carrier info via another package later)
      return [];
    }

    try {
      final List<dynamic> result =
          await platform.invokeMethod('getSignalStrengths');
      return result.cast<Map<dynamic, dynamic>>();
    } on PlatformException catch (e) {
      print("Failed to get cellular data: '${e.message}'.");
      return [];
    }
  }
}
