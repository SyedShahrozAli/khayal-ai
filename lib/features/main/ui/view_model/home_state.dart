class HomeState {
  /// Display name of the logged-in user (null → 'Guest')
  final String? userName;

  /// Index into the mood emoji list; null means not yet chosen today
  final int? selectedMoodIndex;

  /// True once the user has submitted their mood for today.
  final bool moodLocked;

  /// Consecutive days with a mood or completed exercise.
  final int streakCount;

  const HomeState({
    this.userName,
    this.selectedMoodIndex,
    this.moodLocked = false,
    this.streakCount = 0,
  });

  HomeState copyWith({
    String? userName,
    int? selectedMoodIndex,
<<<<<<< HEAD

    /// True once the user has submitted their mood for today.
    /// Emojis become non-interactive until the next calendar day.
    @Default(false) bool moodLocked,

    @Default(0) int streakCount,

    /// List of 7 booleans representing Mon-Sun status for the current week
    @Default(const [false, false, false, false, false, false, false]) List<bool> weekStatus,
  }) = _HomeState;
=======
    bool? moodLocked,
    int? streakCount,
  }) {
    return HomeState(
      userName: userName ?? this.userName,
      selectedMoodIndex: selectedMoodIndex ?? this.selectedMoodIndex,
      moodLocked: moodLocked ?? this.moodLocked,
      streakCount: streakCount ?? this.streakCount,
    );
  }
>>>>>>> 646c0a0 (new feature added)
}
