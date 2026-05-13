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

    return HomeState(
      userName: profileState.profile?.name,
      selectedMoodIndex: savedMood,
    );
  }

  // ── Mood persistence ─────────────────────────────────────────────────────

  Future<int?> _loadTodayMood() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString(Constants.moodDateKey);
    final today = _todayString();
    if (savedDate != today) return null; // new day → reset
    final index = prefs.getInt(Constants.moodKey);
    return index;
  }

  Future<void> saveMood(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(Constants.moodKey, index);
    await prefs.setString(Constants.moodDateKey, _todayString());

    // Update in-memory state
    final current = state.value;
    if (current != null) {
      state = AsyncData(current.copyWith(selectedMoodIndex: index));
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
