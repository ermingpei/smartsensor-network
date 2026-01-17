import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_strings.dart';
import '../core/report_repository.dart';
import 'report_generator_page.dart';

/// Reports Page - View and generate reports
class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this); // 3 tabs: Guide, Generate, History
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Tab Bar
            _buildTabBar(),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGuideTab(), // Issue #7: Instructions first
                  _buildGenerateTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.assessment_rounded,
              color: Colors.cyanAccent, size: 24),
          const SizedBox(width: 12),
          Text(
            AppStrings.t('nav_reports'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.purpleAccent.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 13),
        tabs: [
          Tab(text: AppStrings.languageCode == 'zh' ? '使用说明' : 'Guide'),
          Tab(text: AppStrings.t('tab_generate')),
          Tab(text: AppStrings.t('tab_history')),
        ],
      ),
    );
  }

  /// Issue #7: Guide tab with usage instructions
  Widget _buildGuideTab() {
    final isZh = AppStrings.languageCode == 'zh';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyanAccent.withValues(alpha: 0.2),
                  Colors.transparent
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Colors.cyanAccent, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isZh
                        ? '如何获得有效的检测报告？'
                        : 'How to get an effective detection report?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // WiFi Report Guide
          _buildGuideSection(
            icon: Icons.wifi,
            color: Colors.blueAccent,
            title: isZh ? 'WiFi环境检测报告' : 'WiFi Environment Report',
            steps: isZh
                ? [
                    '1. 进入要检测的房间或区域',
                    '2. 打开报告生成器，选择"WiFi环境检测"',
                    '3. 慢慢在房间内走动（约30秒-1分钟）',
                    '4. 确保覆盖房间的各个角落',
                    '5. 等待扫描完成后生成报告',
                  ]
                : [
                    '1. Enter the room or area to scan',
                    '2. Open Report Generator, select "WiFi Environment"',
                    '3. Walk slowly around the room (30sec - 1min)',
                    '4. Make sure to cover all corners',
                    '5. Wait for scan to complete and generate report',
                  ],
          ),
          const SizedBox(height: 16),

          // Noise Report Guide
          _buildGuideSection(
            icon: Icons.graphic_eq,
            color: Colors.purpleAccent,
            title: isZh ? '噪音环境检测报告' : 'Noise Environment Report',
            steps: isZh
                ? [
                    '1. 在要检测的位置静止站立',
                    '2. 打开报告生成器，选择"噪音环境检测"',
                    '3. 保持安静，让应用采集环境噪音',
                    '4. 建议采集至少30秒数据',
                    '5. 可在不同时段（早/晚）多次检测',
                  ]
                : [
                    '1. Stand still at the location to scan',
                    '2. Open Report Generator, select "Noise Environment"',
                    '3. Stay quiet and let the app collect ambient noise',
                    '4. Collect at least 30 seconds of data',
                    '5. Scan multiple times at different hours (AM/PM)',
                  ],
          ),
          const SizedBox(height: 16),

          // House Viewing Guide
          _buildGuideSection(
            icon: Icons.home,
            color: Colors.greenAccent,
            title: isZh ? '看房环境检测报告' : 'House Viewing Report',
            steps: isZh
                ? [
                    '1. 到达看房地点后打开应用',
                    '2. 选择"看房环境检测"报告',
                    '3. 在每个房间停留20-30秒',
                    '4. 缓慢走过整个房屋',
                    '5. 检测WiFi信号、噪音、网络质量',
                    '6. 报告将综合显示各项指标评分',
                  ]
                : [
                    '1. Open the app when you arrive at the property',
                    '2. Select "House Viewing Report"',
                    '3. Stay in each room for 20-30 seconds',
                    '4. Walk through the entire house slowly',
                    '5. Detects WiFi, noise, and network quality',
                    '6. Report shows combined scores for all metrics',
                  ],
          ),
          const SizedBox(height: 16),

          // Tips
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tips_and_updates,
                        color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isZh ? '提示' : 'Tips',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isZh
                      ? '• 确保在检测期间保持应用前台运行\n• 移动时保持匀速，不要太快\n• 多次检测可获得更准确的结果'
                      : '• Keep the app in foreground during detection\n• Move at a steady pace, not too fast\n• Multiple scans give more accurate results',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideSection({
    required IconData icon,
    required Color color,
    required String title,
    required List<String> steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  step,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    final isZh = AppStrings.languageCode == 'zh';

    return FutureBuilder<List<ReportData>>(
      future: ReportRepository.getReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  color: Colors.cyanAccent.withValues(alpha: 0.3),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  AppStrings.t('no_reports_yet'),
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isZh
                      ? '生成您的第一份报告以在此处查看'
                      : 'Generate your first report to see it here',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return _buildReportHistoryItem(report, isZh);
          },
        );
      },
    );
  }

  Widget _buildReportHistoryItem(ReportData report, bool isZh) {
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(report.createdAt);

    String title;
    IconData icon;
    Color color;

    switch (report.type) {
      case 'wifi':
        title = isZh ? 'WiFi环境检测' : 'WiFi Environment';
        icon = Icons.wifi;
        color = Colors.blueAccent;
        break;
      case 'noise':
        title = isZh ? '噪音环境检测' : 'Noise Environment';
        icon = Icons.graphic_eq;
        color = Colors.purpleAccent;
        break;
      case 'house_viewing':
        title = isZh ? '看房环境检测' : 'House Viewing';
        icon = Icons.home;
        color = Colors.greenAccent;
        break;
      case 'weekly':
        title = isZh ? '周度报告' : 'Weekly Report';
        icon = Icons.calendar_today;
        color = Colors.orangeAccent;
        break;
      default:
        title = isZh ? '环境报告' : 'Environment Report';
        icon = Icons.assessment;
        color = Colors.cyanAccent;
    }

    return Dismissible(
      key: Key(report.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await ReportRepository.deleteReport(report.id);
        setState(() {}); // Refresh the list
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isZh ? '报告已删除' : 'Report deleted'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E3F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateTab() {
    final isZh = AppStrings.languageCode == 'zh';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildReportTypeCard(
            icon: Icons.home_work,
            title: isZh ? '看房环境检测' : 'House Visit Report',
            subtitle: isZh
                ? '噪音 + WiFi + 蜂窝信号 + 综合评分'
                : 'Noise + WiFi + Cell Signal + Score',
            color: Colors.purpleAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportGeneratorPage(
                    reportType: 'house_visit',
                    reportTitle: isZh ? '看房环境检测报告' : 'House Visit Report',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildReportTypeCard(
            icon: Icons.volume_up,
            title: isZh ? '噪音投诉证据' : 'Noise Complaint Evidence',
            subtitle: isZh
                ? '时间戳 + 分贝记录 + 持续时长'
                : 'Timestamps + dB Records + Duration',
            color: Colors.redAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportGeneratorPage(
                    reportType: 'noise',
                    reportTitle: isZh ? '噪音检测报告' : 'Noise Detection Report',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildReportTypeCard(
            icon: Icons.wifi,
            title: isZh ? 'WiFi优化建议' : 'WiFi Optimization',
            subtitle: isZh
                ? '各房间信号强度 + 最佳路由器位置'
                : 'Signal Strength by Room + Best Router Position',
            color: Colors.cyanAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportGeneratorPage(
                    reportType: 'wifi',
                    reportTitle: isZh ? 'WiFi分析报告' : 'WiFi Analysis Report',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildReportTypeCard(
            icon: Icons.calendar_month,
            title: isZh ? '周活动报告' : 'Weekly Activity Report',
            subtitle: isZh
                ? '数据贡献 + 覆盖区域 + 积分变化'
                : 'Data Contribution + Coverage + Points',
            color: Colors.greenAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportGeneratorPage(
                    reportType: 'weekly',
                    reportTitle: isZh ? '周活动报告' : 'Weekly Activity Report',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildReportTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E3F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
