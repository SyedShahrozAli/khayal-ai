import 'package:flutter/material.dart';

import 'breath_phase.dart';

class BreathingExercise {
  final String id;
  final String title;
  final String subtitle;
  final Color color;
  final List<BreathPhase> phases;
  final int defaultMinutes;

  const BreathingExercise({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.phases,
    this.defaultMinutes = 3,
  });

  int get cycleSeconds => phases.fold(0, (sum, phase) => sum + phase.seconds);
}
