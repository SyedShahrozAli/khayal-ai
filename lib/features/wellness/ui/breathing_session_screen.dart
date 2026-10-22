import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_theme.dart';
import '../../activity/repository/activity_repository.dart';
import '../../main/ui/view_model/home_view_model.dart';
import '../model/breathing_exercise.dart';
import '../model/wellness_catalog.dart';

class BreathingSessionScreen extends ConsumerStatefulWidget {
  final String exerciseId;
  final int minutes;

  const BreathingSessionScreen({
    super.key,
    required this.exerciseId,
    required this.minutes,
  });

  @override
  ConsumerState<BreathingSessionScreen> createState() =>
      _BreathingSessionScreenState();
}

class _BreathingSessionScreenState extends ConsumerState<BreathingSessionScreen>
    with SingleTickerProviderStateMixin {
  late final BreathingExercise _exercise;
  late final int _totalSeconds;
  late final AnimationController _pulse;
  Timer? _timer;
  int _elapsed = 0;
  bool _finished = false;
  bool _logged = false;

  @override
  void initState() {
    super.initState();
    _exercise = WellnessCatalog.byId(widget.exerciseId);
    _totalSeconds = widget.minutes * 60;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _finished) return;
      setState(() => _elapsed++);
      if (_elapsed >= _totalSeconds) {
        _completeSession();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  int get _cycleSeconds => math.max(1, _exercise.cycleSeconds);

  String get _phaseLabel {
    var offset = _elapsed % _cycleSeconds;
    for (final phase in _exercise.phases) {
      if (offset < phase.seconds) return phase.label;
      offset -= phase.seconds;
    }
    return _exercise.phases.first.label;
  }

  double get _progress => (_elapsed / _totalSeconds).clamp(0, 1);

  Future<void> _completeSession() async {
    _timer?.cancel();
    setState(() => _finished = true);
    await _logIfNeeded(forceComplete: true);
  }

  Future<void> _logIfNeeded({bool forceComplete = false}) async {
    if (_logged) return;
    final ratio = _elapsed / _totalSeconds;
    final completed = forceComplete || ratio >= 0.8;
    if (!completed) return;
    _logged = true;
    await ref
        .read(activityRepositoryProvider)
        .logExerciseSession(
          type: 'breathing',
          title: _exercise.title,
          durationSeconds: _elapsed,
          completed: true,
        );
    await ref.read(homeViewModelProvider.notifier).refreshStreak();
  }

  Future<void> _exit() async {
    await _logIfNeeded();
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _exercise.color,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _exit,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      _exercise.title,
                      style: AppTheme.title18.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final scale = _finished ? 1.0 : 0.85 + (_pulse.value * 0.25);
                  return Transform.scale(scale: scale, child: child);
                },
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _finished ? 'Done' : _phaseLabel,
                      style: AppTheme.title24.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                _finished
                    ? 'Session complete'
                    : '${(_totalSeconds - _elapsed) ~/ 60}:${((_totalSeconds - _elapsed) % 60).toString().padLeft(2, '0')}',
                style: AppTheme.title20.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.white24,
                color: Colors.white,
              ),
              const Spacer(),
              if (_finished)
                FilledButton(
                  onPressed: _exit,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.mono90,
                  ),
                  child: const Text('Finish'),
                )
              else
                TextButton(
                  onPressed: _exit,
                  child: Text(
                    'End early',
                    style: AppTheme.body16.copyWith(color: Colors.white),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
