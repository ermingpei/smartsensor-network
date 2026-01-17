import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';

import '../features/report_generator_page.dart';
import 'app_strings.dart';

/// Service for generating professional PDF reports
class PdfReportService {
  /// Generate a styled PDF report from ReportData
  static Future<Uint8List> generatePdf(ReportData report) async {
    final pdf = pw.Document();
    final isZh = AppStrings.languageCode == 'zh';
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(report.createdAt);

    // Try to load logo (fallback to text if not available)
    pw.ImageProvider? logoImage;
    try {
      final logoData = await rootBundle.load('assets/icon/icon.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      // Logo not available, will use text fallback
    }

    // Define colors
    const primaryColor = PdfColor.fromInt(0xFF00BCD4); // Cyan
    const accentColor = PdfColor.fromInt(0xFFFFB300); // Amber
    const darkBg = PdfColor.fromInt(0xFF1E1E3F);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Header with logo
          _buildHeader(logoImage, dateStr, isZh, primaryColor),
          pw.SizedBox(height: 20),

          // Report Title
          _buildTitle(report.type, isZh, accentColor),
          pw.SizedBox(height: 30),

          // Summary Section
          _buildSummarySection(report.data, isZh, primaryColor, darkBg),
          pw.SizedBox(height: 20),

          // Detailed Data Section
          _buildDataSection(report.data, isZh, primaryColor, darkBg),
          pw.SizedBox(height: 20),

          // Recommendations Section
          _buildRecommendationsSection(report.data, isZh, primaryColor, darkBg),
        ],
        footer: (context) => _buildFooter(context, isZh),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
      pw.ImageProvider? logo, String dateStr, bool isZh, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            if (logo != null)
              pw.Image(logo, width: 40, height: 40)
            else
              pw.Container(
                width: 40,
                height: 40,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Text('D',
                      style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold)),
                ),
              ),
            pw.SizedBox(width: 12),
            pw.Text(
              'SmartSensor',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              isZh ? '环境检测报告' : 'Environment Report',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              dateStr,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTitle(String type, bool isZh, PdfColor accentColor) {
    String title;
    switch (type) {
      case 'wifi':
        title = isZh ? 'WiFi 环境检测报告' : 'WiFi Environment Report';
        break;
      case 'noise':
        title = isZh ? '噪音环境检测报告' : 'Noise Environment Report';
        break;
      case 'house_viewing':
        title = isZh ? '看房环境综合报告' : 'House Viewing Report';
        break;
      case 'weekly':
        title = isZh ? '周度数据贡献报告' : 'Weekly Contribution Report';
        break;
      default:
        title = isZh ? '环境检测报告' : 'Environment Report';
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: pw.BoxDecoration(
        color: accentColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildSummarySection(
      Map<String, dynamic> data, bool isZh, PdfColor color, PdfColor bgColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isZh ? '📊 数据摘要' : '📊 Summary',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem(
                  isZh ? '累计积分' : 'Total Points',
                  '${(data['totalEarnings'] as num?)?.toStringAsFixed(1) ?? '0'} QBit',
                  color),
              _buildSummaryItem(isZh ? '覆盖区域' : 'Coverage',
                  '${data['uniqueHexCount'] ?? 0}', color),
              _buildSummaryItem(isZh ? '蓝牙设备' : 'BT Devices',
                  '${data['bluetoothDensity'] ?? 0}', color),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(
      String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildDataSection(
      Map<String, dynamic> data, bool isZh, PdfColor color, PdfColor bgColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isZh ? '📈 详细数据' : '📈 Detailed Data',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildDataRow(isZh ? '噪音等级' : 'Noise Level',
              '${(data['currentDecibel'] as num?)?.toStringAsFixed(1) ?? '--'} dB'),
          _buildDataRow(isZh ? '气压' : 'Pressure',
              '${(data['currentPressure'] as num?)?.toStringAsFixed(1) ?? '--'} hPa'),
          _buildDataRow(
              isZh ? '网络类型' : 'Network Type', data['networkType'] ?? '--'),
          _buildDataRow(
              isZh ? '网络延迟' : 'Latency', '${data['latency'] ?? '--'} ms'),
          _buildDataRow(
              isZh ? '数据采集' : 'Sampling',
              data['isSampling'] == true
                  ? (isZh ? '运行中' : 'Active')
                  : (isZh ? '已停止' : 'Stopped')),
        ],
      ),
    );
  }

  static pw.Widget _buildDataRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildRecommendationsSection(
      Map<String, dynamic> data, bool isZh, PdfColor color, PdfColor bgColor) {
    final recommendations = <String>[];

    // Generate recommendations based on data
    final decibel = (data['currentDecibel'] as num?) ?? 0;
    if (decibel > 70) {
      recommendations.add(isZh
          ? '⚠️ 噪音水平较高 (${decibel.toStringAsFixed(0)} dB)，建议在安静时段再次检测'
          : '⚠️ High noise level (${decibel.toStringAsFixed(0)} dB), consider testing during quieter hours');
    } else if (decibel < 40) {
      recommendations.add(isZh
          ? '✅ 环境噪音较低，适合居住/办公'
          : '✅ Low noise environment, suitable for living/working');
    }

    final latency = (data['latency'] as num?) ?? 0;
    if (latency > 100) {
      recommendations.add(isZh
          ? '⚠️ 网络延迟较高 (${latency}ms)，可能影响视频通话'
          : '⚠️ High network latency (${latency}ms), may affect video calls');
    } else if (latency > 0 && latency < 50) {
      recommendations.add(isZh
          ? '✅ 网络延迟良好，适合远程工作'
          : '✅ Good network latency, suitable for remote work');
    }

    if (recommendations.isEmpty) {
      recommendations.add(isZh
          ? '📝 继续收集更多数据以获得更准确的分析'
          : '📝 Continue collecting more data for accurate analysis');
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFF8E1), // Light amber
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            isZh ? '💡 建议' : '💡 Recommendations',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFFFF8F00), // Dark amber
            ),
          ),
          pw.SizedBox(height: 12),
          ...recommendations.map((r) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(r, style: const pw.TextStyle(fontSize: 11)),
              )),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, bool isZh) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            isZh
                ? '由 SmartSensor 生成 • smartsensor.yourcompany.com'
                : 'Generated by SmartSensor • smartsensor.yourcompany.com',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
          pw.Text(
            '${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
