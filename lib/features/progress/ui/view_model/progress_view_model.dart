import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../activity/repository/activity_repository.dart';
import '../state/progress_state.dart';

final progressViewModelProvider =
    AsyncNotifierProvider<ProgressViewModel, ProgressState>(
  ProgressViewModel.new,
);

class ProgressViewModel extends AsyncNotifier<ProgressState> {
  int _rangeDays = 7;

  @override
  Future<ProgressState> build() => _load(_rangeDays);

  Future<ProgressState> _load(int rangeDays) async {
    final repo = ref.read(activityRepositoryProvider);
    final from = DateTime.now().subtract(Duration(days: rangeDays - 1));
    final weekFrom = DateTime.now().subtract(const Duration(days: 6));
    final moods = await repo.getMoodsSince(from);
    final sessions = await repo.getExerciseSessions();
    final weekSessions = await repo.getExerciseSessionsSince(weekFrom);
    final streak = await repo.getStreakStats();
    return ProgressState(
      rangeDays: rangeDays,
      moods: moods,
      sessions: sessions,
      weekSessions: weekSessions,
      streak: streak,
    );
  }

  Future<void> setRange(int days) async {
    _rangeDays = days;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(days));
  }
}
