import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Service to check for app updates
class UpdateChecker {
  // Current app version (should match pubspec.yaml)
  static const String currentVersion = '1.0.4';

  // GitHub release API endpoint
  static const String _releaseUrl =
      'https://api.github.com/repos/nicklaus-dev/smartsensor/releases/latest';

  // Download URLs
  static const String _githubDownloadUrl =
      'https://github.com/nicklaus-dev/smartsensor/releases/latest';

  // China-friendly download (Qubit Rhythm website)
  static const String _chinaDownloadUrl =
      'https://smartsensor.yourcompany.com/dashboard/download.html';

  /// Check if device is likely in China
  static bool get _isChineseLocale {
    final locale = ui.PlatformDispatcher.instance.locale;
    return locale.languageCode == 'zh';
  }

  /// Checks for updates and shows dialog if newer version available
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final latestVersion = await _getLatestVersion();

      if (latestVersion != null &&
          _isNewerVersion(latestVersion, currentVersion)) {
        if (context.mounted) {
          _showUpdateDialog(context, latestVersion);
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
      // Silent fail - don't bother user if update check fails
    }
  }

  /// Fetches latest version from GitHub releases
  static Future<String?> _getLatestVersion() async {
    try {
      final response = await http.get(
        Uri.parse(_releaseUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // GitHub tag format: "v1.0.4" -> "1.0.4"
        String tag = data['tag_name'] ?? '';
        if (tag.startsWith('v')) {
          tag = tag.substring(1);
        }
        return tag.isNotEmpty ? tag : null;
      }
    } catch (e) {
      debugPrint('Failed to fetch latest version: $e');
    }
    return null;
  }

  /// Compares version strings (e.g., "1.0.4" > "1.0.3")
  static bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final l = i < latestParts.length ? latestParts[i] : 0;
        final c = i < currentParts.length ? currentParts[i] : 0;

        if (l > c) return true;
        if (l < c) return false;
      }
    } catch (e) {
      debugPrint('Version comparison error: $e');
    }
    return false;
  }

  /// Shows update dialog to user
  static void _showUpdateDialog(BuildContext context, String newVersion) {
    final isChinese = _isChineseLocale;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.system_update, color: Colors.greenAccent, size: 28),
            SizedBox(width: 12),
            Text(isChinese ? '新版本可用' : 'Update Available',
                style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isChinese
                  ? '发现新版本 v$newVersion'
                  : 'New version v$newVersion available',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              isChinese
                  ? '当前版本: v$currentVersion'
                  : 'Current: v$currentVersion',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.greenAccent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isChinese
                          ? '建议更新以获得最新功能和修复'
                          : 'Update for new features & fixes',
                      style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isChinese ? '稍后' : 'Later',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _openDownloadPage(isChinese);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
            ),
            child: Text(isChinese ? '立即更新' : 'Update Now'),
          ),
        ],
      ),
    );
  }

  /// Opens the download page in browser
  static Future<void> _openDownloadPage(bool useChinaUrl) async {
    final url = useChinaUrl ? _chinaDownloadUrl : _githubDownloadUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
