class ExerciseSession {
  final String id;
  final String type;
  final String title;
  final int durationSeconds;
  final bool completed;
  final DateTime timestamp;

  const ExerciseSession({
    required this.id,
    required this.type,
    required this.title,
    required this.durationSeconds,
    required this.completed,
    required this.timestamp,
  });
}
