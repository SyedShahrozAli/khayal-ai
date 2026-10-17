import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_theme.dart';
import '../../../activity/repository/activity_repository.dart';
import '../../../main/ui/view_model/home_view_model.dart';

class ColourBreathingGame extends ConsumerStatefulWidget {
  const ColourBreathingGame({super.key});

  @override
  ConsumerState<ColourBreathingGame> createState() =>
      _ColourBreathingGameState();
}

class _ColourBreathingGameState extends ConsumerState<ColourBreathingGame>
    with SingleTickerProviderStateMixin {
  static const _sessionSeconds = 120;
  static const _phaseSeconds = 4;
  late final AnimationController _controller;
  Timer? _clock;
  int _elapsed = 0;
  bool _finished = false;
  bool _logged = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _phaseSeconds),
    )..repeat(reverse: true);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_finished) return;
      setState(() => _elapsed++);
      if (_elapsed >= _sessionSeconds) {
        _finish();
      }
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _controller.dispose();
    super.dispose();
  }

  bool get _isInhale {
    final cycle = _elapsed % (_phaseSeconds * 2);
    return cycle < _phaseSeconds;
  }

  Future<void> _finish() async {
    if (_finished) return;
    _clock?.cancel();
    setState(() => _finished = true);
    if (_logged) return;
    _logged = true;
    await ref.read(activityRepositoryProvider).logExerciseSession(
          type: 'game',
          title: 'Colour breathing',
          durationSeconds: _elapsed,
          completed: _elapsed >= (_sessionSeconds * 0.8),
        );
    await ref.read(homeViewModelProvider.notifier).refreshStreak();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final color = Color.lerp(
            const Color(0xFF5B9BBF),
            const Color(0xFFB48EC9),
            t,
          )!;
          return Container(
            color: color,
            child: SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () async {
                        await _finish();
                        if (context.mounted) context.pop();
                      },
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  Transform.scale(
                    scale: 0.7 + (t * 0.5),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.25),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          _finished
                              ? 'Done'
                              : (_isInhale ? 'Inhale' : 'Exhale'),
                          style:
                              AppTheme.title24.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _finished
                        ? 'Colour session complete'
                        : '${((_sessionSeconds - _elapsed) ~/ 60)}:${((_sessionSeconds - _elapsed) % 60).toString().padLeft(2, '0')}',
                    style: AppTheme.title18.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                  if (_finished)
                    FilledButton(
                      onPressed: () => context.pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                      ),
                      child: const Text('Finish'),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
