import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repository/wellness_preferences_repository.dart';
import '../state/wellness_library_state.dart';

final wellnessLibraryViewModelProvider =
    AsyncNotifierProvider<WellnessLibraryViewModel, WellnessLibraryState>(
  WellnessLibraryViewModel.new,
);

class WellnessLibraryViewModel extends AsyncNotifier<WellnessLibraryState> {
  @override
  Future<WellnessLibraryState> build() async {
    final repo = ref.read(wellnessPreferencesRepositoryProvider);
    final favourites = await repo.getFavourites();
    final durations = await repo.getDurations();
    return WellnessLibraryState(
      favourites: favourites,
      durations: durations,
    );
  }

  Future<void> toggleFavourite(String exerciseId) async {
    await ref
        .read(wellnessPreferencesRepositoryProvider)
        .toggleFavourite(exerciseId);
    ref.invalidateSelf();
  }

  Future<void> setDuration(String exerciseId, int minutes) async {
    await ref
        .read(wellnessPreferencesRepositoryProvider)
        .setDuration(exerciseId, minutes);
    ref.invalidateSelf();
  }
}
