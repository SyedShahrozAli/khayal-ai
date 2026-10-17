import '../../../activity/model/exercise_session.dart';
import '../../../activity/model/mood_entry.dart';
import '../../../activity/model/streak_stats.dart';

class ProgressState {
  final int rangeDays;
  final List<MoodEntry> moods;
  final List<ExerciseSession> sessions;
  final List<ExerciseSession> weekSessions;
  final StreakStats streak;

  const ProgressState({
    required this.rangeDays,
    required this.moods,
    required this.sessions,
    required this.weekSessions,
    required this.streak,
  });

  ProgressState copyWith({
    int? rangeDays,
    List<MoodEntry>? moods,
    List<ExerciseSession>? sessions,
    List<ExerciseSession>? weekSessions,
    StreakStats? streak,
  }) {
    return ProgressState(
      rangeDays: rangeDays ?? this.rangeDays,
      moods: moods ?? this.moods,
      sessions: sessions ?? this.sessions,
      weekSessions: weekSessions ?? this.weekSessions,
      streak: streak ?? this.streak,
    );
  }
}
