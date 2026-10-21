import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../constants/database_constants.dart';
import '../../../utils/database_helper.dart';
import '../model/exercise_session.dart';
import '../model/mood_entry.dart';
import '../model/streak_stats.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return const ActivityRepository();
});

class ActivityRepository {
  const ActivityRepository();

  static const _uuid = Uuid();

  Future<Database> get _db => DatabaseHelper.instance.database;

  String todayString([DateTime? date]) {
    final now = date ?? DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> upsertMood({
    required int moodIndex,
    required String label,
    DateTime? date,
  }) async {
    try {
      final db = await _db;
      await db.insert(
        MoodTable.tableName,
        {
          MoodTable.columnDate: todayString(date),
          MoodTable.columnMoodIndex: moodIndex,
          MoodTable.columnLabel: label,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<List<MoodEntry>> getMoodsSince(DateTime from) async {
    try {
      final db = await _db;
      final rows = await db.query(
        MoodTable.tableName,
        where: '${MoodTable.columnDate} >= ?',
        whereArgs: [todayString(from)],
        orderBy: '${MoodTable.columnDate} ASC',
      );
      return rows
          .map(
            (row) => MoodEntry(
              date: row[MoodTable.columnDate] as String,
              moodIndex: row[MoodTable.columnMoodIndex] as int,
              label: row[MoodTable.columnLabel] as String,
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> logExerciseSession({
    required String type,
    required String title,
    required int durationSeconds,
    required bool completed,
  }) async {
    if (!completed) return;
    try {
      final db = await _db;
      await db.insert(ExerciseSessionTable.tableName, {
        ExerciseSessionTable.columnId: _uuid.v4(),
        ExerciseSessionTable.columnType: type,
        ExerciseSessionTable.columnTitle: title,
        ExerciseSessionTable.columnDurationSeconds: durationSeconds,
        ExerciseSessionTable.columnCompleted: 1,
        ExerciseSessionTable.columnTimestamp:
            DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  Future<List<ExerciseSession>> getExerciseSessions({int limit = 50}) async {
    try {
      final db = await _db;
      final rows = await db.query(
        ExerciseSessionTable.tableName,
        orderBy: '${ExerciseSessionTable.columnTimestamp} DESC',
        limit: limit,
      );
      return rows
          .map(
            (row) => ExerciseSession(
              id: row[ExerciseSessionTable.columnId] as String,
              type: row[ExerciseSessionTable.columnType] as String,
              title: row[ExerciseSessionTable.columnTitle] as String,
              durationSeconds:
                  row[ExerciseSessionTable.columnDurationSeconds] as int,
              completed: (row[ExerciseSessionTable.columnCompleted] as int) == 1,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                row[ExerciseSessionTable.columnTimestamp] as int,
              ),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<ExerciseSession>> getExerciseSessionsSince(DateTime from) async {
    try {
      final db = await _db;
      final rows = await db.query(
        ExerciseSessionTable.tableName,
        where: '${ExerciseSessionTable.columnTimestamp} >= ?',
        whereArgs: [from.millisecondsSinceEpoch],
        orderBy: '${ExerciseSessionTable.columnTimestamp} DESC',
      );
      return rows
          .map(
            (row) => ExerciseSession(
              id: row[ExerciseSessionTable.columnId] as String,
              type: row[ExerciseSessionTable.columnType] as String,
              title: row[ExerciseSessionTable.columnTitle] as String,
              durationSeconds:
                  row[ExerciseSessionTable.columnDurationSeconds] as int,
              completed: (row[ExerciseSessionTable.columnCompleted] as int) == 1,
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                row[ExerciseSessionTable.columnTimestamp] as int,
              ),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> _activityDates() async {
    try {
      final db = await _db;
      final moodRows = await db.query(
        MoodTable.tableName,
        columns: [MoodTable.columnDate],
      );
      final sessionRows = await db.query(
        ExerciseSessionTable.tableName,
        columns: [ExerciseSessionTable.columnTimestamp],
      );
      final dates = <String>{};
      for (final row in moodRows) {
        dates.add(row[MoodTable.columnDate] as String);
      }
      for (final row in sessionRows) {
        final ts = DateTime.fromMillisecondsSinceEpoch(
          row[ExerciseSessionTable.columnTimestamp] as int,
        );
        dates.add(todayString(ts));
      }
      return dates;
    } catch (_) {
      return const {};
    }
  }

  Future<StreakStats> getStreakStats() async {
    try {
      final dates = await _activityDates();
      if (dates.isEmpty) {
        return const StreakStats(current: 0, best: 0);
      }

      final sorted = dates.toList()..sort();
      var best = 1;
      var run = 1;
      for (var i = 1; i < sorted.length; i++) {
        final prev = DateTime.tryParse(sorted[i - 1]);
        final current = DateTime.tryParse(sorted[i]);
        if (prev != null && current != null && current.difference(prev).inDays == 1) {
          run++;
          if (run > best) best = run;
        } else {
          run = 1;
        }
      }

      var currentStreak = 0;
      var cursor = DateTime.now();
      final today = todayString(cursor);
      final yesterday = todayString(cursor.subtract(const Duration(days: 1)));
      if (!dates.contains(today) && !dates.contains(yesterday)) {
        return StreakStats(current: 0, best: best);
      }
      if (!dates.contains(today)) {
        cursor = cursor.subtract(const Duration(days: 1));
      }
      while (dates.contains(todayString(cursor))) {
        currentStreak++;
        cursor = cursor.subtract(const Duration(days: 1));
      }

      if (currentStreak > best) best = currentStreak;
      return StreakStats(current: currentStreak, best: best);
    } catch (_) {
      return const StreakStats(current: 0, best: 0);
    }
  }
}
