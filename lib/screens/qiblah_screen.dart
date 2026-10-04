import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../state/qiblah_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';

class QiblahScreen extends StatelessWidget {
  const QiblahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = context.watch<QiblahProvider>();
    final theme = Theme.of(context);
    final hasLocation = q.position != null;
    final bearing = q.qiblahBearing;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 130),
        children: [
          const PageHeader(title: 'Kiblat', subtitle: 'Arah kiblat & waktu shalat'),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: 290,
              height: 290,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Compass dial: north ('U') rotates to stay on true north.
                  AnimatedRotation(
                    turns: q.heading != null ? -q.heading! / 360 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: CustomPaint(
                      size: const Size(290, 290),
                      painter: _CompassPainter(
                        primary: theme.colorScheme.primary,
                        onSurface: theme.colorScheme.onSurface,
                        aligned: q.isAligned,
                      ),
                    ),
                  ),
                  // Qiblah needle: points at the Ka'bah on screen.
                  AnimatedRotation(
                    turns: (bearing != null && q.heading != null) ? (bearing - q.heading!) / 360 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: SizedBox(
                      width: 290,
                      height: 290,
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.navigation_rounded, color: q.isAligned ? AppColors.gold : theme.colorScheme.primary, size: 40),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: q.isAligned ? AppColors.gold : theme.colorScheme.primary, shape: BoxShape.circle),
                                child: const Text('🕋', style: TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Center readout
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 20)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(bearing != null ? '${bearing.toStringAsFixed(0)}°' : '--°', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -1)),
                        const Text('dari Utara', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(q.heading != null ? 'HP: ${q.heading!.toStringAsFixed(0)}°' : 'Kompa: -', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: q.isAligned ? AppColors.gold.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(q.isAligned ? Icons.check_circle_rounded : Icons.rotate_right_rounded, size: 18, color: q.isAligned ? AppColors.gold : theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(q.isAligned ? 'Tepat menghadap kiblat' : 'Putar perangkat perlahan', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.location_on_rounded, color: theme.colorScheme.primary),
                title: Text(q.locationLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: hasLocation
                    ? Text('Jarak ke Ka\'bah ≈ ${q.qiblahDistanceKm.toStringAsFixed(0)} km', style: const TextStyle(fontSize: 12))
                    : const Text('Ketuk untuk mengaktifkan lokasi', style: TextStyle(fontSize: 12)),
                trailing: q.loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(icon: const Icon(Icons.my_location_rounded), onPressed: () => q.refreshLocation()),
              ),
            ),
          ),
          if (q.error != null) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [const Icon(Icons.info_outline_rounded, size: 18, color: Colors.orange), const SizedBox(width: 8), Expanded(child: Text(q.error!, style: TextStyle(fontSize: 12)))]),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Waktu Shalat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                const Spacer(),
                DropdownButton<String>(
                  value: q.method,
                  underline: const SizedBox.shrink(),
                  style: TextStyle(fontSize: 12.5, color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                  items: const [
                    DropdownMenuItem(value: 'kemenag', child: Text('Kemenag (SG)')),
                    DropdownMenuItem(value: 'mwl', child: Text('Muslim World League')),
                    DropdownMenuItem(value: 'makkah', child: Text('Umm al-Qura')),
                    DropdownMenuItem(value: 'egypt', child: Text('Egyptian')),
                    DropdownMenuItem(value: 'karachi', child: Text('Karachi')),
                    DropdownMenuItem(value: 'isna', child: Text('ISNA')),
                  ],
                  onChanged: (v) => v != null ? q.setMethod(v) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: q.prayers.isEmpty
                ? Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(child: Text('Atur lokasi untuk menampilkan waktu shalat', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))),
                    ),
                  )
                : Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final p in q.prayers)
                          _PrayerRow(
                            entry: p,
                            isNext: q.next?.name == p.name,
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final PrayerEntry entry;
  final bool isNext;
  const _PrayerRow({required this.entry, required this.isNext});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: isNext ? theme.colorScheme.primary.withValues(alpha: 0.10) : null,
      child: ListTile(
        leading: Icon(
          switch (entry.name) {
            'Subuh' => Icons.nights_stay_rounded,
            'Terbit' => Icons.wb_twilight_rounded,
            'Dzuhur' => Icons.wb_sunny_rounded,
            'Ashar' => Icons.sunny_snowing,
            'Maghrib' => Icons.wb_twilight_rounded,
            _ => Icons.nightlight_round,
          },
          color: isNext ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        title: Text(entry.name, style: TextStyle(fontWeight: isNext ? FontWeight.w800 : FontWeight.w600, fontSize: 14.5)),
        trailing: Text(DateFormat.Hm().format(entry.time), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isNext ? theme.colorScheme.primary : null)),
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final Color primary;
  final Color onSurface;
  final bool aligned;
  _CompassPainter({required this.primary, required this.onSurface, required this.aligned});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = primary.withValues(alpha: 0.35);
    canvas.drawCircle(c, r - 4, ring);
    canvas.drawCircle(c, r - 22, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = onSurface.withValues(alpha: 0.1));

    for (int i = 0; i < 72; i++) {
      final angle = i * 5 * math.pi / 180;
      final isMajor = i % 9 == 0;
      final len = isMajor ? 14.0 : (i % 3 == 0 ? 8.0 : 4.0);
      final p1 = c + Offset(math.sin(angle), -math.cos(angle)) * (r - 8);
      final p2 = c + Offset(math.sin(angle), -math.cos(angle)) * (r - 8 - len);
      canvas.drawLine(p1, p2, Paint()..strokeWidth = isMajor ? 2.5 : 1.2..color = onSurface.withValues(alpha: isMajor ? 0.7 : 0.3));
    }

    void label(String t, double deg, Color col, double fs) {
      final tp = TextPainter(text: TextSpan(text: t, style: TextStyle(color: col, fontSize: fs, fontWeight: FontWeight.w800)), textDirection: ui.TextDirection.ltr)..layout();
      final angle = deg * math.pi / 180;
      final off = c + Offset(math.sin(angle), -math.cos(angle)) * (r - 44);
      tp.paint(canvas, off - Offset(tp.width / 2, tp.height / 2));
    }

    label('U', 0, aligned ? AppColors.gold : onSurface.withValues(alpha: 0.85), 15);
    label('S', 180, onSurface.withValues(alpha: 0.55), 13);
    label('T', 90, onSurface.withValues(alpha: 0.55), 13);
    label('B', 270, onSurface.withValues(alpha: 0.55), 13);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter old) => old.aligned != aligned || old.primary != primary;
}
