import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/models.dart';
import '../state/audio_provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
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
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: Grad.goldSheen,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.4), blurRadius: 26, offset: const Offset(0, 12))],
                          ),
                          child: Center(
                            child: Text(
                              r.name.trim().split(' ').first.characters.first,
                              style: const TextStyle(color: AppColors.emeraldDeep, fontSize: 40, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
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
                    tooltip: 'Acak',
                    onPressed: () {
                      final n = surahs.isEmpty ? 1 : surahs[DateTime.now().millisecond % surahs.length].number;
                      settings.setReciter(r.id, r.name, selected.id);
                      audio.playSurah(reciter: r, moshaf: selected, surahNumber: n);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                    },
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
              return ListTile(
                onTap: () {
                  settings.setReciter(r.id, r.name, selected.id);
                  audio.playSurah(reciter: r, moshaf: selected, surahNumber: s.number);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()));
                },
                leading: _NumberBadge(number: s.number, active: isCurrent),
                title: Text(s.transliteration, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: isCurrent ? theme.colorScheme.primary : null)),
                subtitle: Text('${s.ayahCount} ayat • ${s.revelation == 'Meccan' ? 'Makkiyah' : 'Madaniyah'}', style: const TextStyle(fontSize: 11.5)),
                trailing: Icon(
                  isCurrent && audio.playing ? Icons.equalizer_rounded : Icons.play_arrow_rounded,
                  color: isCurrent ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  size: 20,
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

class _NumberBadge extends StatelessWidget {
  final int number;
  final bool active;
  const _NumberBadge({required this.number, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.gold.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: active ? AppColors.goldDeep : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
