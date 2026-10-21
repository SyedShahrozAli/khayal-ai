import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../theme/app_theme.dart';
import '../../../activity/repository/activity_repository.dart';
import '../../../common/ui/widgets/scenic_sun_illustration.dart';
import '../../../main/ui/view_model/home_view_model.dart';

class BubblePopGame extends ConsumerStatefulWidget {
  const BubblePopGame({super.key});

  @override
  ConsumerState<BubblePopGame> createState() => _BubblePopGameState();
}

class _Bubble {
  final int id;
  double x;
  double y;
  final double radius;
  final Color baseColor;
  final double speedY;
  final double wobbleSpeed;
  final double wobbleAmp;
  double wobblePhase;

  _Bubble({
    required this.id,
    required this.x,
    required this.y,
    required this.radius,
    required this.baseColor,
    required this.speedY,
    required this.wobbleSpeed,
    required this.wobbleAmp,
    required this.wobblePhase,
  });
}

class _Particle {
  final Offset origin;
  final Offset velocity;
  final Color color;
  final double size;
  double progress; // 0.0 to 1.0

  _Particle({
    required this.origin,
    required this.velocity,
    required this.color,
    required this.size,
    this.progress = 0.0,
  });
}

class _FloatingText {
  final Offset position;
  final String text;
  double progress; // 0.0 to 1.0

  _FloatingText({
    required this.position,
    required this.text,
    this.progress = 0.0,
  });
}

class _BubblePopGameState extends ConsumerState<BubblePopGame>
    with SingleTickerProviderStateMixin {
  static const _sessionSeconds = 60;
  final _random = math.Random();

  late final AnimationController _animController;
  final List<_Bubble> _bubbles = [];
  final List<_Particle> _particles = [];
  final List<_FloatingText> _floatingTexts = [];

  Timer? _spawnTimer;
  Timer? _clockTimer;
  int _elapsed = 0;
  int _pops = 0;
  int _nextId = 0;
  bool _finished = false;
  bool _logged = false;

  // Cheerful pastel color palette matching the design system
  static const _bubbleColors = [
    Color(0xFF7BC6FF), // Soft Sky Blue
    Color(0xFFFFA085), // Soft Peach
    Color(0xFFB5A2F8), // Soft Lavender
    Color(0xFF86CA90), // Soft Mint
    Color(0xFFFFCF53), // Soft Honey Amber
    Color(0xFFEF798A), // Soft Coral Rose
    Color(0xFFDE6B48), // Warm Terracotta
    Color(0xFF90A959), // Avocado Olive
  ];

  @override
  void initState() {
    super.initState();

    // 60fps Game Loop Controller without widget tree rebuilds
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_gameLoop);
    _animController.repeat();

    // 1-Second Countdown Timer
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_finished) return;
      setState(() => _elapsed++);
      if (_elapsed >= _sessionSeconds) {
        _finish();
      }
    });

    // Bubble spawn loop
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_finished && mounted) {
        _spawnBubble();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Initial set of bubbles spread across screen
        for (int i = 0; i < 7; i++) {
          _spawnBubble(initialRandomY: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _spawnTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _gameLoop() {
    if (_finished || !mounted) return;

    final size = MediaQuery.sizeOf(context);
    if (size.width == 0 || size.height == 0) return;

    // 1. Update bubbles position
    for (final b in _bubbles) {
      b.y -= b.speedY;
      b.wobblePhase += b.wobbleSpeed;
      b.x += math.sin(b.wobblePhase) * b.wobbleAmp;

      // Keep within bounds
      if (b.x < b.radius) b.x = b.radius;
      if (b.x > size.width - b.radius) b.x = size.width - b.radius;
    }

    // Remove bubbles that float past the top screen
    _bubbles.removeWhere((b) => b.y < -b.radius * 2);

    // If screen has fewer than 5 bubbles, spawn one immediately
    if (_bubbles.length < 5) {
      _spawnBubble();
    }

    // 2. Update burst particles
    for (final p in _particles) {
      p.progress += 0.05;
    }
    _particles.removeWhere((p) => p.progress >= 1.0);

    // 3. Update floating "+1" texts
    for (final ft in _floatingTexts) {
      ft.progress += 0.035;
    }
    _floatingTexts.removeWhere((ft) => ft.progress >= 1.0);
  }

  void _spawnBubble({bool initialRandomY = false}) {
    final size = MediaQuery.sizeOf(context);
    if (size.width == 0 || size.height == 0) return;

    final radius = 32.0 + _random.nextDouble() * 26.0;
    final startY = initialRandomY
        ? 140.0 + _random.nextDouble() * (size.height - 240.0)
        : size.height + radius + _random.nextDouble() * 40.0;
    final startX = radius + _random.nextDouble() * (size.width - radius * 2);

    final bubble = _Bubble(
      id: _nextId++,
      x: startX,
      y: startY,
      radius: radius,
      baseColor: _bubbleColors[_random.nextInt(_bubbleColors.length)],
      speedY: 1.2 + _random.nextDouble() * 1.6,
      wobbleSpeed: 0.04 + _random.nextDouble() * 0.04,
      wobbleAmp: 0.8 + _random.nextDouble() * 0.8,
      wobblePhase: _random.nextDouble() * math.pi * 2,
    );

    _bubbles.add(bubble);
    if (_bubbles.length > 15) {
      _bubbles.removeAt(0);
    }
  }

  /// Instantaneous single-touch hit detection (pops strictly the topmost bubble)
  void _handleTouch(Offset touch) {
    if (_finished) return;

    // Do not pop if touching within top app bar area
    if (touch.dy < 72) return;

    _Bubble? candidate;

    // 1. First pass: Find the topmost bubble that directly contains the touch point (dist <= radius)
    // Checking in reverse order prioritizes the visually topmost bubble (drawn last)
    for (int i = _bubbles.length - 1; i >= 0; i--) {
      final b = _bubbles[i];
      final dx = b.x - touch.dx;
      final dy = b.y - touch.dy;
      final distSq = dx * dx + dy * dy;

      if (distSq <= b.radius * b.radius) {
        candidate = b;
        break; // Topmost bubble found
      }
    }

    // 2. Second pass: If user tapped slightly outside the visual rim, apply a small 6px grace margin
    if (candidate == null) {
      for (int i = _bubbles.length - 1; i >= 0; i--) {
        final b = _bubbles[i];
        final dx = b.x - touch.dx;
        final dy = b.y - touch.dy;
        final distSq = dx * dx + dy * dy;
        final graceRadius = b.radius + 6.0;

        if (distSq <= graceRadius * graceRadius) {
          candidate = b;
          break;
        }
      }
    }

    // Pop strictly ONE bubble per touch. The bubble underneath requires the next touch.
    if (candidate != null) {
      _pop(candidate);
    }
  }

  void _pop(_Bubble bubble) {
    // Immediate tactile feedback
    HapticFeedback.mediumImpact();

    // Spawn 14 radiating explosion particles
    const particleCount = 14;
    for (int i = 0; i < particleCount; i++) {
      final angle = (i * 2 * math.pi) / particleCount + _random.nextDouble() * 0.35;
      final speed = 3.0 + _random.nextDouble() * 4.5;
      final vx = math.cos(angle) * speed;
      final vy = math.sin(angle) * speed;

      _particles.add(
        _Particle(
          origin: Offset(bubble.x, bubble.y),
          velocity: Offset(vx, vy),
          color: bubble.baseColor,
          size: 4.5 + _random.nextDouble() * 4.0,
        ),
      );
    }

    // Spawn floating "+1" pop indicator
    _floatingTexts.add(
      _FloatingText(
        position: Offset(bubble.x, bubble.y - 10),
        text: '+1',
      ),
    );

    _bubbles.removeWhere((item) => item.id == bubble.id);
    _pops++;

    // Rebuild only for the score counter in header
    setState(() {});
  }

  Future<void> _finish() async {
    if (_finished) return;
    _clockTimer?.cancel();
    _spawnTimer?.cancel();
    setState(() => _finished = true);

    if (_logged) return;
    _logged = true;

    await ref.read(activityRepositoryProvider).logExerciseSession(
          type: 'game',
          title: 'Bubble pop',
          durationSeconds: _elapsed,
          completed: _elapsed >= (_sessionSeconds * 0.6),
        );
    await ref.read(homeViewModelProvider.notifier).refreshStreak();
  }

  @override
  Widget build(BuildContext context) {
    final remainingSeconds = math.max(0, _sessionSeconds - _elapsed);
    final progress = _elapsed / _sessionSeconds;

    return Scaffold(
      backgroundColor: const Color(0xFFF3EFE8),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background Ambient Clouds ───────────────────────────────────
            Positioned(
              top: -40,
              right: -30,
              child: IgnorePointer(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFDE8DF).withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: -50,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE2F0FB).withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),

            // ── Fullscreen Interactive Game Canvas (Zero Latency Listener) ──
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (event) => _handleTouch(event.localPosition),
                child: CustomPaint(
                  painter: _GameCanvasPainter(
                    bubbles: _bubbles,
                    particles: _particles,
                    floatingTexts: _floatingTexts,
                    repaint: _animController,
                  ),
                ),
              ),
            ),

            // ── Top Header Control Bar ──────────────────────────────────────
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () async {
                      await _finish();
                      if (context.mounted) context.pop();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF2E1C00),
                        size: 20,
                      ),
                    ),
                  ),

                  // Timer & Pop Count Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circular time progress
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            value: 1.0 - progress,
                            strokeWidth: 2.5,
                            backgroundColor: const Color(0xFFEDE6DA),
                            color: const Color(0xFFF7A81B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${remainingSeconds}s',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E1C00),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 1,
                          height: 16,
                          color: const Color(0xFFDDD2C2),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.bubble_chart_rounded,
                          size: 16,
                          color: Color(0xFFDE6B48),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_pops',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFDE6B48),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Celebration Completion Modal ────────────────────────────────
            if (_finished)
              Container(
                color: Colors.black.withValues(alpha: 0.45),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 340),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 90,
                        height: 90,
                        child: ScenicSunIllustration(
                          height: 90,
                          compactSun: true,
                          showHills: true,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Sensory Reset Complete ✨',
                        style: AppTheme.title20.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF221400),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You popped $_pops mindful bubbles.\nTake a long, deep breath and step forward with gentle calm.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B584E),
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF7A81B),
                            foregroundColor: const Color(0xFF221400),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'Continue Day',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Unified High-Performance Canvas Painter (Bubbles, Radial Particle Explosions, Floating +1)
class _GameCanvasPainter extends CustomPainter {
  final List<_Bubble> bubbles;
  final List<_Particle> particles;
  final List<_FloatingText> floatingTexts;

  _GameCanvasPainter({
    required this.bubbles,
    required this.particles,
    required this.floatingTexts,
    required AnimationController repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw All Bubbles
    for (final b in bubbles) {
      _paintBubble(canvas, b);
    }

    // 2. Draw Burst Particles
    for (final p in particles) {
      final double remainingLife = (1.0 - p.progress).clamp(0.0, 1.0);
      final int alpha = (remainingLife * 255).toInt();
      final particlePaint = Paint()
        ..color = p.color.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      // Expand outward with deceleration
      final currentPos = Offset(
        p.origin.dx + p.velocity.dx * p.progress * 16.0,
        p.origin.dy + p.velocity.dy * p.progress * 16.0,
      );

      canvas.drawCircle(currentPos, p.size * remainingLife, particlePaint);
    }

    // 3. Draw Floating "+1" Indicators
    for (final ft in floatingTexts) {
      final double remainingLife = (1.0 - ft.progress).clamp(0.0, 1.0);
      final int alpha = (remainingLife * 255).toInt();
      final textSpan = TextSpan(
        text: ft.text,
        style: TextStyle(
          color: const Color(0xFFDE6B48).withAlpha(alpha),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Rise upward smoothly
      final dyOffset = ft.progress * 30.0;
      textPainter.paint(
        canvas,
        Offset(
          ft.position.dx - textPainter.width * 0.5,
          ft.position.dy - dyOffset,
        ),
      );
    }
  }

  void _paintBubble(Canvas canvas, _Bubble b) {
    final center = Offset(b.x, b.y);
    final radius = b.radius;

    // Translucent spherical gradient body
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          b.baseColor.withValues(alpha: 0.18),
          b.baseColor.withValues(alpha: 0.50),
          b.baseColor.withValues(alpha: 0.85),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bodyPaint);

    // Rim glow
    final rimPaint = Paint()
      ..color = b.baseColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius - 1, rimPaint);

    // Specular crescent light reflection (upper-left)
    final shinePath = Path();
    final shineRect = Rect.fromCircle(
      center: Offset(center.dx - radius * 0.16, center.dy - radius * 0.16),
      radius: radius * 0.68,
    );
    shinePath.addArc(shineRect, -math.pi * 0.78, math.pi * 0.48);

    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.18
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(shinePath, shinePaint);

    // Secondary tiny highlight dot (lower-right reflection)
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx + radius * 0.44, center.dy + radius * 0.44),
      radius * 0.08,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GameCanvasPainter oldDelegate) => true;
}
