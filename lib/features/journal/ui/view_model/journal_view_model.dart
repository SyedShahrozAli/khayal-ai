import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../model/journal_entry.dart';
import '../../model/journal_state.dart';
import '../../repository/journal_repository.dart';

part 'journal_view_model.g.dart';

@riverpod
class JournalViewModel extends _$JournalViewModel {
  late JournalRepository _repo;

  @override
  JournalState build() {
    _repo = ref.read(journalRepositoryProvider);
    Future.microtask(() async {
      await refresh();
      // Auto-sync any existing offline drafts on load
      syncDrafts();
    });
    return const JournalState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isSaving: true);
    try {
      final entries = await _repo.fetchEntries(page: 1);
      final pendingCount = await _repo.getPendingDraftsCount();
      state = state.copyWith(
        entries: entries,
        isSaving: false,
        page: 1,
        hasMore: entries.length >= 20,
        pendingDraftsCount: pendingCount,
      );
    } catch (_) {
      final pendingCount = await _repo.getPendingDraftsCount();
      state = state.copyWith(
        isSaving: false,
        pendingDraftsCount: pendingCount,
      );
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.isSaving) return;
    final nextPage = state.page + 1;
    try {
      final more = await _repo.fetchEntries(page: nextPage);
      state = state.copyWith(
        entries: [...state.entries, ...more],
        page: nextPage,
        hasMore: more.length >= 20,
      );
    } catch (_) {}
  }

  Future<JournalEntry?> createEntry({
    String? title,
    required String contentText,
    String entryType = 'text',
    String language = 'en',
    List<String> tags = const [],
    bool isDraft = false,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      final entry = await _repo.createEntry(
        title: title,
        contentText: contentText,
        entryType: entryType,
        language: language,
        tags: tags,
        isDraft: isDraft,
      );
      final pendingCount = await _repo.getPendingDraftsCount();
      state = state.copyWith(
        isSaving: false,
        entries: [entry, ...state.entries],
        pendingDraftsCount: pendingCount,
      );
      return entry;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  Future<JournalEntry?> updateEntry({
    required String id,
    String? title,
    required String contentText,
    String? language,
    String? entryType,
    List<String>? tags,
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      final updated = await _repo.updateEntry(
        id: id,
        title: title,
        contentText: contentText,
        language: language,
        entryType: entryType,
        tags: tags,
      );
      final updatedList = state.entries.map((e) {
        return e.id == id ? updated : e;
      }).toList();

      final pendingCount = await _repo.getPendingDraftsCount();
      state = state.copyWith(
        isSaving: false,
        entries: updatedList,
        pendingDraftsCount: pendingCount,
      );
      return updated;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    await _repo.deleteEntry(id);
    final pendingCount = await _repo.getPendingDraftsCount();
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
      pendingDraftsCount: pendingCount,
    );
  }

  Future<int> syncDrafts() async {
    state = state.copyWith(isSyncing: true);
    try {
      final count = await _repo.syncOfflineDrafts();
      final entries = await _repo.fetchEntries(page: 1);
      final pendingCount = await _repo.getPendingDraftsCount();
      state = state.copyWith(
        entries: entries,
        isSyncing: false,
        pendingDraftsCount: pendingCount,
      );
      return count;
    } catch (_) {
      state = state.copyWith(isSyncing: false);
      return 0;
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
