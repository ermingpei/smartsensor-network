import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

import '../features/report_generator_page.dart';

/// Repository for storing and retrieving report history locally
class ReportRepository {
  static Database? _database;
  static const String _tableName = 'reports';

  /// Initialize the database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smartsensor_reports.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            title TEXT,
            created_at INTEGER NOT NULL,
            data TEXT NOT NULL
          )
        ''');
        debugPrint('📋 Reports database created');
      },
    );
  }

  /// Save a report to local storage
  static Future<void> saveReport(ReportData report, {String? title}) async {
    final db = await database;

    await db.insert(
      _tableName,
      {
        'id': report.id,
        'type': report.type,
        'title': title,
        'created_at': report.createdAt.millisecondsSinceEpoch,
        'data': jsonEncode(report.data),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('📋 Report saved: ${report.id}');
  }

  /// Get all saved reports, ordered by date descending
  static Future<List<ReportData>> getReports() async {
    final db = await database;

    final results = await db.query(
      _tableName,
      orderBy: 'created_at DESC',
    );

    return results
        .map((row) => ReportData(
              id: row['id'] as String,
              type: row['type'] as String,
              createdAt:
                  DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
              data: jsonDecode(row['data'] as String) as Map<String, dynamic>,
            ))
        .toList();
  }

  /// Get a single report by ID
  static Future<ReportData?> getReport(String id) async {
    final db = await database;

    final results = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final row = results.first;
    return ReportData(
      id: row['id'] as String,
      type: row['type'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      data: jsonDecode(row['data'] as String) as Map<String, dynamic>,
    );
  }

  /// Delete a report by ID
  static Future<void> deleteReport(String id) async {
    final db = await database;

    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
    debugPrint('🗑️ Report deleted: $id');
  }

  /// Get report count
  static Future<int> getReportCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Clear all reports
  static Future<void> clearAllReports() async {
    final db = await database;
    await db.delete(_tableName);
    debugPrint('🗑️ All reports cleared');
  }
}
