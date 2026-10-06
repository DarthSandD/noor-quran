import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../audio/audio_service.dart';
import '../models/models.dart';
import '../state/audio_provider.dart';
import '../widgets/artwork.dart';
import '../widgets/motion.dart';
import '../widgets/reciter_avatar.dart';
import 'player_screen.dart';
import 'reciter_screen.dart';

/// The Murottal library — a Spotify-style browse surface.
///
/// Hierarchy: library → reciter (artist page) → now playing, exactly the shape
/// people already know from music apps, so nothing has to be explained.
class MurottalScreen extends StatefulWidget {
  const MurottalScreen({super.key});

  @override
  State<MurottalScreen> createState() => _MurottalScreenState();
}

class _MurottalScreenState extends State<MurottalScreen> {
  final _search = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = QuranRepository.instance;
    final audio = context.watch<AudioProvider>();
    final theme = Theme.of(context);

    final reciters = repo.reciters.where((r) {
      if (_q.isEmpty) return true;
      return r.name.toLowerCase().contains(_q) || r.letter.toLowerCase() == _q;
    }).toList(growable: false);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PageHeader(
                title: 'Murottal',
                subtitle: '${repo.reciters.length} qari • ${repo.radios.length} radio live',
                trailing: IconButton(
                  icon: const Icon(Icons.radio_rounded),
                  tooltip: 'Radio live',
                  onPressed: () => _openRadio(context),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                  decoration: const InputDecoration(
                    hintText: 'Cari qari…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
              ),
            ),
            // Now playing, when something is loaded.
            if (audio.service.hasQueue)
              SliverToBoxAdapter(
                child: FadeRise(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _NowPlayingCard(audio: audio),
                  ),
                ),
              ),
            // Featured reciters — the horizontal "made for you" rail.
            if (_q.isEmpty) ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Text('Qari pilihan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 150,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: reciters.take(12).length,
                    separatorBuilder: (_, _) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final r = reciters[i];
                      return FadeRise(
                        delay: Duration(milliseconds: 40 * i),
                        child: _FeaturedTile(reciter: r),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: Text('Semua qari', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                ),
              ),
            ],
            SliverList.builder(
              itemCount: reciters.length,
              itemBuilder: (_, i) {
                final r = reciters[i];
                final moshafCount = r.moshafs.length;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReciterScreen(reciterId: r.id)),
                      ),
                      leading: ReciterAvatar(name: r.name, seed: r.id, size: 46, radius: 14),
                      title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                      subtitle: Text(
                        '$moshafCount riwayat • ${r.moshafs.first.surahTotal} surah',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.play_circle_fill_rounded, color: theme.colorScheme.primary, size: 30),
                        tooltip: 'Putar',
                        onPressed: () => _quickPlay(context, r),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  /// Plays the reciter's most complete moshaf from Al-Fatihah.
  static void _quickPlay(BuildContext context, Reciter r) {
    final best = r.moshafs.reduce((a, b) => a.surahTotal >= b.surahTotal ? a : b);
    context.read<AudioProvider>().playAll(reciter: r, moshaf: best);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
  }

  void _openRadio(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _RadioSheet(),
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final AudioProvider audio;
  const _NowPlayingCard({required this.audio});

  @override
  Widget build(BuildContext context) {
    final svc = audio.service;
    final surah = audio.currentSurahObj;
    final isRadio = svc.mode == AudioMode.radio;
    final palette = isRadio ? _radioPalette(svc.title) : paletteFor(surah?.number ?? 1);

    return PressScale(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen())),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [palette.deep, palette.mid], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: palette.mid.withValues(alpha: 0.34), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    if (isRadio)
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
                        ),
                        child: Icon(audio.playing ? Icons.graphic_eq_rounded : Icons.radio_rounded, color: Colors.white, size: 26),
                      )
                    else
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: SurahArt(number: surah?.number ?? 1, radius: 14, showNumber: false),
                      ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(svc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                          const SizedBox(height: 2),
                          Text(svc.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(audio.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
                      onPressed: audio.toggle,
                    ),
                  ],
                ),
              ),
              // Radio gets the LIVE equalizer ribbon; surah/ayah gets a bar.
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
        ),
      ),
    );
  }

  static double _progress(AudioProvider audio) {
    final dur = audio.duration;
    final pos = audio.position;
    if (dur == null || dur.inMilliseconds <= 0) return 0.0;
    return (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
  }
}

/// Deterministic palette for a radio station, seeded by its name.
ArtPalette _radioPalette(String name) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return kArtPalettes[h % kArtPalettes.length];
}

class _FeaturedTile extends StatelessWidget {
  final Reciter reciter;
  const _FeaturedTile({required this.reciter});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReciterScreen(reciterId: reciter.id)),
      ),
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            ReciterAvatar(name: reciter.name, seed: reciter.id, size: 84, radius: 26),
            const SizedBox(height: 8),
            Text(
              reciter.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.25, color: scheme.onSurface.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple radio picker, kept here so the library is self-contained.
class _RadioSheet extends StatelessWidget {
  const _RadioSheet();

  @override
  Widget build(BuildContext context) {
    final radios = QuranRepository.instance.radios;
    final audio = context.watch<AudioProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, controller) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Radio Qur'an", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 40),
              itemCount: radios.length,
              itemBuilder: (_, i) {
                final r = radios[i];
                final isCurrent = audio.service.radio?.id == r.id;
                final palette = _radioPalette(r.name);
                final live = isCurrent && audio.playing;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PressScale(
                    onTap: () => audio.playRadio(r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCurrent ? palette.mid.withValues(alpha: isDark ? 0.30 : 0.10) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18),
                        border: isCurrent ? Border.all(color: palette.mid.withValues(alpha: 0.55), width: 1.2) : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [palette.deep, palette.mid], begin: Alignment.topLeft, end: Alignment.bottomRight),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(live ? Icons.graphic_eq_rounded : Icons.radio_rounded, color: Colors.white, size: 21),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (live) ...[
                                      const PulseDot(size: 5, color: Color(0xFFFF3B5C)),
                                      const SizedBox(width: 5),
                                      const Text('LIVE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, letterSpacing: 1.0, color: Color(0xFFFF5577))),
                                    ] else
                                      Text(isCurrent ? 'Terjeda' : 'Live 24 jam',
                                          style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Icon(isCurrent && audio.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                              color: isCurrent ? palette.mid : theme.colorScheme.primary, size: 30),
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
    );
  }
}
