import 'package:flutter/material.dart';
import '../data/repository.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork.dart';
import '../widgets/motion.dart';

/// Asmaul Husna: 99 names of Allah.
///
/// Uses a flowing masonry-like two-column grid where each card carries the
/// surah-art palette seeded by the name's index — same visual language as
/// the rest of the app, instead of a flat list.
class AsmaScreen extends StatelessWidget {
  const AsmaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = QuranRepository.instance.asma;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Asmaul Husna',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800, letterSpacing: -0.5,
                      )),
                  const SizedBox(height: 4),
                  Text('99 Nama Allah Yang Maha Mendah.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      )),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 130),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 154,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final a = items[i];
                  final palette = kArtPalettes[(i * 3 + 5) % kArtPalettes.length];
                  return FadeRise(
                    delay: Duration(milliseconds: 18 * i),
                    duration: const Duration(milliseconds: 320),
                    child: PressScale(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [palette.deep, palette.mid],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isDark ? null : Motion.glow(palette.mid, alpha: 0.25, blur: 14, y: 6),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -18,
                              top: -18,
                              child: Opacity(
                                opacity: 0.18,
                                child: Text(a.arabic,
                                    style: TextStyle(
                                      fontSize: 86,
                                      height: 1,
                                      color: Colors.white,
                                      fontFamily: 'AmiriQuran',
                                    )),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                                  ),
                                  child: Text('${a.number}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      )),
                                ),
                                const Spacer(),
                                Text(a.arabic,
                                    style: const TextStyle(
                                      fontFamily: 'AmiriQuran',
                                      fontSize: 28,
                                      height: 1.1,
                                      color: Colors.white,
                                    )),
                                const SizedBox(height: 6),
                                Text(a.transliteration,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: -0.2,
                                    )),
                                if (a.id.isNotEmpty)
                                  Text(a.id,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.75),
                                      )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}