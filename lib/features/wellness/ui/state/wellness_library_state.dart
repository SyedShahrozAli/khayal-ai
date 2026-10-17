class WellnessLibraryState {
  final Set<String> favourites;
  final Map<String, int> durations;

  const WellnessLibraryState({
    this.favourites = const {},
    this.durations = const {},
  });

  WellnessLibraryState copyWith({
    Set<String>? favourites,
    Map<String, int>? durations,
  }) {
    return WellnessLibraryState(
      favourites: favourites ?? this.favourites,
      durations: durations ?? this.durations,
    );
  }
}
