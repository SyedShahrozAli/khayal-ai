import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_theme.dart';
import '../../../activity/repository/activity_repository.dart';
import '../../../main/ui/view_model/home_view_model.dart';

class BubblePopGame extends ConsumerStatefulWidget {
  const BubblePopGame({super.key});

  @override
  ConsumerState<BubblePopGame> createState() => _BubblePopGameState();
}

class _Bubble {
  Offset position;
  double radius;
  Color color;
  final int id;

  _Bubble({
    required this.id,
    required this.position,
    required this.radius,
    required this.color,
  });
}

class _BubblePopGameState extends ConsumerState<BubblePopGame> {
  static const _sessionSeconds = 60;
  final _random = Random();
  final _bubbles = <_Bubble>[];
  Timer? _spawnTimer;
  Timer? _clock;
  int _elapsed = 0;
  int _pops = 0;
  int _nextId = 0;
  bool _finished = false;
  bool _logged = false;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_finished) return;
      setState(() => _elapsed++);
      if (_elapsed >= _sessionSeconds) {
        _finish();
      }
    });
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      if (!_finished) _spawnBubble();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _spawnBubble());
  }

  @override
  void dispose() {
    _clock?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  void _spawnBubble() {
    final size = MediaQuery.sizeOf(context);
    setState(() {
      _bubbles.add(
        _Bubble(
          id: _nextId++,
          position: Offset(
            40 + _random.nextDouble() * (size.width - 80),
            120 + _random.nextDouble() * (size.height - 280),
          ),
          radius: 28 + _random.nextDouble() * 24,
          color: [
            const Color(0xFF7EB8D4),
            const Color(0xFFF2BDC0),
            const Color(0xFFB48EC9),
            const Color(0xFF5BAFA6),
          ][_random.nextInt(4)],
        ),
      );
      if (_bubbles.length > 10) {
        _bubbles.removeAt(0);
      }
    });
  }

  void _pop(_Bubble bubble) {
    setState(() {
      _bubbles.removeWhere((item) => item.id == bubble.id);
      _pops++;
    });
  }

  Future<void> _finish() async {
    if (_finished) return;
    _clock?.cancel();
    _spawnTimer?.cancel();
    setState(() => _finished = true);
    if (_logged) return;
    _logged = true;
    await ref.read(activityRepositoryProvider).logExerciseSession(
          type: 'game',
          title: 'Bubble pop',
          durationSeconds: _elapsed,
          completed: _elapsed >= (_sessionSeconds * 0.8),
        );
    await ref.read(homeViewModelProvider.notifier).refreshStreak();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFEBF5),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () async {
                  await _finish();
                  if (context.mounted) context.pop();
                },
                icon: const Icon(Icons.close),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Text(
                _finished
                    ? 'Nice — $_pops pops'
                    : '${_sessionSeconds - _elapsed}s  •  $_pops',
                style: AppTheme.title16,
              ),
            ),
            if (!_finished)
              ..._bubbles.map(
                (bubble) => Positioned(
                  left: bubble.position.dx - bubble.radius,
                  top: bubble.position.dy - bubble.radius,
                  child: GestureDetector(
                    onTap: () => _pop(bubble),
                    child: Container(
                      width: bubble.radius * 2,
                      height: bubble.radius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bubble.color.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ),
              ),
            if (_finished)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('All done', style: AppTheme.title24),
                    const SizedBox(height: 8),
                    Text('You popped $_pops bubbles', style: AppTheme.body16),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
