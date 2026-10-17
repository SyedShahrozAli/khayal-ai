import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/constants.dart';
import '../../../activity/repository/activity_repository.dart';
import '../../../profile/ui/view_model/profile_view_model.dart';
import 'home_state.dart';

part 'home_view_model.g.dart';

const _moodLabels = ['Very Sad', 'Sad', 'Okay', 'Happy', 'Excited'];

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  Future<HomeState> build() async {
    final profileState = await ref.watch(profileViewModelProvider.future);
    final savedMood = await _loadTodayMood();
    final streakData = await _handleStreakLogic();

    return HomeState(
      userName: profileState.profile?.name,
      selectedMoodIndex: savedMood,
      moodLocked: savedMood != null,
      streakCount: streakData.count,
      weekStatus: streakData.weekStatus,
    );
  }

  Future<({int count, List<bool> weekStatus})> _handleStreakLogic() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _todayString();
    final yesterday = _dateString(now.subtract(const Duration(days: 1)));
    final lastLogin = prefs.getString(Constants.lastLoginDateKey);
    var currentCount = prefs.getInt(Constants.streakCountKey) ?? 0;
    var weekStatusStrings =
        prefs.getStringList(Constants.weekStatusKey) ?? List.filled(7, 'false');

    if (lastLogin != today) {
      currentCount = lastLogin == yesterday ? currentCount + 1 : 1;
      if (now.weekday == DateTime.monday) {
        weekStatusStrings = List.filled(7, 'false');
      }
      weekStatusStrings[now.weekday - 1] = 'true';
      await prefs.setString(Constants.lastLoginDateKey, today);
      await prefs.setInt(Constants.streakCountKey, currentCount);
      await prefs.setStringList(Constants.weekStatusKey, weekStatusStrings);
    }

    return (
      count: currentCount,
      weekStatus: weekStatusStrings.map((value) => value == 'true').toList(),
    );
  }

  Future<int?> _loadTodayMood() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(Constants.moodDateKey) != _todayString()) return null;
    return prefs.getInt(Constants.moodKey);
  }

  Future<void> saveMood(int index) async {
    final current = state.value;
    if (current?.moodLocked == true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Constants.moodKey, index);
    await prefs.setString(Constants.moodDateKey, _todayString());
    await ref
        .read(activityRepositoryProvider)
        .upsertMood(moodIndex: index, label: _moodLabels[index]);
    await refreshStreak();
    final updated = state.value ?? current ?? const HomeState();
    state = AsyncData(
      updated.copyWith(selectedMoodIndex: index, moodLocked: true),
    );
  }

  Future<void> refreshStreak() async {
    final current = state.value;
    if (current == null) return;
    final streak = await ref.read(activityRepositoryProvider).getStreakStats();
    state = AsyncData(current.copyWith(streakCount: streak.current));
  }

  String _todayString() => _dateString(DateTime.now());

  String _dateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
