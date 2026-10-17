<<<<<<< HEAD
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
=======
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../model/journal_entry.dart';
import '../../repository/journal_repository.dart';

final journalViewModelProvider =
    AsyncNotifierProvider<JournalViewModel, List<JournalEntry>>(
  JournalViewModel.new,
);

class JournalViewModel extends AsyncNotifier<List<JournalEntry>> {
  JournalRepository get _repository => ref.read(journalRepositoryProvider);

  @override
  Future<List<JournalEntry>> build() {
    return _repository.getEntries();
  }

  Future<void> saveEntry({
    String? id,
    required String title,
    required String body,
    String? prompt,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.saveEntry(
        id: id,
        title: title,
        body: body,
        prompt: prompt,
      );
      return _repository.getEntries();
    });
  }

  Future<void> deleteEntry(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _repository.deleteEntry(id);
      return _repository.getEntries();
    });
>>>>>>> 646c0a0 (new feature added)
  }
}
