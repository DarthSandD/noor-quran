import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/models.dart';
import '../state/audio_provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork.dart';
import '../widgets/motion.dart';
import '../widgets/reciter_avatar.dart';
import 'player_screen.dart';

/// A reciter's page — the "artist" view.
///
/// Shows every moshaf (riwayah) the reciter has, a **Putar Semua** action, and
/// the full surah list. Tapping a surah starts playback there and continues
/// through the rest of the queue, exactly like starting an album mid-track.
class ReciterScreen extends StatelessWidget {
  final int reciterId;
  const ReciterScreen({super.key, required this.reciterId});

  Reciter get _reciter => QuranRepository.instance.reciters.firstWhere(
        (r) => r.id == reciterId,
        orElse: () => QuranRepository.instance.reciters.first,
      );

  @override
  Widget build(BuildContext context) {
    final r = _reciter;
    final audio = context.watch<AudioProvider>();
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    // The moshaf the user last used for this reciter, else the most complete.
    final preferred = r.moshafs.reduce((a, b) => a.surahTotal >= b.surahTotal ? a : b);
    final selected = r.moshafs.firstWhere(
      (m) => m.id == settings.moshafId,
      orElse: () => preferred,
    );

    final surahs = QuranRepository.instance.surahs
        .where((s) => selected.hasSurah(s.number))
        .toList(growable: false);

    final isThisReciter = audio.service.reciter?.id == r.id;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 240,
            backgroundColor: theme.scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: Grad.emerald),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        ReciterHero(name: r.name, seed: r.id, size: 116),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Text(
                            r.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${r.moshafs.length} riwayat • ${surahs.length} surah',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Actions.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        settings.setReciter(r.id, r.name, selected.id);
                        audio.playAll(reciter: r, moshaf: selected);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text('Putar Semua'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    tooltip: 'Acak semua',
                    onPressed: () => _shuffleAll(context, r, selected, surahs, settings, audio),
                    icon: const Icon(Icons.shuffle_rounded),
                  ),
                ],
              ),
            ),
          ),
          // Riwayah selector (only when there is more than one).
          if (r.moshafs.length > 1)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: r.moshafs.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final m = r.moshafs[i];
                    final on = m.id == selected.id;
                    return ChoiceChip(
                      selected: on,
                      label: Text(m.name, style: const TextStyle(fontSize: 12)),
                      onSelected: (_) => settings.setReciter(r.id, r.name, m.id),
                    );
                  },
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text('Surah', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            ),
          ),
          SliverList.builder(
            itemCount: surahs.length,
            itemBuilder: (_, i) {
              final s = surahs[i];
              final isCurrent = isThisReciter && audio.service.currentSurah == s.number && audio.service.mode.name == 'surah';
              final palette = paletteFor(s.number, juz: s.ayahs.first.juz);
              final isDark = theme.brightness == Brightness.dark;
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: PressScale(
                  onTap: () {
                    settings.setReciter(r.id, r.name, selected.id);
                    audio.playSurah(reciter: r, moshaf: selected, surahNumber: s.number);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? palette.mid.withValues(alpha: isDark ? 0.30 : 0.10)
                          : (isDark ? AppColors.nightCard : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isCurrent ? palette.mid.withValues(alpha: 0.55) : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                        width: isCurrent ? 1.3 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SurahStarBadge(number: s.number, size: 44, juz: s.ayahs.first.juz, solid: isCurrent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.transliteration,
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: isCurrent ? palette.mid : null)),
                              const SizedBox(height: 2),
                              Text('${s.ayahCount} ayat • ${s.revelation == 'Meccan' ? 'Makkiyah' : 'Madaniyah'}',
                                  style: const TextStyle(fontSize: 11.5)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(s.name, style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 21, height: 1.0, color: isDark ? palette.accent : Color.lerp(palette.deep, Colors.black, 0.35))),
                        const SizedBox(width: 6),
                        Icon(
                          isCurrent && audio.playing ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                          color: isCurrent ? palette.mid : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

/// Shuffles the reciter's whole catalogue.
///
/// Real shuffle: the queue is rebuilt in random order, so playback genuinely
/// jumps around instead of picking one random starting surah and then running
/// in order.
void _shuffleAll(BuildContext context, Reciter r, Moshaf selected, List<Surah> surahs, SettingsProvider settings, AudioProvider audio) {
  if (surahs.isEmpty) return;
  final shuffled = [...surahs]..shuffle(math.Random());
  settings.setReciter(r.id, r.name, selected.id);
  audio.playShuffled(reciter: r, moshaf: selected, surahNumbers: shuffled.map((s) => s.number).toList());
  Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
}
