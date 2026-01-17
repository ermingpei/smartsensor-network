import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 隐私保护工具类，负责在端侧对敏感数据（如地理位置）进行加盐哈希和偏移处理。
class PrivacyGuard {
  final String _salt;

  PrivacyGuard({required String salt}) : _salt = salt;

  /// 对数据进行加盐哈希，用于生成唯一的“匿名节点 ID”。
  String anonymizeNodeId(String deviceId) {
    final bytes = utf8.encode(deviceId + _salt);
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  /// 对地理位置进行轻微扰动（时空偏移），以保护用户的精确住址。
  /// 仅保留街区级别的精度。
  Map<String, double> perturbLocation(double lat, double lng) {
    // 简单的坐标截断或加噪逻辑（示例：截断到小数点后 3 位，约 110 米误差）
    return {
      'lat': double.parse(lat.toStringAsFixed(3)),
      'lng': double.parse(lng.toStringAsFixed(3)),
    };
  }

  /// 生成数据存证摘要。
  String generateDigest({
    required double pressure,
    required double decibel,
    required double lat,
    required double lng,
    required int timestamp,
  }) {
    final payload = "$pressure|$decibel|$lat|$lng|$timestamp|$_salt";
    return sha256.convert(utf8.encode(payload)).toString();
  }
}
