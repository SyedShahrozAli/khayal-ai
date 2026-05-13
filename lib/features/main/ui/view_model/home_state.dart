import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    /// Display name of the logged-in user (null → 'Guest')
    String? userName,

    /// Index into the mood emoji list; null means not yet chosen today
    int? selectedMoodIndex,

    /// True once the user has submitted their mood for today.
    /// Emojis become non-interactive until the next calendar day.
    @Default(false) bool moodLocked,

    @Default(0) int streakCount,

    /// List of 7 booleans representing Mon-Sun status for the current week
    @Default(const [false, false, false, false, false, false, false]) List<bool> weekStatus,
  }) = _HomeState;
}
