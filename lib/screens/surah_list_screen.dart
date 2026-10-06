import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork.dart';
import '../widgets/motion.dart';
import 'surah_reader_screen.dart';

enum _Filter { all, meccan, medinan }

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});
  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  _Filter _filter = _Filter.all;
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = QuranRepository.instance;
    final scheme = Theme.of(context).colorScheme;
    final lang = context.watch<SettingsProvider>().translationId.startsWith('id') ? 'id' : 'en';
    var list = repo.surahs;
    if (_filter == _Filter.meccan) list = list.where((s) => s.revelation == 'Meccan').toList();
    if (_filter == _Filter.medinan) list = list.where((s) => s.revelation == 'Medinan').toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((s) =>
          s.transliteration.toLowerCase().contains(q) ||
          s.nameEn.toLowerCase().contains(q) ||
          s.nameId.toLowerCase().contains(q) ||
          s.number.toString() == q).toList();
    }

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          PageHeader(title: "Al-Qur'an", subtitle: '${list.length} surah • 6.236 ayat'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari surah…',
                prefixIcon: const Icon(Icons.search_rounded, size: 21),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () { _controller.clear(); setState(() => _query = ''); }),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _chip('Semua', _Filter.all),
                const SizedBox(width: 8),
                _chip('Makkiyah', _Filter.meccan),
                const SizedBox(width: 8),
                _chip('Madaniyah', _Filter.medinan),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 44, color: scheme.onSurface.withValues(alpha: 0.25)),
                        const SizedBox(height: 10),
                        Text('Surah tidak ditemukan', style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final s = list[i];
                      return FadeRise(
                        delay: Duration(milliseconds: (i % 12) * 25),
                        duration: const Duration(milliseconds: 380),
                        child: _SurahTile(surah: s, lang: lang),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter f) {
    final selected = _filter == f;
    final scheme = Theme.of(context).colorScheme;
    return PressScale(
      onTap: () => setState(() => _filter = f),
      child: AnimatedContainer(
        duration: Motion.med,
        curve: Motion.curve,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? Grad.emeraldSoft : null,
          color: selected ? null : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : scheme.onSurface.withValues(alpha: 0.8)),
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  final Surah surah;
  final String lang;
  const _SurahTile({required this.surah, required this.lang});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final name = lang == 'id' ? surah.nameId : surah.nameEn;
    final palette = paletteFor(surah.number, juz: surah.ayahs.first.juz);

    // The familiar Qur'an-app row: star badge → names → Arabic plate.
    // Modified here with the surah's own palette so the list still feels Noor.
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: PressScale(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReaderScreen(surahNumber: surah.number))),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightCard : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
            boxShadow: isDark ? null : [BoxShadow(color: AppColors.ink.withValues(alpha: 0.035), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Hero(
                tag: 'art-${surah.number}',
                child: SurahStarBadge(number: surah.number, size: 46, juz: surah.ayahs.first.juz),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(surah.transliteration, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _MetaChip(label: surah.revelation == 'Meccan' ? 'Makkiyah' : 'Madaniyah', color: palette.accent),
                        const SizedBox(width: 6),
                        Text('$name • ${surah.ayahCount} ayat',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: scheme.onSurface.withValues(alpha: 0.55))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Ornamental Arabic name plate — the classic Qur'an-app flourish.
              Container(
                constraints: const BoxConstraints(minWidth: 54),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.mid.withValues(alpha: 0.16), palette.deep.withValues(alpha: 0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.accent.withValues(alpha: 0.30)),
                ),
                child: Text(
                  surah.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 22, height: 1.0, color: _ink(scheme, palette)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Keep the Arabic legible in both themes: dark ink on light, accent on dark.
  static Color _ink(ColorScheme scheme, ArtPalette palette) {
    if (scheme.brightness == Brightness.dark) return palette.accent;
    return Color.lerp(palette.deep, Colors.black, 0.35)!;
  }
}

/// Tiny tinted label for revelation place.
class _MetaChip extends StatelessWidget {
  final String label;
  final Color color;
  const _MetaChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: color)),
    );
  }
}


