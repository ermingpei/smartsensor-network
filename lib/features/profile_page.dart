import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_strings.dart';
import '../core/sensor_manager.dart';
import '../core/auth_service.dart';
import 'widgets/qbit_icon.dart';
import 'rewards_page.dart';
import 'about_page.dart';
import 'onboarding_page.dart';
import 'auth_page.dart';
import 'main_scaffold.dart';

/// Profile Page - User profile, earnings, and settings
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF0D0D1A),
        Color(0xFF1A1A3E),
        Color(0xFF0D0D1A),
      ],
    );

    return Container(
      decoration: const BoxDecoration(gradient: bgGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),
              // User Info Card
              _buildUserInfoCard(context),
              const SizedBox(height: 20),
              // Earnings Card
              _buildEarningsCard(context),
              const SizedBox(height: 20),
              // Invite Friends Card (Issue #2 - Prominent invite card)
              _buildInviteCard(context),
              const SizedBox(height: 20),
              // Settings List
              _buildSettingsList(context),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.person_rounded,
                color: Colors.cyanAccent, size: 24),
            const SizedBox(width: 12),
            Text(
              AppStrings.t('nav_profile'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Version number in top right
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final version = snapshot.data?.version ?? '...';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'v$version',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 11,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUserInfoCard(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        final isAnonymous = authService.isAnonymous;

        // Hide card when logged in
        if (!isAnonymous) {
          return const SizedBox.shrink();
        }

        final isZh = AppStrings.languageCode == 'zh';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E3F),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.cyanAccent, Colors.purpleAccent],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isZh ? '非注册用户' : 'Anonymous User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AppStrings.t('tier_free'),
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tier info icon on right
                  IconButton(
                    onPressed: () => _showTierInfoDialog(context),
                    icon: const Icon(Icons.info_outline,
                        color: Colors.cyanAccent, size: 22),
                    tooltip: AppStrings.t('tier_info_title'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Warning message
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.t('anonymous_warning').replaceAll('⚠️ ', ''),
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Register/Login button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AuthPage(
                          onAuthSuccess: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isZh ? '注册 / 登录' : 'Register / Login',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEarningsCard(BuildContext context) {
    return Consumer<SensorManager>(
      builder: (context, manager, _) {
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RewardsPage()),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D2D4A), Color(0xFF1E1E3F)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                // QBit Icon
                const QBitIcon(size: 48),
                const SizedBox(width: 16),
                // Earnings Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t('earning_dashboard'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${manager.totalEarnings.toStringAsFixed(2)} QBit',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        AppStrings.t('earning_dashboard_desc'),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white38, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Issue #2: Prominent Invite Friends Card
  Widget _buildInviteCard(BuildContext context) {
    final isZh = AppStrings.languageCode == 'zh';
    final accentCyan = const Color(0xFF22D3EE);

    return GestureDetector(
      onTap: () => _showInviteDialog(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A5F), Color(0xFF0D1F3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentCyan.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: accentCyan.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.people_alt, color: accentCyan, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isZh ? '🎁 邀请好友 赚取加成' : '🎁 INVITE FRIENDS & EARN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isZh
                            ? '裂变是最强的增长方式！'
                            : 'Viral growth is the best strategy!',
                        style: TextStyle(
                          color: Colors.cyanAccent.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white38, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard,
                          color: Colors.amber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isZh
                              ? '好友注册后您将获得系统奖励'
                              : 'Get system bonus when friends register',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.trending_up,
                          color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isZh
                              ? '每位好友贡献 +20% 积分加成'
                              : '+20% boost from each friend',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.info,
            iconColor: Colors.cyanAccent,
            title: AppStrings.t('about'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AboutPage()),
            ),
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.privacy_tip,
            iconColor: Colors.cyanAccent,
            title: AppStrings.t('privacy_policy'),
            onTap: () async {
              final Uri url = Uri.parse(
                  'https://smartsensor.yourcompany.com/dashboard/privacy.html');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.restart_alt,
            iconColor: Colors.orangeAccent,
            title: AppStrings.t('replay_tutorial'),
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('seenOnboarding', false);
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => OnboardingPage()),
                );
              }
            },
          ),
          _buildDivider(),
          // Auth Status & Logout
          Consumer<AuthService>(
            builder: (context, authService, _) {
              if (authService.isLoggedIn) {
                return _buildSettingsItem(
                  icon: Icons.logout,
                  iconColor: Colors.redAccent,
                  title: AppStrings.t('logout'),
                  subtitle: authService.currentUser?.email,
                  onTap: () async {
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuthPage(
                            onAuthSuccess: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MainScaffold(),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white70),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            )
          : null,
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 14)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      color: Colors.purpleAccent.withValues(alpha: 0.1),
      height: 1,
      indent: 56,
    );
  }

  /// Show tier info dialog
  void _showTierInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(AppStrings.t('tier_info_title'),
                style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            AppStrings.t('tier_info_desc'),
            style: const TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.t('got_it'),
                style: const TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  /// Show invite dialog with referral code and share functionality
  void _showInviteDialog(BuildContext context) async {
    // Get device ID for referral code
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('sentinel_device_id');
    if (deviceId == null) {
      deviceId = 'XXXXXX';
    }
    final code = deviceId.substring(0, 6).toUpperCase();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E3F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.people, color: Colors.greenAccent),
            const SizedBox(width: 12),
            Text(
              AppStrings.t('invite_friends'),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.t('tip_invite_content'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            // Referral Code Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.amber, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.languageCode == 'zh'
                              ? '已复制到剪贴板'
                              : 'Copied to clipboard'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.languageCode == 'zh' ? '关闭' : 'Close',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share, size: 18),
            label: Text(AppStrings.languageCode == 'zh' ? '分享' : 'Share'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final String subject = AppStrings.t('share_subject');
              final String body =
                  AppStrings.t('share_body').replaceAll('#CODE#', code);
              SharePlus.instance
                  .share(ShareParams(text: body, subject: subject));
            },
          ),
        ],
      ),
    );
  }
}
