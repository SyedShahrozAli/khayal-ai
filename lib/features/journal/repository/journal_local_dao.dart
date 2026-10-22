import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../../../constants/database_constants.dart';
import '../../../utils/database_helper.dart';
import '../model/journal_entry.dart';

class JournalLocalDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  Map<String, dynamic> _toMap(JournalEntry entry) {
    return {
      JournalTable.columnId: entry.id,
      JournalTable.columnUserId: entry.userId,
      JournalTable.columnEntryType: entry.entryType,
      JournalTable.columnContentText: entry.contentText,
      JournalTable.columnTitle: entry.title,
      JournalTable.columnLanguage: entry.language,
      JournalTable.columnTags: jsonEncode(entry.tags),
      JournalTable.columnSentiment: entry.sentiment != null
          ? jsonEncode(entry.sentiment)
          : null,
      JournalTable.columnDetectedKeywords: jsonEncode(entry.detectedKeywords),
      JournalTable.columnIsDraft: entry.isDraft ? 1 : 0,
      JournalTable.columnIsDeleted: entry.isDeleted ? 1 : 0,
      JournalTable.columnCreatedAt: entry.createdAt.toIso8601String(),
      JournalTable.columnUpdatedAt: entry.updatedAt.toIso8601String(),
      JournalTable.columnSyncedAt: entry.syncedAt?.toIso8601String(),
    };
  }

  JournalEntry _fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      try {
        final decoded = jsonDecode(val.toString());
        if (decoded is List) return decoded.map((e) => e.toString()).toList();
      } catch (_) {}
      return [];
    }

    Map<String, dynamic>? parseMap(dynamic val) {
      if (val == null) return null;
      if (val is Map) return Map<String, dynamic>.from(val);
      try {
        final decoded = jsonDecode(val.toString());
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
      return null;
    }

    return JournalEntry(
      id: map[JournalTable.columnId] as String,
      userId: map[JournalTable.columnUserId] as String,
      entryType: map[JournalTable.columnEntryType] as String? ?? 'text',
      contentText: map[JournalTable.columnContentText] as String,
      title: map[JournalTable.columnTitle] as String?,
      language: map[JournalTable.columnLanguage] as String? ?? 'en',
      tags: parseList(map[JournalTable.columnTags]),
      sentiment: parseMap(map[JournalTable.columnSentiment]),
      detectedKeywords: parseList(map[JournalTable.columnDetectedKeywords]),
      isDraft: (map[JournalTable.columnIsDraft] as int? ?? 0) == 1,
      isDeleted: (map[JournalTable.columnIsDeleted] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map[JournalTable.columnCreatedAt] as String),
      updatedAt: DateTime.parse(map[JournalTable.columnUpdatedAt] as String),
      syncedAt: map[JournalTable.columnSyncedAt] != null
          ? DateTime.tryParse(map[JournalTable.columnSyncedAt] as String)
          : null,
    );
  }

  Future<void> insertOrUpdate(JournalEntry entry) async {
    final db = await _db;
    await db.insert(
      JournalTable.tableName,
      _toMap(entry),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<JournalEntry>> getAll(String userId) async {
    final db = await _db;
    final results = await db.query(
      JournalTable.tableName,
      where:
          '${JournalTable.columnUserId} = ? AND ${JournalTable.columnIsDeleted} = 0',
      whereArgs: [userId],
      orderBy: '${JournalTable.columnCreatedAt} DESC',
    );
    return results.map(_fromMap).toList();
  }

  Future<JournalEntry?> getById(String id, String userId) async {
    final db = await _db;
    final results = await db.query(
      JournalTable.tableName,
      where:
          '${JournalTable.columnId} = ? AND ${JournalTable.columnUserId} = ? AND ${JournalTable.columnIsDeleted} = 0',
      whereArgs: [id, userId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _fromMap(results.first);
  }

  Future<void> softDelete(String id, String userId) async {
    final db = await _db;
    await db.update(
      JournalTable.tableName,
      {
        JournalTable.columnIsDeleted: 1,
        JournalTable.columnUpdatedAt: DateTime.now().toIso8601String(),
      },
      where:
          '${JournalTable.columnId} = ? AND ${JournalTable.columnUserId} = ?',
      whereArgs: [id, userId],
    );
  }

  Future<List<JournalEntry>> getUnsyncedDrafts(String userId) async {
    final db = await _db;
    final results = await db.query(
      JournalTable.tableName,
      where:
          '${JournalTable.columnUserId} = ? AND ${JournalTable.columnIsDraft} = 1',
      whereArgs: [userId],
      orderBy: '${JournalTable.columnCreatedAt} ASC',
    );
    return results.map(_fromMap).toList();
  }

  Future<void> markSynced(String id, DateTime syncedAt) async {
    final db = await _db;
    await db.update(
      JournalTable.tableName,
      {
        JournalTable.columnIsDraft: 0,
        JournalTable.columnSyncedAt: syncedAt.toIso8601String(),
      },
      where: '${JournalTable.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> batchMarkSynced(List<String> ids, DateTime syncedAt) async {
    if (ids.isEmpty) return;
    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      '''
      UPDATE ${JournalTable.tableName}
      SET ${JournalTable.columnIsDraft} = 0,
          ${JournalTable.columnSyncedAt} = ?
      WHERE ${JournalTable.columnId} IN ($placeholders)
      ''',
      [syncedAt.toIso8601String(), ...ids],
    );
  }
}
