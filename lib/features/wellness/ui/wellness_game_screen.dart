import 'package:flutter/material.dart';

import 'games/bubble_pop_game.dart';
import 'games/colour_breathing_game.dart';

class WellnessGameScreen extends StatelessWidget {
  final String gameId;

  const WellnessGameScreen({super.key, required this.gameId});

  @override
  Widget build(BuildContext context) {
    if (gameId == 'colour_breathing') {
      return const ColourBreathingGame();
    }
    return const BubblePopGame();
  }
}
