import 'package:flutter/material.dart';

import 'breath_phase.dart';
import 'breathing_exercise.dart';

class WellnessCatalog {
  WellnessCatalog._();

  static const exercises = [
    BreathingExercise(
      id: 'box',
      title: 'Box breathing',
      subtitle: 'Inhale, hold, exhale, rest — four equal sides',
      color: Color(0xFF5B9BBF),
      phases: [
        BreathPhase(label: 'Inhale', seconds: 4),
        BreathPhase(label: 'Hold', seconds: 4),
        BreathPhase(label: 'Exhale', seconds: 4),
        BreathPhase(label: 'Rest', seconds: 4),
      ],
    ),
    BreathingExercise(
      id: '478',
      title: '4-7-8 breathing',
      subtitle: 'A longer exhale to settle the nervous system',
      color: Color(0xFF7E8CC5),
      defaultMinutes: 4,
      phases: [
        BreathPhase(label: 'Inhale', seconds: 4),
        BreathPhase(label: 'Hold', seconds: 7),
        BreathPhase(label: 'Exhale', seconds: 8),
      ],
    ),
    BreathingExercise(
      id: 'equal',
      title: 'Equal breathing',
      subtitle: 'Match the length of inhale and exhale',
      color: Color(0xFF5BAFA6),
      phases: [
        BreathPhase(label: 'Inhale', seconds: 5),
        BreathPhase(label: 'Exhale', seconds: 5),
      ],
    ),
    BreathingExercise(
      id: 'calm',
      title: 'Calm inhale',
      subtitle: 'Soft inhale, slower exhale',
      color: Color(0xFFF2BDC0),
      phases: [
        BreathPhase(label: 'Inhale', seconds: 4),
        BreathPhase(label: 'Exhale', seconds: 6),
        BreathPhase(label: 'Rest', seconds: 2),
      ],
    ),
    BreathingExercise(
      id: 'bodyscan',
      title: 'Body scan',
      subtitle: 'Gently notice each part of the body',
      color: Color(0xFFC9A87C),
      defaultMinutes: 5,
      phases: [
        BreathPhase(label: 'Feet', seconds: 8),
        BreathPhase(label: 'Legs', seconds: 8),
        BreathPhase(label: 'Chest', seconds: 8),
        BreathPhase(label: 'Arms', seconds: 8),
        BreathPhase(label: 'Face', seconds: 8),
      ],
    ),
  ];

  static BreathingExercise byId(String id) {
    return exercises.firstWhere((exercise) => exercise.id == id);
  }
}

class WellnessGameInfo {
  final String id;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;

  const WellnessGameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

class WellnessGames {
  WellnessGames._();

  static const bubblePop = WellnessGameInfo(
    id: 'bubble_pop',
    title: 'Bubble pop',
    subtitle: 'Tap floating bubbles for a short reset',
    color: Color(0xFF7EB8D4),
    icon: Icons.bubble_chart_outlined,
  );

  static const colourBreathing = WellnessGameInfo(
    id: 'colour_breathing',
    title: 'Colour breathing',
    subtitle: 'Follow the glow as you breathe',
    color: Color(0xFFB48EC9),
    icon: Icons.blur_circular,
  );

  static const all = [bubblePop, colourBreathing];
}
