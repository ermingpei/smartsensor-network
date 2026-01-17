import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  /// Returns the current network type as a readable string
  Future<String> getNetworkType() async {
    try {
      final List<ConnectivityResult> results =
          await _connectivity.checkConnectivity();
      if (results.isEmpty) return 'None';

      // We take the first result as primary for now
      final result = results.first;

      switch (result) {
        case ConnectivityResult.wifi:
          return 'WiFi';
        case ConnectivityResult.mobile:
          return 'Mobile'; // In a real app we might differentiate 4G/5G if platform allows,
        // but standard connectivity_plus just says mobile.
        // We can potentially use other packages for 5G detection later.
        case ConnectivityResult.ethernet:
          return 'Ethernet';
        case ConnectivityResult.vpn:
          return 'VPN';
        case ConnectivityResult.none:
          return 'None';
        default:
          return 'Other';
      }
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Measures latency to a reliable target in milliseconds.
  /// Returns -1 if request fails.
  Future<int> measureLatency() async {
    final stopwatch = Stopwatch()..start();
    try {
      // Use generate_204 endpoints which are designed for connectivity checks
      // These are faster and don't redirect
      final response = await http
          .get(
            Uri.parse('http://connectivitycheck.gstatic.com/generate_204'),
          )
          .timeout(const Duration(seconds: 5));
      stopwatch.stop();

      // Accept 204 (expected) or any non-error status
      if (response.statusCode < 400) {
        return stopwatch.elapsedMilliseconds;
      }
      return -1;
    } catch (e) {
      // Fallback: Try alternate endpoint
      try {
        final fallbackStopwatch = Stopwatch()..start();
        final fallbackResponse = await http
            .get(
              Uri.parse('http://www.gstatic.com/generate_204'),
            )
            .timeout(const Duration(seconds: 5));
        fallbackStopwatch.stop();

        if (fallbackResponse.statusCode < 400) {
          return fallbackStopwatch.elapsedMilliseconds;
        }
      } catch (_) {
        // Both failed
      }
      return -1;
    }
  }

  /// Measures network quality by performing multiple pings.
  /// Returns a map with: latencyMs, jitterMs, packetLossPercent
  Future<Map<String, dynamic>> measureNetworkQuality(
      {int pingCount = 5}) async {
    List<int> latencies = [];
    int failures = 0;

    for (int i = 0; i < pingCount; i++) {
      final latency = await measureLatency();
      if (latency > 0) {
        latencies.add(latency);
      } else {
        failures++;
      }
      // Small delay between pings to avoid rate limiting
      if (i < pingCount - 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // Calculate metrics
    final packetLossPercent = (failures / pingCount) * 100;

    if (latencies.isEmpty) {
      return {
        'latencyMs': -1,
        'jitterMs': -1,
        'packetLossPercent': packetLossPercent,
      };
    }

    // Average latency
    final avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;

    // Jitter: Standard deviation of latencies
    double jitter = 0;
    if (latencies.length > 1) {
      double sumSquaredDiff = 0;
      for (var lat in latencies) {
        sumSquaredDiff += (lat - avgLatency) * (lat - avgLatency);
      }
      jitter = _sqrt(sumSquaredDiff / latencies.length);
    }

    return {
      'latencyMs': avgLatency.round(),
      'jitterMs': jitter.round(),
      'packetLossPercent': packetLossPercent,
    };
  }

  /// Simple square root implementation to avoid dart:math import
  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
