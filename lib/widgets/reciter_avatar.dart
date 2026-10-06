import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A generated portrait for a reciter.
///
/// There are 242 reciters and no licensed photographs of them, so instead of a
/// flat initial in a square this renders a distinct "artist image": a seeded
/// gradient, a soft light bloom, concentric arcs and the initial. Deterministic
/// per reciter, so a given qari always looks the same — which is what makes the
/// catalogue feel like a real music library rather than a list of names.
class ReciterAvatar extends StatelessWidget {
  const ReciterAvatar({
    super.key,
    required this.name,
    required this.seed,
    this.size = 56,
    this.radius = 16,
    this.showInitial = true,
  });

  final String name;
  final int seed;
  final double size;
  final double radius;
  final bool showInitial;

  /// Two-stop palette derived from the reciter id.
  static (Color, Color, Color) paletteFor(int seed) {
    const pairs = [
      (Color(0xFF0E6E5C), Color(0xFF1FA98C), Color(0xFFE8CE86)),
      (Color(0xFF2A3F8F), Color(0xFF5A78D8), Color(0xFFC7D3FF)),
      (Color(0xFF8C2140), Color(0xFFC9486A), Color(0xFFFFD3A5)),
      (Color(0xFF9A6B0E), Color(0xFFD9A227), Color(0xFFFFE9B0)),
      (Color(0xFF0E6E7A), Color(0xFF20A6B8), Color(0xFFA9F0F5)),
      (Color(0xFF6B1F86), Color(0xFFA64FC7), Color(0xFFF0C8FF)),
      (Color(0xFF1E4A9E), Color(0xFF4C82E0), Color(0xFFBFD6FF)),
      (Color(0xFF8C4A18), Color(0xFFC97B33), Color(0xFFFFD9A8)),
      (Color(0xFF1E7A3C), Color(0xFF3FB768), Color(0xFFC8FFD8)),
      (Color(0xFF5E2A63), Color(0xFF9B5AA0), Color(0xFFF3D0F0)),
      (Color(0xFF13526B), Color(0xFF2E90B5), Color(0xFFB6E9FF)),
      (Color(0xFF7A1E1E), Color(0xFFB84545), Color(0xFFFFCFA5)),
    ];
    return pairs[seed.abs() % pairs.length];
  }

  static String initialOf(String name) {
    final t = name.trim();
    if (t.isEmpty) return '؟';
    return t.split(RegExp(r'\s+')).first.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final (deep, mid, accent) = paletteFor(seed);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [deep, mid], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _ArcsPainter(accent: accent, seed: seed)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.4, -0.5),
                    radius: 1.1,
                    colors: [accent.withValues(alpha: 0.32), Colors.transparent],
                  ),
                ),
              ),
              if (showInitial)
                Center(
                  child: Text(
                    initialOf(name),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.40,
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 10)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArcsPainter extends CustomPainter {
  _ArcsPainter({required this.accent, required this.seed});
  final Color accent;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.72, size.height * 0.78);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.width * 0.03)
      ..color = accent.withValues(alpha: 0.20);

    final rings = 3 + (seed % 2);
    for (var i = 0; i < rings; i++) {
      canvas.drawCircle(c, size.width * (0.22 + i * 0.16), paint);
    }
    // A faint diagonal band adds direction.
    final band = Paint()
      ..color = accent.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.16;
    canvas.drawLine(Offset(-size.width * 0.2, size.height * 1.1), Offset(size.width * 1.1, -size.height * 0.2), band);
  }

  @override
  bool shouldRepaint(_ArcsPainter old) => old.seed != seed || old.accent != accent;
}

/// Large "artist header" artwork for a reciter page.
class ReciterHero extends StatelessWidget {
  const ReciterHero({super.key, required this.name, required this.seed, this.size = 132});
  final String name;
  final int seed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (deep, mid, _) = ReciterAvatar.paletteFor(seed);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: mid.withValues(alpha: 0.45), blurRadius: 34, offset: const Offset(0, 16)),
          const BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: ReciterAvatar(name: name, seed: seed, size: size, radius: size / 2),
    );
  }
}
