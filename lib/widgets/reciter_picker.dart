import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repository.dart';
import '../state/audio_provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';

/// Bottom sheet to choose a reciter and start playback for a surah.
/// [fromAyah] (1-based) starts ayah-by-ayah recitation from that verse.
Future<void> showReciterPicker(BuildContext context, {required int startSurah, int? fromAyah}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ReciterPicker(startSurah: startSurah, fromAyah: fromAyah),
  );
}

class _ReciterPicker extends StatefulWidget {
  final int startSurah;
  final int? fromAyah;
  const _ReciterPicker({required this.startSurah, this.fromAyah});
  @override
  State<_ReciterPicker> createState() => _ReciterPickerState();
}

class _ReciterPickerState extends State<_ReciterPicker> {
  bool _ayahMode = false;
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
    final surahName = repo.surah(widget.startSurah).transliteration;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Expanded(child: Text('Putar Surah $surahName', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Per Surah'), icon: Icon(Icons.album_rounded, size: 18)),
                  ButtonSegment(value: true, label: Text('Per Ayat'), icon: Icon(Icons.format_list_numbered_rounded, size: 18)),
                ],
                selected: {_ayahMode},
                onSelectionChanged: (v) => setState(() => _ayahMode = v.first),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _q = v.toLowerCase()),
                decoration: const InputDecoration(hintText: 'Cari qari…', prefixIcon: Icon(Icons.search_rounded)),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: _ayahMode
                  ? _AyahList(controller: controller, q: _q, startSurah: widget.startSurah, fromAyah: widget.fromAyah ?? 1)
                  : _SurahList(controller: controller, q: _q, startSurah: widget.startSurah),
            ),
          ],
        );
      },
    );
  }
}

class _SurahList extends StatelessWidget {
  final ScrollController controller;
  final String q;
  final int startSurah;
  const _SurahList({required this.controller, required this.q, required this.startSurah});

  @override
  Widget build(BuildContext context) {
    final reciters = QuranRepository.instance.reciters.where((r) {
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q);
    }).toList();
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: reciters.length,
      itemBuilder: (_, i) {
        final r = reciters[i];
        final moshafs = r.moshafs.where((m) => m.hasSurah(startSurah)).toList();
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            shape: const Border(),
            collapsedShape: const Border(),
            leading: CircleAvatar(
              backgroundColor: AppColors.emerald.withValues(alpha: 0.15),
              child: Text(r.name.trim().split(' ').first.characters.first, style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w800)),
            ),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            subtitle: Text('${moshafs.length} riwayat tersedia', style: const TextStyle(fontSize: 11.5)),
            children: [
              for (final m in moshafs)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.play_circle_outline_rounded, size: 20),
                  title: Text(m.name, style: const TextStyle(fontSize: 13)),
                  onTap: () async {
                    final audio = context.read<AudioProvider>();
                    final settings = context.read<SettingsProvider>();
                    settings.setReciter(r.id, r.name, m.id);
                    Navigator.pop(context);
                    await audio.playSurah(reciter: r, moshaf: m, surahNumber: startSurah);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AyahList extends StatelessWidget {
  final ScrollController controller;
  final String q;
  final int startSurah;
  final int fromAyah;
  const _AyahList({required this.controller, required this.q, required this.startSurah, required this.fromAyah});

  @override
  Widget build(BuildContext context) {
    final list = QuranRepository.instance.ayahReciters.where((r) {
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q);
    }).toList();
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final r = list[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.gold.withValues(alpha: 0.2),
              child: const Icon(Icons.record_voice_over_rounded, size: 20, color: AppColors.gold),
            ),
            title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
            subtitle: Text('Ayat $fromAyah • ${r.bitrate}kbps', style: const TextStyle(fontSize: 11.5)),
            trailing: const Icon(Icons.play_arrow_rounded),
            onTap: () async {
              Navigator.pop(context);
              await context.read<AudioProvider>().playAyahRecitation(reciter: r, surahNumber: startSurah, fromAyah: fromAyah);
            },
          ),
        );
      },
    );
  }
}
