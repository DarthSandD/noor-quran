import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_service.dart';
import '../state/audio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork.dart';
import '../widgets/motion.dart';
import '../screens/player_screen.dart';

/// Compact now-playing bar that floats above the navigation bar.
///
/// Shows the current item's cover art, live progress and a working
/// play/pause + skip, so playback is controllable without opening the player.
///
/// It has two faces: a **surah/ayah** face with a progress bar, and a **radio**
/// face with a pulsing LIVE ribbon and an animated equalizer (a live stream has
/// no end, so a progress bar there would be a lie).
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
    final isRadio = svc.mode == AudioMode.radio;

    // A live radio stream has no duration, so the palette is picked from the
    // station name instead of a surah number.
    final surahNumber = audio.currentSurahObj?.number ?? 1;
    final palette = isRadio ? _radioPalette(svc.title) : paletteFor(surahNumber);

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
                // Faint artwork wash so the bar belongs to the current item.
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
                          _leading(isRadio: isRadio, surahNumber: surahNumber, palette: palette, playing: audio.playing),
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
                          if (isRadio)
                            // Live streams have nothing to skip to.
                            const _LivePill()
                          else
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24),
                              onPressed: audio.hasNext ? audio.next : null,
                              tooltip: 'Berikutnya',
                            ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
                            onPressed: audio.toggle,
                            tooltip: audio.playing ? 'Jeda' : 'Putar',
                          ),
                        ],
                      ),
                    ),
                    // The ribbon: an equalizer for radio, a progress bar for
                    // surah/ayah playback.
                    if (isRadio)
                      EqualizerBars(active: audio.playing, color: palette.accent)
                    else
                      LinearProgressIndicator(
                        value: _progress(audio),
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

  double _progress(AudioProvider audio) {
    final dur = audio.duration;
    final pos = audio.position;
    if (dur == null || dur.inMilliseconds <= 0) return 0.0;
    return (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
  }

  Widget _leading({required bool isRadio, required int surahNumber, required ArtPalette palette, required bool playing}) {
    if (isRadio) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [palette.mid, palette.deep], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(playing ? Icons.graphic_eq_rounded : Icons.radio_rounded, color: Colors.white, size: 22),
      );
    }
    return SizedBox(
      width: 44,
      height: 44,
      child: SurahArt(number: surahNumber, radius: 13, showNumber: false),
    );
  }

  /// Deterministic palette for a radio station, seeded by its name so a given
  /// station always wears the same colour.
  static ArtPalette _radioPalette(String name) {
    var h = 0;
    for (final c in name.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return kArtPalettes[h % kArtPalettes.length];
  }
}

/// The little "LIVE" pill shown while a station streams.
class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3B5C).withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF3B5C).withValues(alpha: 0.55)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseDot(size: 6, color: Color(0xFFFF3B5C)),
          SizedBox(width: 5),
          Text('LIVE', style: TextStyle(color: Color(0xFFFF6B85), fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
        ],
      ),
    );
  }
}
