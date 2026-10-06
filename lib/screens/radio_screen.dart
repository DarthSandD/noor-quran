import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repository.dart';
import '../state/audio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork.dart';
import '../widgets/motion.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final radios = QuranRepository.instance.radios;
    final audio = context.watch<AudioProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentRadio = audio.service.radio;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Hero card.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B5E47), Color(0xFF1DB97E), Color(0xFFD4AF37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isDark ? null : [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.34), blurRadius: 24, offset: const Offset(0, 10))],
                ),
                child: Stack(
                  children: [
                    // Big translucent Arabic letterform as watermark.
                    Positioned(
                      right: -16,
                      top: -10,
                      child: Opacity(
                        opacity: 0.12,
                        child: Text('ر', style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 180, height: 1, color: Colors.white)),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.radio_rounded, color: Colors.white, size: 26),
                            SizedBox(width: 12),
                            Text('Radio Murottal Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text('${radios.length} stasiun streaming 24/7 — tidak perlu unduh',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 12.5, fontWeight: FontWeight.w500)),
                        if (currentRadio != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.18))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFFFF5577), shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(currentRadio.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.5)),
                                ),
                                const SizedBox(width: 8),
                                Text(audio.playing ? 'ON AIR' : 'PAUSED', style: TextStyle(color: Colors.white.withValues(alpha: 0.78), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.4)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Stations list.
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 130),
                itemCount: radios.length,
                itemBuilder: (_, i) {
                  final r = radios[i];
                  final isCurrent = currentRadio?.id == r.id;
                  final palette = radioPalette(r.name);
                  final live = isCurrent && audio.playing;
                  return FadeRise(
                    delay: Duration(milliseconds: 16 * i),
                    duration: const Duration(milliseconds: 320),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PressScale(
                        onTap: () => audio.playRadio(r),
                        child: AnimatedContainer(
                          duration: Motion.med,
                          curve: Motion.curve,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isCurrent ? palette.deep.withValues(alpha: isDark ? 0.45 : 0.10) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(18),
                            border: isCurrent ? Border.all(color: palette.mid.withValues(alpha: 0.55), width: 1.2) : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(colors: [palette.deep, palette.mid], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(live ? Icons.graphic_eq_rounded : Icons.radio_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 13),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, letterSpacing: -0.2)),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (live) ...[
                                              const PulseDot(size: 5, color: Color(0xFFFF3B5C)),
                                              const SizedBox(width: 5),
                                              const Text('LIVE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Color(0xFFFF5577))),
                                            ] else
                                              Text(isCurrent ? 'Terjeda' : 'Live streaming',
                                                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(live ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: isCurrent ? palette.mid : theme.colorScheme.primary, size: 30),
                                ],
                              ),
                              // The ribbon, only on the station actually playing.
                              if (live) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: EqualizerBars(active: true, color: palette.accent, bars: 30, height: 4, barWidth: 2.5),
                                ),
                              ],
                            ],
                          ),
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