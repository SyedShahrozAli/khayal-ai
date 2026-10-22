import 'dart:io' show Platform;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../model/journal_entry.dart';
import 'journal_local_dao.dart';

part 'journal_repository.g.dart';

final _kBaseUrl = Platform.isAndroid
    ? 'http://192.168.110.232:8000'
    : 'http://localhost:8000';

@riverpod
JournalRepository journalRepository(Ref ref) => JournalRepository();

class JournalRepository {
  final JournalLocalDao _localDao = JournalLocalDao();
  final Uuid _uuid = const Uuid();

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<Options?> _authOptions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final token = await user.getIdToken().timeout(const Duration(seconds: 8));
      return Options(headers: {'Authorization': 'Bearer $token'});
    } catch (_) {
      return null;
    }
  }

  Future<bool> _isOnline() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Fetches entries from remote backend and caches locally.
  /// If offline or server error, serves gracefully from local SQLite (REL-1).
  Future<List<JournalEntry>> fetchEntries({
    int page = 1,
    String? entryType,
    String? language,
  }) async {
    final uid = _currentUserId ?? 'anonymous';

    // First attempt remote fetch if online
    if (await _isOnline()) {
      try {
        final opts = await _authOptions();
        if (opts != null) {
          final query = <String, dynamic>{'page': page, 'page_size': 20};
          if (entryType != null) query['entry_type'] = entryType;
          if (language != null) query['language'] = language;

          final response = await _dio.get(
            '/journal/entries',
            queryParameters: query,
            options: opts,
          );
          final List data = response.data as List;
          final remoteEntries = data
              .map((e) => JournalEntry.fromJson(e as Map<String, dynamic>))
              .toList();

          // Cache remote entries in SQLite
          for (final entry in remoteEntries) {
            await _localDao.insertOrUpdate(entry);
          }
          return remoteEntries;
        }
      } catch (_) {
        // Fall back to local SQLite on network failure
      }
    }

    // Serve from local database
    final localEntries = await _localDao.getAll(uid);
    if (entryType != null || language != null) {
      return localEntries.where((e) {
        if (entryType != null && e.entryType != entryType) return false;
        if (language != null && e.language != language) return false;
        return true;
      }).toList();
    }
    return localEntries;
  }

  /// Creates a new journal entry.
  /// Saves locally immediately and attempts remote sync.
  Future<JournalEntry> createEntry({
    String? title,
    required String contentText,
    String entryType = 'text',
    String language = 'en',
    List<String> tags = const [],
    bool isDraft = false,
  }) async {
    final uid = _currentUserId ?? 'guest_${_uuid.v4().substring(0, 8)}';
    final now = DateTime.now();
    final localId = _uuid.v4();

    JournalEntry entry = JournalEntry(
      id: localId,
      userId: uid,
      entryType: entryType,
      contentText: contentText,
      title: title,
      language: language,
      tags: tags,
      isDraft: isDraft,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
      syncedAt: null,
    );

    // Save locally first to ensure REL-1 (zero data loss)
    await _localDao.insertOrUpdate(entry);

    // If online and not explicitly draft, attempt remote persist
    if (!isDraft && await _isOnline()) {
      try {
        final opts = await _authOptions();
        if (opts != null) {
          final response = await _dio.post(
            '/journal/entries',
            data: {
              'title': title,
              'content_text': contentText,
              'entry_type': entryType,
              'language': language,
              'tags': tags,
              'is_draft': false,
            },
            options: opts,
          );
          final remoteEntry = JournalEntry.fromJson(
            response.data as Map<String, dynamic>,
          );
          await _localDao.insertOrUpdate(remoteEntry);
          return remoteEntry;
        }
      } catch (_) {
        // Mark as unsynced local draft on network failure
        entry = entry.copyWith(isDraft: true);
        await _localDao.insertOrUpdate(entry);
      }
    }

    return entry;
  }

  /// Updates an existing journal entry (FE-4).
  Future<JournalEntry> updateEntry({
    required String id,
    String? title,
    required String contentText,
    String? language,
    String? entryType,
    List<String>? tags,
  }) async {
    final uid = _currentUserId ?? 'anonymous';
    final existing = await _localDao.getById(id, uid);
    final now = DateTime.now();

    JournalEntry updated = existing != null
        ? existing.copyWith(
            title: title,
            contentText: contentText,
            language: language ?? existing.language,
            entryType: entryType ?? existing.entryType,
            tags: tags ?? existing.tags,
            updatedAt: now,
          )
        : JournalEntry(
            id: id,
            userId: uid,
            entryType: entryType ?? 'text',
            contentText: contentText,
            title: title,
            language: language ?? 'en',
            tags: tags ?? [],
            createdAt: now,
            updatedAt: now,
          );

    // Update locally
    await _localDao.insertOrUpdate(updated);

    // Attempt remote update
    if (await _isOnline()) {
      try {
        final opts = await _authOptions();
        if (opts != null) {
          final response = await _dio.patch(
            '/journal/entries/$id',
            data: {
              'title': title,
              'content_text': contentText,
              'language': language,
              'entry_type': entryType,
              'tags': tags,
            },
            options: opts,
          );
          final remote = JournalEntry.fromJson(
            response.data as Map<String, dynamic>,
          );
          await _localDao.insertOrUpdate(remote);
          return remote;
        }
      } catch (_) {
        // Kept locally as modified draft
      }
    }

    return updated;
  }

  /// Soft deletes a journal entry locally and on the server (FE-4).
  Future<void> deleteEntry(String id) async {
    final uid = _currentUserId ?? 'anonymous';
    await _localDao.softDelete(id, uid);

    if (await _isOnline()) {
      try {
        final opts = await _authOptions();
        if (opts != null) {
          await _dio.delete(
            '/journal/entries/$id',
            queryParameters: {'soft': true},
            options: opts,
          );
        }
      } catch (_) {}
    }
  }

  /// Synchronizes all offline drafts with the server (FE-5, REL-1).
  Future<int> syncOfflineDrafts() async {
    final uid = _currentUserId ?? 'anonymous';
    final drafts = await _localDao.getUnsyncedDrafts(uid);
    if (drafts.isEmpty) return 0;

    if (!await _isOnline()) return 0;

    final opts = await _authOptions();
    if (opts == null) return 0;

    try {
      final payload = {'entries': drafts.map((e) => e.toJson()).toList()};
      final response = await _dio.post(
        '/journal/sync',
        data: payload,
        options: opts,
      );

      final syncedIds = List<String>.from(response.data['synced_ids'] ?? []);
      if (syncedIds.isNotEmpty) {
        await _localDao.batchMarkSynced(syncedIds, DateTime.now());
      }
      return syncedIds.length;
    } catch (_) {
      return 0;
    }
  }

  Future<int> getPendingDraftsCount() async {
    final uid = _currentUserId ?? 'anonymous';
    final drafts = await _localDao.getUnsyncedDrafts(uid);
    return drafts.length;
  }
}
