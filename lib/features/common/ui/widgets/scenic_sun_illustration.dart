import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom vector painter creating the scenic hill & smiling sun artwork
/// shown in the reference design.
class ScenicSunIllustration extends StatelessWidget {
  final double height;
  final double? width;
  final bool showHills;
  final bool compactSun;

  const ScenicSunIllustration({
    super.key,
    this.height = 160,
    this.width,
    this.showHills = true,
    this.compactSun = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          size: Size(width ?? double.infinity, height),
          painter: _ScenicPainter(showHills: showHills, compactSun: compactSun),
        ),
      ),
    );
  }
}

class _ScenicPainter extends CustomPainter {
  final bool showHills;
  final bool compactSun;

  _ScenicPainter({required this.showHills, required this.compactSun});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Sky Gradient Background
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFEA9F), Color(0xFFFFD464)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // 2. Birds in flight
    _drawBirds(canvas, w, h);

    // 3. Smiling Sun
    if (compactSun) {
      _drawSmilingSun(canvas, Offset(w * 0.5, h * 0.5), radius: h * 0.32);
    } else {
      _drawSmilingSun(
        canvas,
        Offset(w * 0.72, h * 0.42),
        radius: math.min(w, h) * 0.22,
      );
    }

    // 4. Rolling Hills & Pine Trees
    if (showHills) {
      _drawHillsAndTrees(canvas, w, h);
    }
  }

  void _drawBirds(Canvas canvas, double w, double h) {
    final birdPaint = Paint()
      ..color = const Color(0xFF6B5829).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final birdPositions = [
      Offset(w * 0.28, h * 0.32),
      Offset(w * 0.38, h * 0.26),
      Offset(w * 0.46, h * 0.38),
      Offset(w * 0.22, h * 0.45),
    ];

    for (final pos in birdPositions) {
      final path = Path();
      const span = 6.0;
      path.moveTo(pos.dx - span, pos.dy + 2);
      path.quadraticBezierTo(pos.dx - span * 0.5, pos.dy - 3, pos.dx, pos.dy);
      path.quadraticBezierTo(
        pos.dx + span * 0.5,
        pos.dy - 3,
        pos.dx + span,
        pos.dy + 2,
      );
      canvas.drawPath(path, birdPaint);
    }
  }

  void _drawSmilingSun(Canvas canvas, Offset center, {required double radius}) {
    final rayCount = 12;
    final rayLength = radius * 0.28;

    // Rays
    final rayPaint = Paint()
      ..color = const Color(0xFFFFB834)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < rayCount; i++) {
      final angle = (i * 2 * math.pi) / rayCount;
      final x1 = center.dx + math.cos(angle) * (radius + rayLength);
      final y1 = center.dy + math.sin(angle) * (radius + rayLength);

      final p1 = Offset(
        center.dx + math.cos(angle - 0.12) * radius,
        center.dy + math.sin(angle - 0.12) * radius,
      );
      final p2 = Offset(
        center.dx + math.cos(angle + 0.12) * radius,
        center.dy + math.sin(angle + 0.12) * radius,
      );

      final rayPath = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(x1, y1)
        ..lineTo(p2.dx, p2.dy)
        ..close();
      canvas.drawPath(rayPath, rayPaint);
    }

    // Sun Body
    final sunPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFC947), Color(0xFFFFAE19)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sunPaint);

    // Cute Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF6F59).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx - radius * 0.42, center.dy + radius * 0.18),
      radius * 0.14,
      cheekPaint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.42, center.dy + radius * 0.18),
      radius * 0.14,
      cheekPaint,
    );

    // Eyes (Happy curves or shiny dots)
    final eyePaint = Paint()
      ..color = const Color(0xFF332008)
      ..style = PaintingStyle.fill;

    final leftEye = Offset(
      center.dx - radius * 0.28,
      center.dy - radius * 0.05,
    );
    final rightEye = Offset(
      center.dx + radius * 0.28,
      center.dy - radius * 0.05,
    );

    canvas.drawCircle(leftEye, radius * 0.10, eyePaint);
    canvas.drawCircle(rightEye, radius * 0.10, eyePaint);

    // Eye catchlights (white dots)
    final catchPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(leftEye.dx - radius * 0.03, leftEye.dy - radius * 0.03),
      radius * 0.035,
      catchPaint,
    );
    canvas.drawCircle(
      Offset(rightEye.dx - radius * 0.03, rightEye.dy - radius * 0.03),
      radius * 0.035,
      catchPaint,
    );

    // Happy Smile
    final smilePaint = Paint()
      ..color = const Color(0xFF332008)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;

    final smileRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.12),
      width: radius * 0.38,
      height: radius * 0.32,
    );
    canvas.drawArc(smileRect, 0.15 * math.pi, 0.7 * math.pi, false, smilePaint);
  }

  void _drawHillsAndTrees(Canvas canvas, double w, double h) {
    // 1. Back Hill (Soft Yellow-Green)
    final backHillPaint = Paint()
      ..color = const Color(0xFF90C259)
      ..style = PaintingStyle.fill;

    final backHillPath = Path()
      ..moveTo(0, h * 0.76)
      ..quadraticBezierTo(w * 0.35, h * 0.58, w * 0.75, h * 0.72)
      ..quadraticBezierTo(w * 0.90, h * 0.76, w, h * 0.70)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(backHillPath, backHillPaint);

    // Trees on Back Hill
    _drawTree(canvas, Offset(w * 0.12, h * 0.64), 26, const Color(0xFF4C7B2F));
    _drawTree(canvas, Offset(w * 0.18, h * 0.60), 34, const Color(0xFF3D6623));
    _drawTree(canvas, Offset(w * 0.24, h * 0.66), 24, const Color(0xFF4C7B2F));

    // Right side distant trees
    _drawTree(canvas, Offset(w * 0.88, h * 0.66), 22, const Color(0xFF4C7B2F));
    _drawTree(canvas, Offset(w * 0.93, h * 0.64), 28, const Color(0xFF3D6623));

    // 2. Foreground Hill (Vibrant Lawn Green)
    final frontHillPaint = Paint()
      ..color = const Color(0xFF6C9E37)
      ..style = PaintingStyle.fill;

    final frontHillPath = Path()
      ..moveTo(0, h * 0.86)
      ..quadraticBezierTo(w * 0.25, h * 0.82, w * 0.55, h * 0.90)
      ..quadraticBezierTo(w * 0.80, h * 0.96, w, h * 0.84)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(frontHillPath, frontHillPaint);

    // Trees on Foreground Hill
    _drawTree(canvas, Offset(w * 0.06, h * 0.76), 36, const Color(0xFF2E5318));
    _drawTree(canvas, Offset(w * 0.14, h * 0.80), 28, const Color(0xFF37611E));
  }

  void _drawTree(
    Canvas canvas,
    Offset bottomCenter,
    double height,
    Color color,
  ) {
    final treePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final width = height * 0.48;
    final path = Path()
      ..moveTo(bottomCenter.dx, bottomCenter.dy - height)
      ..lineTo(bottomCenter.dx + width * 0.5, bottomCenter.dy)
      ..lineTo(bottomCenter.dx - width * 0.5, bottomCenter.dy)
      ..close();

    canvas.drawPath(path, treePaint);
  }

  @override
  bool shouldRepaint(covariant _ScenicPainter oldDelegate) =>
      oldDelegate.showHills != showHills ||
      oldDelegate.compactSun != compactSun;
}
