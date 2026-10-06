import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A colour recipe for one generated "cover".
class ArtPalette {
  const ArtPalette(this.deep, this.mid, this.glow, this.accent);
  final Color deep;
  final Color mid;
  final Color glow;
  final Color accent;

  LinearGradient get gradient => LinearGradient(
        colors: [deep, mid, glow],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

/// Curated palettes — each evokes a different illuminated-manuscript mood:
/// emerald, lapis, burgundy, saffron, teal, plum, indigo, copper…
const List<ArtPalette> kArtPalettes = [
  ArtPalette(Color(0xFF062E24), Color(0xFF0E6E5C), Color(0xFF1FA98C), Color(0xFFE8CE86)),
  ArtPalette(Color(0xFF101A3A), Color(0xFF2A3F8F), Color(0xFF5A78D8), Color(0xFFC7D3FF)),
  ArtPalette(Color(0xFF3A0E1C), Color(0xFF8C2140), Color(0xFFC9486A), Color(0xFFFFD3A5)),
  ArtPalette(Color(0xFF3B2A06), Color(0xFF9A6B0E), Color(0xFFD9A227), Color(0xFFFFE9B0)),
  ArtPalette(Color(0xFF062B33), Color(0xFF0E6E7A), Color(0xFF20A6B8), Color(0xFFA9F0F5)),
  ArtPalette(Color(0xFF2A0A38), Color(0xFF6B1F86), Color(0xFFA64FC7), Color(0xFFF0C8FF)),
  ArtPalette(Color(0xFF0B1E45), Color(0xFF1E4A9E), Color(0xFF4C82E0), Color(0xFFBFD6FF)),
  ArtPalette(Color(0xFF3A1A06), Color(0xFF8C4A18), Color(0xFFC97B33), Color(0xFFFFD9A8)),
  ArtPalette(Color(0xFF0A2E1C), Color(0xFF1E7A3C), Color(0xFF3FB768), Color(0xFFC8FFD8)),
  ArtPalette(Color(0xFF241026), Color(0xFF5E2A63), Color(0xFF9B5AA0), Color(0xFFF3D0F0)),
  ArtPalette(Color(0xFF06222E), Color(0xFF13526B), Color(0xFF2E90B5), Color(0xFFB6E9FF)),
  ArtPalette(Color(0xFF2E0A0A), Color(0xFF7A1E1E), Color(0xFFB84545), Color(0xFFFFCFA5)),
];

/// Deterministic palette for a surah (1–114), with juz-based variety so
/// neighbouring surahs never look identical.
ArtPalette paletteFor(int surahNumber, {int? juz}) {
  final seed = surahNumber * 7 + (juz ?? (surahNumber ~/ 5)) * 3;
  return kArtPalettes[seed % kArtPalettes.length];
}

/// Generated artwork for a surah: a rich gradient, a Khatam (eight-point star)
/// lattice, a soft light bloom and a hairline rim. Deterministic, crisp at any
/// size, and completely asset-free.
class SurahArt extends StatelessWidget {
  const SurahArt({
    super.key,
    required this.number,
    this.juz,
    this.radius = 22,
    this.label,
    this.showNumber = true,
    this.bloom = true,
    this.border = true,
  });

  final int number;
  final int? juz;
  final double radius;
  final String? label;
  final bool showNumber;
  final bool bloom;
  final bool border;

  /// The gradient this cover uses — lets screens tint their background to match.
  static LinearGradient gradientFor(int number, {int? juz}) =>
      paletteFor(number, juz: juz).gradient;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFor(number, juz: juz);
    final r = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: r,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: palette.gradient,
          borderRadius: r,
          border: border ? Border.all(color: Colors.white.withValues(alpha: 0.10), width: 1) : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _KhatamPainter(accent: palette.accent, seed: number)),
            if (bloom)
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.55, -0.65),
                    radius: 1.15,
                    colors: [palette.accent.withValues(alpha: 0.30), Colors.transparent],
                  ),
                ),
              ),
            // Darken the lower third so text always stays legible.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.28)],
                ),
              ),
            ),
            if (label != null || showNumber)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (label != null)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label!,
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontFamily: 'AmiriQuran',
                              color: Colors.white,
                              height: 1.4,
                              shadows: [Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 12)],
                            ),
                          ),
                        ),
                      ),
                    if (label != null && showNumber) const SizedBox(height: 6),
                    if (showNumber)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                        ),
                        child: Text(
                          '$number',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                        ),
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

/// Draws the eight-pointed-star lattice (Khatam) that gives each cover its
/// hand-illuminated character.
class _KhatamPainter extends CustomPainter {
  _KhatamPainter({required this.accent, required this.seed});
  final Color accent;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 4.2;
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, size.width * 0.006);

    final offset = (seed % 3) * cell * 0.18;
    for (double y = -cell + offset; y < size.height + cell; y += cell) {
      for (double x = -cell + offset; x < size.width + cell; x += cell) {
        canvas.drawPath(_star8(Offset(x + cell / 2, y + cell / 2), cell * 0.34), paint);
      }
    }

    // A single brighter star anchors the composition.
    final anchor = Paint()
      ..color = accent.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, size.width * 0.008);
    canvas.drawPath(_star8(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.30), anchor);
  }

  /// Eight-pointed star: two squares rotated 45° apart.
  Path _star8(Offset c, double r) {
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

  @override
  bool shouldRepaint(_KhatamPainter old) => old.accent != accent || old.seed != seed;
}

/// Deterministic palette for a radio station, seeded by its name.
///
/// Shared so a station wears the *same* colour in the radio page, the picker
/// sheet, the mini-player and the full player — the colour becomes part of the
/// station's identity rather than an artefact of list position.
ArtPalette radioPalette(String name) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return kArtPalettes[h % kArtPalettes.length];
}

/// The classic Qur'an-app surah marker: an eight-pointed star (Rub el Hizb)
/// framing the surah number.
///
/// Nearly every Qur'an app uses this shape, which is exactly why it reads
/// instantly as "surah list". Here it is tinted with the surah's own palette so
/// the familiar marker still belongs to Noor's visual language.
class SurahStarBadge extends StatelessWidget {
  const SurahStarBadge({
    super.key,
    required this.number,
    this.size = 46,
    this.juz,
    this.solid = false,
  });

  final int number;
  final double size;
  final int? juz;

  /// `true` fills the star with the palette gradient (bolder, used in the
  /// player); `false` draws the tinted outline most lists use.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFor(number, juz: juz);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StarBadgePainter(
          fill: solid ? palette.mid : palette.mid.withValues(alpha: 0.14),
          stroke: solid ? palette.accent.withValues(alpha: 0.6) : palette.accent,
          numberColor: solid ? Colors.white : palette.accent,
          number: number,
          solid: solid,
        ),
      ),
    );
  }
}

class _StarBadgePainter extends CustomPainter {
  _StarBadgePainter({
    required this.fill,
    required this.stroke,
    required this.numberColor,
    required this.number,
    required this.solid,
  });

  final Color fill;
  final Color stroke;
  final Color numberColor;
  final int number;
  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.47;
    final path = _star8(c, r);

    if (solid) {
      // Soft bloom behind the solid star so it reads as a lit marker.
      canvas.drawPath(
        path,
        Paint()
          ..color = stroke.withValues(alpha: 0.30)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.10),
      );
    }
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * (solid ? 0.05 : 0.045)
        ..strokeJoin = StrokeJoin.round,
    );

    // The number sits in the star's heart.
    final tp = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: numberColor,
          fontSize: size.width * 0.30,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  /// Eight-pointed star: two squares rotated 45° apart.
  Path _star8(Offset c, double r) {
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

  @override
  bool shouldRepaint(_StarBadgePainter old) =>
      old.fill != fill || old.stroke != stroke || old.numberColor != numberColor || old.number != number || old.solid != solid;
}
