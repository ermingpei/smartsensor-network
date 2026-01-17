import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:network_info_plus/network_info_plus.dart';
import '../core/app_strings.dart';
import '../core/wifi_fingerprint_service.dart';

/// WiFi Analyzer Page - Scan and display nearby WiFi networks
class WiFiAnalyzerPage extends StatefulWidget {
  const WiFiAnalyzerPage({super.key});

  @override
  State<WiFiAnalyzerPage> createState() => _WiFiAnalyzerPageState();
}

class _WiFiAnalyzerPageState extends State<WiFiAnalyzerPage> {
  List<WiFiAccessPoint> _accessPoints = [];
  bool _isScanning = false;
  String? _error;
  LocationFingerprint? _lastFingerprint;

  // iOS current WiFi info
  String? _iosWifiName;
  String? _iosWifiBssid;
  String? _iosWifiIp;
  bool _isIOS = false;

  @override
  void initState() {
    super.initState();
    _isIOS = Platform.isIOS;
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _error = null;
    });

    try {
      if (_isIOS) {
        // iOS: Use NetworkInfo to get current connected WiFi
        await _getIosCurrentWifi();
      } else {
        // Android: Full WiFi scan
        final can = await WiFiScan.instance.canStartScan();
        if (can == CanStartScan.yes) {
          await WiFiScan.instance.startScan();
          final results = await WiFiScan.instance.getScannedResults();
          setState(() {
            _accessPoints = results;
            _accessPoints.sort((a, b) => b.level.compareTo(a.level));
          });
        } else {
          final isZh = AppStrings.languageCode == 'zh';
          setState(() {
            _error = isZh
                ? 'WiFi扫描不可用，请检查权限设置。'
                : 'WiFi scan unavailable. Please check permissions.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _getIosCurrentWifi() async {
    try {
      final info = NetworkInfo();
      _iosWifiName = await info.getWifiName();
      _iosWifiBssid = await info.getWifiBSSID();
      _iosWifiIp = await info.getWifiIP();

      // Remove quotes from SSID if present
      if (_iosWifiName != null && _iosWifiName!.startsWith('"')) {
        _iosWifiName = _iosWifiName!.substring(1, _iosWifiName!.length - 1);
      }

      setState(() {
        if (_iosWifiName == null && _iosWifiBssid == null) {
          final isZh = AppStrings.languageCode == 'zh';
          _error = isZh
              ? '未连接到WiFi网络，或需要授权位置权限。'
              : 'Not connected to WiFi, or location permission required.';
        }
      });
    } catch (e) {
      debugPrint('iOS WiFi info error: $e');
      final isZh = AppStrings.languageCode == 'zh';
      setState(() {
        _error = isZh
            ? '获取WiFi信息失败：请确保已授权位置权限。'
            : 'Failed to get WiFi info: Please grant location permission.';
      });
    }
  }

  /// Collect anonymized WiFi fingerprint for location services
  void _collectFingerprint() {
    if (_accessPoints.isEmpty) return;

    final wifiReadings = _accessPoints.map((ap) {
      return WifiFingerprintService.createFingerprint(
        bssid: ap.bssid,
        signalLevel: ap.level,
        frequency: ap.frequency,
      );
    }).toList();

    _lastFingerprint = WifiFingerprintService.createLocationFingerprint(
      wifiReadings: wifiReadings,
    );

    WifiFingerprintService.logFingerprint(_lastFingerprint!);

    final isZh = AppStrings.languageCode == 'zh';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        isZh
            ? '✅ 已收集 ${wifiReadings.length} 个接入点的匿名指纹'
            : '✅ Collected anonymized fingerprint from ${wifiReadings.length} APs',
      ),
      backgroundColor: Colors.green,
    ));
  }

  Color _getSignalColor(int level) {
    if (level >= -50) return Colors.green;
    if (level >= -60) return Colors.lightGreen;
    if (level >= -70) return Colors.yellow;
    if (level >= -80) return Colors.orange;
    return Colors.red;
  }

  String _getSignalQuality(int level) {
    if (level >= -50) return AppStrings.t('signal_excellent');
    if (level >= -60) return AppStrings.t('signal_good');
    if (level >= -70) return AppStrings.t('signal_fair');
    return AppStrings.t('signal_poor');
  }

  int _getSignalBars(int level) {
    if (level >= -50) return 4;
    if (level >= -60) return 3;
    if (level >= -70) return 2;
    if (level >= -80) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppStrings.t('wifi_analyzer')),
        actions: [
          // Fingerprint button
          if (_accessPoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.fingerprint),
              tooltip: AppStrings.languageCode == 'zh'
                  ? '收集指纹'
                  : 'Collect Fingerprint',
              onPressed: _collectFingerprint,
            ),
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Summary Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2E7D9B), Color(0xFF1A4A5E)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    Icons.wifi,
                    '${_accessPoints.length}',
                    AppStrings.t('networks_found'),
                  ),
                  _buildSummaryItem(
                    Icons.signal_wifi_4_bar,
                    _accessPoints.isNotEmpty
                        ? '${_accessPoints.first.level} dBm'
                        : '--',
                    AppStrings.t('strongest_signal'),
                  ),
                ],
              ),
            ),

            // iOS: Show current WiFi info card
            if (_isIOS && (_iosWifiName != null || _iosWifiBssid != null))
              _buildIosCurrentWifiCard(),

            // Signal Spectrum Heatmap (Android only)
            if (!_isIOS && _accessPoints.isNotEmpty) _buildSignalSpectrum(),

            // Network List (Android) or iOS info message
            Expanded(
              child: _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              color: Colors.orangeAccent.withValues(alpha: 0.5),
                              size: 80,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _error!.contains('iOS') ||
                                      _error!.contains('not supported')
                                  ? (AppStrings.languageCode == 'zh'
                                      ? 'iOS 限制'
                                      : 'iOS Limitation')
                                  : (AppStrings.languageCode == 'zh'
                                      ? 'WiFi 扫描不可用'
                                      : 'WiFi Scan Unavailable'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 14),
                              ),
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
                                      AppStrings.languageCode == 'zh'
                                          ? '提示：在 Android 设备上可使用完整功能'
                                          : 'Tip: Full features available on Android',
                                      style: const TextStyle(
                                          color: Colors.cyanAccent,
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _startScan,
                              icon: const Icon(Icons.refresh),
                              label: Text(AppStrings.t('retry')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.cyanAccent.withValues(alpha: 0.2),
                                foregroundColor: Colors.cyanAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _accessPoints.isEmpty && !_isScanning
                      ? Center(
                          child: Text(
                            AppStrings.t('no_networks'),
                            style: const TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _accessPoints.length,
                          itemBuilder: (context, index) {
                            final ap = _accessPoints[index];
                            final signalColor = _getSignalColor(ap.level);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E1E3F),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: signalColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Signal Bars
                                  _buildSignalBars(
                                      _getSignalBars(ap.level), signalColor),
                                  const SizedBox(width: 16),
                                  // Network Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          ap.ssid.isNotEmpty
                                              ? ap.ssid
                                              : '<Hidden>',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ch ${ap.frequency ~/ 1000 < 3 ? (ap.frequency - 2407) ~/ 5 : (ap.frequency - 5000) ~/ 5} • ${ap.frequency} MHz',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Signal Strength
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${ap.level} dBm',
                                        style: TextStyle(
                                          color: signalColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _getSignalQuality(ap.level),
                                        style: TextStyle(
                                          color: signalColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIosCurrentWifiCard() {
    final isZh = AppStrings.languageCode == 'zh';
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current WiFi Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E7D9B), Color(0xFF1A4A5E)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.cyanAccent.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.wifi, color: Colors.greenAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    isZh ? '当前连接' : 'Connected',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _iosWifiName ?? (isZh ? '未知网络' : 'Unknown Network'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildWifiInfoRow(
                    Icons.router,
                    'BSSID',
                    _iosWifiBssid ?? '--',
                  ),
                  const SizedBox(height: 12),
                  _buildWifiInfoRow(
                    Icons.lan,
                    isZh ? 'IP 地址' : 'IP Address',
                    _iosWifiIp ?? '--',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // iOS Limitation Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E3F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isZh
                          ? 'iOS 只能显示当前连接的WiFi信息，无法扫描周围网络。'
                          : 'iOS can only show current WiFi, scanning nearby networks is not available.',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
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

  Widget _buildWifiInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSignalBars(int bars, Color color) {
    return Row(
      children: List.generate(4, (index) {
        final isActive = index < bars;
        return Container(
          width: 6,
          height: 8.0 + (index * 6),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  /// Signal spectrum heatmap showing channel congestion
  Widget _buildSignalSpectrum() {
    // Separate 2.4GHz and 5GHz networks
    final networks2_4 =
        _accessPoints.where((ap) => ap.frequency < 3000).toList();
    final networks5 =
        _accessPoints.where((ap) => ap.frequency >= 5000).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Colors.cyanAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                AppStrings.t('signal_spectrum'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2.4GHz Band
          _buildBandSpectrum('2.4 GHz', networks2_4, 2400, 2483, 13),
          const SizedBox(height: 8),
          // 5GHz Band (simplified to common channels)
          _buildBandSpectrum('5 GHz', networks5, 5170, 5825, 20),
        ],
      ),
    );
  }

  Widget _buildBandSpectrum(
    String label,
    List<WiFiAccessPoint> networks,
    int freqStart,
    int freqEnd,
    int channels,
  ) {
    // Create channel signal map
    final Map<int, int> channelSignals = {};
    for (var ap in networks) {
      int channel;
      if (ap.frequency < 3000) {
        channel = ((ap.frequency - 2407) / 5).round().clamp(1, 14);
      } else {
        channel = ((ap.frequency - 5000) / 5).round();
      }
      final current = channelSignals[channel] ?? -100;
      if (ap.level > current) {
        channelSignals[channel] = ap.level;
      }
    }

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 24,
            child: CustomPaint(
              painter: SpectrumPainter(
                channelSignals: channelSignals,
                channels: channels,
                is5GHz: freqStart >= 5000,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${networks.length}',
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
        ),
      ],
    );
  }
}

/// Custom painter for spectrum heatmap visualization
class SpectrumPainter extends CustomPainter {
  final Map<int, int> channelSignals;
  final int channels;
  final bool is5GHz;

  SpectrumPainter({
    required this.channelSignals,
    required this.channels,
    required this.is5GHz,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / channels;

    for (int i = 0; i < channels; i++) {
      int channel;
      if (is5GHz) {
        // 5GHz common channels: 36, 40, 44, 48... (step of 4)
        channel = 36 + (i * 4);
      } else {
        channel = i + 1;
      }

      final signal = channelSignals[channel] ?? -100;
      final intensity = ((signal + 100) / 50).clamp(0.0, 1.0);

      final color = Color.lerp(
        Colors.blue.withValues(alpha: 0.3),
        Colors.red,
        intensity,
      )!;

      final rect = Rect.fromLTWH(
        i * barWidth,
        size.height * (1 - intensity),
        barWidth - 1,
        size.height * intensity,
      );

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumPainter oldDelegate) {
    return oldDelegate.channelSignals != channelSignals;
  }
}
