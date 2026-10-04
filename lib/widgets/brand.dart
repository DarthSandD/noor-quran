import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The Noor emblem — a gold eight-pointed star ring cradling a crescent and
/// star — drawn with a CustomPainter so it stays crisp at any size and can be
/// animated (used on the splash screen and in headers).
class NoorMark extends StatelessWidget {
  const NoorMark({super.key, this.size = 72, this.color, this.glow = true, this.progress = 1.0});

  final double size;
  final Color? color;
  final bool glow;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NoorMarkPainter(color: color ?? AppColors.goldSoft, glow: glow, progress: progress),
      ),
    );
  }
}

class _NoorMarkPainter extends CustomPainter {
  _NoorMarkPainter({required this.color, required this.glow, required this.progress});

  final Color color;
  final bool glow;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;
    final stroke = size.width * 0.052;

    if (glow) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 2.4
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.045);
      canvas.drawPath(_octagram(c, r), glowPaint);
    }

    final ringPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_octagram(c, r), ringPaint);

    // Crescent: circle minus an offset circle.
    final cr = r * 0.55;
    final off = size.width * 0.075;
    final outer = Path()..addOval(Rect.fromCircle(center: c, radius: cr));
    final hole = Path()..addOval(Rect.fromCircle(center: c.translate(off, 0), radius: cr));
    final crescent = Path.combine(PathOperation.difference, outer, hole);

    final fill = Paint()..color = color..isAntiAlias = true;
    canvas.drawPath(crescent, fill);

    // Small star in the crescent's opening.
    final starC = c.translate(size.width * 0.115, -size.height * 0.02);
    canvas.drawPath(_star(starC, size.width * 0.062, 5), fill);
  }

  Path _octagram(Offset c, double r) {
    final path = Path();
    for (final rot in [0.0, math.pi / 4]) {
      final pts = List.generate(4, (i) {
        final a = rot + i * math.pi / 2;
        return c.translate(r * math.cos(a), r * math.sin(a));
      });
      path.addPolygon(pts, true);
    }
    return path;
  }

  Path _star(Offset c, double r, int points) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final rad = i.isEven ? r : r * 0.42;
      final a = -math.pi / 2 + i * math.pi / points;
      final p = c.translate(rad * math.cos(a), rad * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_NoorMarkPainter old) => old.color != color || old.progress != progress || old.glow != glow;
}
