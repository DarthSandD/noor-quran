import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/audio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork.dart';
import '../widgets/motion.dart';
import '../screens/player_screen.dart';

/// Compact now-playing bar that floats above the navigation bar.
///
/// Shows the current surah's cover art, live progress and a working
/// play/pause + skip, so playback is controllable without opening the player.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final visible = audio.service.title.isNotEmpty;

    return AnimatedSlide(
      duration: Motion.med,
      curve: Motion.curve,
      offset: visible ? Offset.zero : const Offset(0, 1.4),
      child: AnimatedOpacity(
        duration: Motion.med,
        opacity: visible ? 1 : 0,
        child: visible ? _bar(context, audio) : const SizedBox(height: 0),
      ),
    );
  }

  Widget _bar(BuildContext context, AudioProvider audio) {
    final svc = audio.service;
    final dur = audio.duration;
    final pos = audio.position;
    final progress = (dur != null && dur.inMilliseconds > 0)
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    final surahNumber = audio.currentSurahObj?.number ?? 1;
    final palette = paletteFor(surahNumber);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: PressScale(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen())),
        child: Container(
          decoration: BoxDecoration(
            color: palette.deep,
            borderRadius: BorderRadius.circular(20),
            boxShadow: Motion.glow(palette.mid, alpha: 0.45, blur: 22, y: 8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Faint artwork wash so the bar belongs to the current surah.
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [palette.mid.withValues(alpha: 0.95), palette.deep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            height: 44,
                            child: SurahArt(number: surahNumber, radius: 13, showNumber: false),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(svc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5, letterSpacing: -0.1)),
                                const SizedBox(height: 2),
                                Text(svc.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
                            onPressed: audio.toggle,
                            tooltip: audio.playing ? 'Jeda' : 'Putar',
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24),
                            onPressed: audio.hasNext ? audio.next : null,
                            tooltip: 'Berikutnya',
                          ),
                        ],
                      ),
                    ),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 2.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      valueColor: AlwaysStoppedAnimation(palette.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
