import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/app_strings.dart';

/// GDPR/PIPEDA compliant consent dialog shown on first launch
/// User must consent before data collection begins
class ConsentDialog extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback? onDecline;

  const ConsentDialog({
    super.key,
    required this.onAccept,
    this.onDecline,
  });

  static const String _consentKey = 'privacy_consent_given';
  static const String _consentDateKey = 'privacy_consent_date';

  /// Check if user has already given consent
  static Future<bool> hasConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  /// Save consent status
  static Future<void> saveConsent(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, accepted);
    if (accepted) {
      await prefs.setString(_consentDateKey, DateTime.now().toIso8601String());
    }
  }

  /// Clear consent (for testing or data deletion)
  static Future<void> clearConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentKey);
    await prefs.remove(_consentDateKey);
  }

  void _openPrivacyPolicy() async {
    final Uri url =
        Uri.parse('https://smartsensor.yourcompany.com/dashboard/privacy.html');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isZh = AppStrings.languageCode == 'zh';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    width: 80,
                    height: 80,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.sensors,
                      size: 80,
                      color: Colors.cyanAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                isZh ? '数据采集许可' : 'Data Collection Consent',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Description Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(
                      Icons.sensors,
                      isZh
                          ? '传感器数据：气压、噪音、网络信号'
                          : 'Sensors: Pressure, noise, network signals',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      isZh
                          ? '位置数据：模糊化的GPS坐标 (~100m精度)'
                          : 'Location: Approximate GPS (~100m accuracy)',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.cloud_upload_outlined,
                      isZh
                          ? '数据存储：加密传输至北美服务器'
                          : 'Storage: Encrypted transfer to North America',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.schedule,
                      isZh
                          ? '保留期限：最长2年，之后匿名化或删除'
                          : 'Retention: Up to 2 years, then anonymized',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Privacy Policy Link
              TextButton.icon(
                onPressed: _openPrivacyPolicy,
                icon: const Icon(Icons.privacy_tip_outlined,
                    color: Colors.cyanAccent, size: 18),
                label: Text(
                  isZh ? '阅读完整隐私政策 →' : 'Read Full Privacy Policy →',
                  style:
                      const TextStyle(color: Colors.cyanAccent, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Accept Button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await saveConsent(true);
                    onAccept();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isZh ? '我同意并继续' : 'I Agree & Continue',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Decline Button
              TextButton(
                onPressed: () async {
                  await saveConsent(false);
                  if (onDecline != null) {
                    onDecline!();
                  } else {
                    // Show warning dialog
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1E293B),
                          title: Text(
                            isZh ? '无法使用App' : 'Cannot Use App',
                            style: const TextStyle(color: Colors.white),
                          ),
                          content: Text(
                            isZh
                                ? 'SmartSensor需要收集传感器数据才能正常运行。不同意即无法使用App功能。'
                                : 'SmartSensor requires sensor data collection to function. Without consent, the app cannot be used.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(isZh ? '返回' : 'Go Back'),
                            ),
                          ],
                        ),
                      );
                    }
                  }
                },
                child: Text(
                  isZh ? '不同意' : 'I Do Not Agree',
                  style: const TextStyle(color: Colors.white38, fontSize: 14),
                ),
              ),

              // Rights Notice
              const SizedBox(height: 16),
              Text(
                isZh
                    ? '您可以随时在设置中撤回同意或请求删除数据。'
                    : 'You can withdraw consent or request data deletion anytime in Settings.',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                color: Colors.white70, fontSize: 14, height: 1.4),
          ),
        ),
      ],
    );
  }
}
