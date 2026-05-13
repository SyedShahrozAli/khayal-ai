import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../constants/constants.dart';
import '../../../profile/ui/view_model/profile_view_model.dart';
import 'home_state.dart';

part 'home_view_model.g.dart';

@riverpod
class HomeViewModel extends _$HomeViewModel {
  @override
  Future<HomeState> build() async {
    // Load profile from the keep-alive ProfileViewModel
    final profileState = await ref.watch(
      profileViewModelProvider.future,
    );

    // Restore today's saved mood (null if not yet selected today)
    final savedMood = await _loadTodayMood();

    // Mood is locked if it was already recorded for today
    final locked = savedMood != null;

    // Update and get streak info
    final streakData = await _handleStreakLogic();

    return HomeState(
      userName: profileState.profile?.name,
      selectedMoodIndex: savedMood,
      moodLocked: locked,
      streakCount: streakData.count,
      weekStatus: streakData.weekStatus,
    );
  }

  // ── Streak logic ─────────────────────────────────────────────────────────

  Future<({int count, List<bool> weekStatus})> _handleStreakLogic() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = _todayString();
    final yesterday = _dateString(now.subtract(const Duration(days: 1)));
    
    final lastLogin = prefs.getString(Constants.lastLoginDateKey);
    int currentCount = prefs.getInt(Constants.streakCountKey) ?? 0;
    
    // Get or initialize week status
    List<String> weekStatusStrings = prefs.getStringList(Constants.weekStatusKey) ?? 
        List.filled(7, 'false');
    
    // If it's a new day, we need to process streak
    if (lastLogin != today) {
      if (lastLogin == yesterday) {
        // Consecutive day
        currentCount++;
      } else {
        // Missed a day or more
        currentCount = 1;
      }
      
      // Check if we need to reset week status (if it's Monday or if we missed a lot of time)
      // For simplicity, let's reset if the last login was in a different week
      // Or just clear the week if today is Monday
      if (now.weekday == DateTime.monday) {
        weekStatusStrings = List.filled(7, 'false');
      }

      // Mark today as active in the week status
      // DateTime.monday is 1, so index is now.weekday - 1
      weekStatusStrings[now.weekday - 1] = 'true';
      
      // Save everything
      await prefs.setString(Constants.lastLoginDateKey, today);
      await prefs.setInt(Constants.streakCountKey, currentCount);
      await prefs.setStringList(Constants.weekStatusKey, weekStatusStrings);
    }

    return (
      count: currentCount,
      weekStatus: weekStatusStrings.map((e) => e == 'true').toList(),
    );
  }

  // ── Mood persistence ─────────────────────────────────────────────────────

  Future<int?> _loadTodayMood() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(Constants.moodDateKey);
    final today = _todayString();
    // A new calendar day → no mood recorded yet
    if (savedDate != today) return null;
    return prefs.getInt(Constants.moodKey);
  }

  /// Saves the mood index for today.
  /// If the mood has already been locked for today this is a no-op —
  /// the user cannot change their recorded mood within the same day.
  Future<void> saveMood(int index) async {
    final current = state.value;

    // Guard: already locked for today → ignore
    if (current?.moodLocked == true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Constants.moodKey, index);
    await prefs.setString(Constants.moodDateKey, _todayString());

    // Update in-memory state and lock immediately
    state = AsyncData(
      (current ?? HomeState()).copyWith(
        selectedMoodIndex: index,
        moodLocked: true,
      ),
    );
  }

  String _todayString() => _dateString(DateTime.now());

  String _dateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
