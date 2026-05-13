import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_state.freezed.dart';

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    /// Display name of the logged-in user (null → 'Guest')
    String? userName,

    /// Index into the mood emoji list; null means not yet chosen today
    int? selectedMoodIndex,
  }) = _HomeState;
}
