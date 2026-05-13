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
    // Kick off loading after construction
    Future.microtask(refresh);
    return const JournalState();
  }

  Future<void> refresh() async {
    state = const JournalState(isSaving: true);
    try {
      final entries = await _repo.fetchEntries(page: 1);
      state = JournalState(
        entries: entries,
        page: 1,
        hasMore: entries.length >= 20,
      );
    } catch (e) {
      state = const JournalState();
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
    required String content,
    List<String> tags = const [],
  }) async {
    state = state.copyWith(isSaving: true);
    try {
      final entry = await _repo.createEntry(
        title: title,
        content: content,
        tags: tags,
      );
      state = state.copyWith(
        isSaving: false,
        entries: [entry, ...state.entries],
      );
      return entry;
    } catch (e) {
      state = state.copyWith(isSaving: false);
      rethrow;
    }
  }

  Future<void> deleteEntry(String id) async {
    await _repo.deleteEntry(id);
    state = state.copyWith(
      entries: state.entries.where((e) => e.id != id).toList(),
    );
  }
}
