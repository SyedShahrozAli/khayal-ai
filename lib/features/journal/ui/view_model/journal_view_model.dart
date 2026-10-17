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
  }
}
