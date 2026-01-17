import 'package:flutter/material.dart';
import '../core/app_strings.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Determine language for content
    bool isZh = AppStrings.languageCode == 'zh';

    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(
        title:
            Text(AppStrings.t('about'), style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1E293B),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset('assets/icon/icon.png', width: 80, height: 80),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                'SmartSensor Network',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            Center(
              child: Text(
                'v${AppStrings.t('version')}', // Version will be injected specifically in dashboard, here just label or static
                style: TextStyle(color: Colors.white54),
              ),
            ),
            SizedBox(height: 32),
            _buildSectionTitle(isZh ? '我们的使命' : 'Our Mission'),
            _buildSectionBody(isZh
                ? 'SmartSensor 致力于构建全球最大的去中心化环境感知网络。通过汇聚亿万智能手机的传感器数据，我们正在绘制前所未有的高精度全球环境图谱。'
                : 'SmartSensor is dedicated to building the world\'s largest decentralized environmental sensing network. By pooling sensor data from billions of smartphones, we are mapping the globe with unprecedented precision.'),
            SizedBox(height: 24),
            _buildSectionTitle(isZh ? '核心价值' : 'Core Value'),
            _buildFeatureItem(
              Icons.science,
              isZh ? '贡献科研' : 'Scientific Contribution',
              isZh
                  ? '您的数据将帮助科学家研究微气候、噪音污染和信号传播，解决现实世界的环境挑战。'
                  : 'Your data helps scientists study micro-climates, noise pollution, and signal propagation to solve real-world environmental challenges.',
            ),
            _buildFeatureItem(
              Icons.paid,
              isZh ? '获取收益' : 'Earn Rewards',
              isZh
                  ? '闲置资源变现。每一次自动采集都在为您赚取感测积分，可兑换礼品卡。'
                  : 'Monetize idle resources. Every automatic scan earns you Sense Points, which can be redeemed for gift cards.',
            ),
            _buildFeatureItem(
              Icons.auto_awesome,
              isZh ? '零感运行' : 'Effortless',
              isZh
                  ? '无需复杂操作，App 在后台自动运行，不影响您的日常使用。'
                  : 'No complex setup. The app runs automatically in the background without interrupting your daily routine.',
            ),
            SizedBox(height: 32),
            Center(
              child: TextButton.icon(
                icon: Icon(Icons.email, color: Colors.cyanAccent),
                label: Text(
                  'admin@yourcompany.com',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 16),
                ),
                onPressed: () {
                  final Uri emailLaunchUri = Uri(
                    scheme: 'mailto',
                    path: 'admin@yourcompany.com',
                    query: 'subject=SmartSensor Support',
                  );
                  launchUrl(emailLaunchUri);
                },
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                AppStrings.t('powered_by'),
                style: TextStyle(color: Colors.white24, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSectionBody(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(desc,
                    style: TextStyle(
                        color: Colors.white60, fontSize: 14, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
