import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'privacy_guard.dart';

/// 负责将端侧脱敏后的数据同步至 Supabase 的服务类。
/// 支持离线存储和自动重试机制 (Store-and-Forward)。
class DataSyncService {
  final SupabaseClient _client;
  final PrivacyGuard _privacyGuard;
  Database? _db;

  DataSyncService({
    required SupabaseClient client,
    required PrivacyGuard privacyGuard,
  })  : _client = client,
        _privacyGuard = privacyGuard {
    _initDB();
  }

  SupabaseClient get client => _client;

  /// 初始化本地 SQLite 数据库
  Future<void> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sensor_sentinel.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_readings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            node_id TEXT,
            reading_data TEXT, 
            created_at INTEGER
          )
        ''');
      },
    );
    debugPrint("✅ Local Database Initialized");

    // 启动时尝试同步一次
    syncPendingData();
  }

  /// 上报传感器读数 (先存本地，后续自动同步)
  Future<void> uploadReading({
    required String deviceId,
    required double pressure,
    required double decibel,
    required double lat,
    required double lng,
    String? referredBy,
    String? networkType,
    int? latency,
    List<Map<String, dynamic>>? wifiFingerprint,
    int? bluetoothDevices,
    List<Map<dynamic, dynamic>>? cellData,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final anonymizedId = _privacyGuard.anonymizeNodeId(deviceId);
    final perturbedLoc = _privacyGuard.perturbLocation(lat, lng);

    // 生成数据摘要以供云端验证一致性
    final digest = _privacyGuard.generateDigest(
      pressure: pressure,
      decibel: decibel,
      lat: perturbedLoc['lat']!,
      lng: perturbedLoc['lng']!,
      timestamp: timestamp.millisecondsSinceEpoch,
    );

    // 1. 确保节点已注册 (Upsert) - 这一步仍尝试在线做，若失败则此次不强求，下次同步也能补上
    Map<String, dynamic> nodeData = {
      'anonymized_id': anonymizedId,
      'device_model': 'Mobile-PoC',
    };
    if (referredBy != null && referredBy.isNotEmpty) {
      nodeData['referred_by'] = referredBy;
    }

    try {
      await _client.from('nodes').upsert(nodeData, onConflict: 'anonymized_id');
    } catch (e) {
      // 忽略节点注册错误，稍后重试
    }

    // 2. 构造读数 Payload
    final Map<String, dynamic> readingData = {
      'node_id': anonymizedId,
      'pressure_hpa': pressure,
      'decibel_db': decibel,
      'location': 'POINT(${perturbedLoc['lng']} ${perturbedLoc['lat']})',
      'timestamp': timestamp.toIso8601String(),
      'digest': digest,
    };

    if (networkType != null) readingData['network_type'] = networkType;
    if (latency != null) readingData['latency_ms'] = latency;
    if (wifiFingerprint != null && wifiFingerprint.isNotEmpty) {
      readingData['wifi_data'] = wifiFingerprint;
    }
    if (bluetoothDevices != null) {
      readingData['bluetooth_devices'] = bluetoothDevices;
    }
    if (cellData != null && cellData.isNotEmpty) {
      readingData['cell_data'] = cellData;
    }

    // 3. 存入本地数据库 (SQLite)
    if (_db != null) {
      await _db!.insert('pending_readings', {
        'node_id': anonymizedId,
        'reading_data': jsonEncode(readingData),
        'created_at': timestamp.millisecondsSinceEpoch,
      });
      debugPrint("💾 Data saved to local DB (Offline mode safe)");
    }

    // 4. 触发同步尝试
    syncPendingData();
  }

  bool _isSyncing = false;

  /// 将本地积压的数据同步到云端
  Future<void> syncPendingData() async {
    if (_isSyncing || _db == null) return;
    _isSyncing = true;

    try {
      // 1. 获取未上传的数据 (一次最多 50 条，防止包过大)
      final List<Map<String, dynamic>> pending = await _db!.query(
        'pending_readings',
        limit: 50,
        orderBy: 'created_at ASC',
      );

      if (pending.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint("🚀 Syncing ${pending.length} pending records...");

      // 2. 数据处理与分流
      // 优化：改为批量上传以减少请求数
      List<Map<String, dynamic>> readingsPayload = [];
      List<Map<String, dynamic>> wifiPayload = []; // 分流出的 WiFi 数据
      List<int> batchIds = [];

      for (var row in pending) {
        try {
          // A. 解析原始数据
          final data = Map<String, dynamic>.from(
              jsonDecode(row['reading_data'] as String));
          batchIds.add(row['id'] as int);

          // B. 提取并分离 WiFi 数据 (如果存在)
          if (data.containsKey('wifi_data')) {
            final List wifiList = data['wifi_data'];
            // 只有当有有效扫描结果时才记录
            if (wifiList.isNotEmpty) {
              // 构造 wifi_logs 记录
              wifiPayload.add({
                'user_id': _client.auth.currentUser?.id,
                'device_id': data['node_id'], // anonymized_id
                'latitude': _extractLat(data['location']),
                'longitude': _extractLng(data['location']),
                'scan_data': wifiList,
                'scan_count': wifiList.length,
                'created_at': data['timestamp'], // 保持时间同步
                'is_verified': false,
              });
            }
            // 从主表中移除，防止字段不匹配报错
            data.remove('wifi_data');
          }

          readingsPayload.add(data);
        } catch (e) {
          debugPrint(
              "❌ Corrupt data found in sync, deleting ID ${row['id']}: $e");
          await _db!.delete('pending_readings',
              where: 'id = ?', whereArgs: [row['id']]);
        }
      }

      // 3. 执行分流上传
      // A. 上传 WiFi 数据 (允许失败)
      if (wifiPayload.isNotEmpty) {
        try {
          debugPrint("📡 Uploading ${wifiPayload.length} WiFi fingerprints...");
          await _client.from('wifi_logs').insert(wifiPayload);
        } catch (e) {
          debugPrint("⚠️ WiFi upload warning: $e");
          // WiFi 上传失败不阻断主流程
        }
      }

      // B. 上传主传感器数据
      if (readingsPayload.isNotEmpty) {
        await _client.from('readings').insert(readingsPayload);

        // 4. 上传成功，删除本地记录
        debugPrint(
            "✅ Batch upload (Sensors+WiFi) success! Clearing local DB...");
        for (var id in batchIds) {
          await _db!
              .delete('pending_readings', where: 'id = ?', whereArgs: [id]);
        }
      }

      // 如果还有剩余，继续同步
      if (pending.length == 50) {
        _isSyncing = false;
        syncPendingData(); // Recursive call for next batch
        return;
      }
    } catch (e) {
      debugPrint("⚠️ Sync failed (Network issue?): $e");
    } finally {
      _isSyncing = false;
    }
  }

  // Helpers to parse "POINT(lng lat)"
  double _extractLat(String wkt) {
    try {
      // POINT(121.5 31.2) -> "121.5 31.2" -> splitting
      final clean = wkt.replaceAll('POINT(', '').replaceAll(')', '');
      final parts = clean.split(' ');
      return double.parse(parts[1]); // Lat is 2nd
    } catch (e) {
      return 0.0;
    }
  }

  double _extractLng(String wkt) {
    try {
      final clean = wkt.replaceAll('POINT(', '').replaceAll(')', '');
      final parts = clean.split(' ');
      return double.parse(parts[0]); // Lng is 1st
    } catch (e) {
      return 0.0;
    }
  }
}
