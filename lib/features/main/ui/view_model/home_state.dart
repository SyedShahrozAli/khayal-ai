class HomeState {
  final String? userName;
  final int? selectedMoodIndex;
  final bool moodLocked;
  final int streakCount;
  final List<bool> weekStatus;

  const HomeState({
    this.userName,
    this.selectedMoodIndex,
    this.moodLocked = false,
    this.streakCount = 0,
    this.weekStatus = const [false, false, false, false, false, false, false],
  });

  HomeState copyWith({
    String? userName,
    int? selectedMoodIndex,
    bool? moodLocked,
    int? streakCount,
    List<bool>? weekStatus,
  }) {
    return HomeState(
      userName: userName ?? this.userName,
      selectedMoodIndex: selectedMoodIndex ?? this.selectedMoodIndex,
      moodLocked: moodLocked ?? this.moodLocked,
      streakCount: streakCount ?? this.streakCount,
      weekStatus: weekStatus ?? this.weekStatus,
    );
  }
}
