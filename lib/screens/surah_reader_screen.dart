import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../data/repository.dart';
import '../models/models.dart';
import '../state/settings_provider.dart';
import '../state/audio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/motion.dart';
import '../widgets/reader_settings_sheet.dart';
import '../widgets/reciter_picker.dart';

class SurahReaderScreen extends StatefulWidget {
  final int surahNumber;
  final int initialAyah;
  const SurahReaderScreen({super.key, required this.surahNumber, this.initialAyah = 1});

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  final ItemScrollController _scroll = ItemScrollController();
  final ItemPositionsListener _positions = ItemPositionsListener.create();

  List<String>? _translation;
  List<String>? _tafsir;
  int? _lastAutoScrolled;

  Surah get surah => QuranRepository.instance.surah(widget.surahNumber);

  @override
  void initState() {
    super.initState();
    _loadTranslations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialAyah > 1) {
        _scroll.jumpTo(index: widget.initialAyah - 1, alignment: 0.1);
      }
    });
  }

  Future<void> _loadTranslations() async {
    final repo = QuranRepository.instance;
    final tid = context.read<SettingsProvider>().translationId;
    final t = await repo.translation(tid);
    if (mounted) setState(() => _translation = t);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tid = context.watch<SettingsProvider>().translationId;
    if (_loadedFor != tid) {
      _loadedFor = tid;
      _loadTranslations();
    }
  }

  String? _loadedFor;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final audio = context.watch<AudioProvider>();

    // Auto-scroll to the ayah currently being recited (ayah-by-ayah mode).
    if (settings.autoScroll && audio.service.mode.name == 'ayah' && audio.service.currentSurah == widget.surahNumber) {
      final idx = audio.service.currentAyahIndex;
      if (idx != _lastAutoScrolled && idx >= 0 && idx < surah.ayahCount) {
        _lastAutoScrolled = idx;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.isAttached) {
            _scroll.scrollTo(index: idx, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic, alignment: 0.28);
          }
        });
      }
    }

    final playingAyah = (audio.service.mode.name == 'ayah' && audio.service.currentSurah == widget.surahNumber)
        ? audio.service.currentAyahIndex
        : -1;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(surah: surah, onSettings: () => _openSettings(context), onPlay: () => _pickReciter(context)),
            Expanded(
              child: ScrollablePositionedList.builder(
                itemScrollController: _scroll,
                itemPositionsListener: _positions,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 160),
                itemCount: surah.ayahs.length + (surah.bismillah ? 1 : 0),
                itemBuilder: (context, i) {
                  if (surah.bismillah && i == 0) {
                    return _Bismillah();
                  }
                  final ai = surah.bismillah ? i - 1 : i;
                  final a = surah.ayahs[ai];
                  return _AyahTile(
                    surah: surah,
                    ayah: a,
                    translation: settings.showTranslation && _translation != null ? _translation![QuranRepository.instance.globalIndex(surah.number, a.numberInSurah)] : null,
                    tafsir: settings.showTafsir && _tafsir != null ? _tafsir![QuranRepository.instance.globalIndex(surah.number, a.numberInSurah)] : null,
                    highlighted: playingAyah == ai,
                    settings: settings,
                    onTap: () => _ayahActions(context, a, ai),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _ReaderFabs(
        onSettings: () => _openSettings(context),
        onPlay: () => _pickReciter(context),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ReaderSettingsSheet(),
    ).then((_) => _loadTafsirIfNeeded());
  }

  Future<void> _loadTafsirIfNeeded() async {
    final settings = context.read<SettingsProvider>();
    if (settings.showTafsir && _tafsir == null) {
      final t = await QuranRepository.instance.translation('id.jalalayn');
      if (mounted) setState(() => _tafsir = t);
    }
  }

  Future<void> _pickReciter(BuildContext context) async {
    await showReciterPicker(context, startSurah: surah.number);
  }

  void _ayahActions(BuildContext context, Ayah a, int index) {
    final settings = context.read<SettingsProvider>();
    final audio = context.read<AudioProvider>();
    final bookmarked = settings.isBookmarked(surah.number, a.numberInSurah);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('QS. ${surah.transliteration}: ${a.numberInSurah}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: AppColors.gold),
              title: Text(bookmarked ? 'Hapus penanda' : 'Tandai ayat'),
              onTap: () {
                settings.toggleBookmark(surah.number, a.numberInSurah, surah.transliteration);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow_rounded),
              title: const Text('Putar dari ayat ini'),
              onTap: () async {
                Navigator.pop(ctx);
                final reciters = audio.service.ayahReciters.isNotEmpty ? audio.service.ayahReciters : QuranRepository.instance.ayahReciters;
                if (reciters.isEmpty) return;
                final sel = audio.service.ayahReciter ?? reciters.first;
                await audio.playAyahRecitation(reciter: sel, surahNumber: surah.number, fromAyah: a.numberInSurah);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Salin ayat'),
              onTap: () {
                final t = _translation != null ? _translation![QuranRepository.instance.globalIndex(surah.number, a.numberInSurah)] : '';
                Clipboard.setData(ClipboardData(text: '${a.text}\n\n$t\n\n(QS. ${surah.transliteration}: ${a.numberInSurah})'));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ayat disalin')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Bagikan ayat'),
              onTap: () {
                final t = _translation != null ? _translation![QuranRepository.instance.globalIndex(surah.number, a.numberInSurah)] : '';
                SharePlus.instance.share(ShareParams(text: '${a.text}\n\n$t\n\n(QS. ${surah.transliteration}: ${a.numberInSurah})'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Surah surah;
  final VoidCallback onSettings;
  final VoidCallback onPlay;
  const _Header({required this.surah, required this.onSettings, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 16),
      decoration: BoxDecoration(
        gradient: Grad.emerald,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -18,
            child: Opacity(opacity: 0.12, child: const NoorMark(size: 120, glow: false, color: Colors.white)),
          ),
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.text_fields_rounded, color: Colors.white), onPressed: onSettings),
                  IconButton(icon: const Icon(Icons.headphones_rounded, color: Colors.white), onPressed: onPlay),
                ],
              ),
              Text(surah.name, style: const TextStyle(fontFamily: 'AmiriQuran', color: Colors.white, fontSize: 34)),
              const SizedBox(height: 4),
              Text('Surah ${surah.transliteration}', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  '${surah.revelation == 'Meccan' ? 'Makkiyah' : 'Madaniyah'} • ${surah.ayahCount} ayat • Surah ke-${surah.number}',
                  style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bismillah extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: 28 * context.watch<SettingsProvider>().arabicScale,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _AyahTile extends StatelessWidget {
  final Surah surah;
  final Ayah ayah;
  final String? translation;
  final String? tafsir;
  final bool highlighted;
  final SettingsProvider settings;
  final VoidCallback onTap;

  const _AyahTile({
    required this.surah,
    required this.ayah,
    required this.translation,
    required this.tafsir,
    required this.highlighted,
    required this.settings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return AnimatedContainer(
      duration: Motion.med,
      curve: Motion.curve,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primary.withValues(alpha: isDark ? 0.16 : 0.09)
            : (isDark ? AppColors.nightCard : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? scheme.primary.withValues(alpha: 0.55) : scheme.outlineVariant.withValues(alpha: isDark ? 0.9 : 0.65),
          width: highlighted ? 1.5 : 1,
        ),
        boxShadow: (!highlighted && !isDark) ? [BoxShadow(color: AppColors.ink.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))] : null,
      ),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: highlighted ? Grad.emeraldSoft : null,
                    color: highlighted ? null : scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text('${ayah.numberInSurah}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: highlighted ? Colors.white : scheme.primary)),
                ),
                const Spacer(),
                if (ayah.sajda) ...[
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)), child: const Text('Sajdah', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gold))),
                  const SizedBox(width: 6),
                ],
                PressScale(
                  scale: 0.85,
                  onTap: () => settings.toggleBookmark(surah.number, ayah.numberInSurah, surah.transliteration),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      settings.isBookmarked(surah.number, ayah.numberInSurah) ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      size: 21,
                      color: settings.isBookmarked(surah.number, ayah.numberInSurah) ? AppColors.gold : scheme.onSurface.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ayah.text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: settings.arabicFont,
                fontSize: 27 * settings.arabicScale,
                height: 2.05,
                color: scheme.onSurface,
              ),
            ),
            if (translation != null && translation!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: scheme.onSurface.withValues(alpha: 0.06)),
              const SizedBox(height: 10),
              Text(translation!, style: TextStyle(fontSize: 14.5, height: 1.6, color: scheme.onSurface.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
            ],
            if (tafsir != null && tafsir!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Text('Tafsir Jalalayn', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: scheme.onSurface.withValues(alpha: 0.7))),
                    ]),
                    const SizedBox(height: 7),
                    Text(tafsir!, style: TextStyle(fontSize: 13.5, height: 1.55, color: scheme.onSurface.withValues(alpha: 0.78))),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReaderFabs extends StatelessWidget {
  final VoidCallback onSettings;
  final VoidCallback onPlay;
  const _ReaderFabs({required this.onSettings, required this.onPlay});
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'reader_settings',
          onPressed: onSettings,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          child: const Icon(Icons.tune_rounded),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: 'reader_play',
          onPressed: onPlay,
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          child: const Icon(Icons.play_arrow_rounded, size: 30),
        ),
      ],
    );
  }
}
