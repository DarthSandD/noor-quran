import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';
import '../state/settings_provider.dart';
import '../state/qiblah_provider.dart';
import '../data/repository.dart';
import '../models/models.dart';
import 'surah_reader_screen.dart';
import 'search_screen.dart';
import 'player_screen.dart';
import 'tasbih_screen.dart';
import 'asma_screen.dart';
import 'radio_screen.dart';
import 'bookmark_screen.dart';
import 'qiblah_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final qiblah = context.watch<QiblahProvider>();
    final repo = QuranRepository.instance;
    final lastRead = settings.lastRead;
    final surah = lastRead != null ? repo.surah(lastRead.surah) : repo.surah(1);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Greeting(settings: settings)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ContinueCard(
                  surah: surah,
                  ayah: lastRead?.ayah ?? 1,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SurahReaderScreen(surahNumber: surah.number, initialAyah: lastRead?.ayah ?? 1),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _PrayerCard(qiblah: qiblah),
                const SizedBox(height: 18),
                _SectionTitle('Jelajahi', onMore: () {}),
                const SizedBox(height: 10),
                _QuickGrid(),
                const SizedBox(height: 20),
                _SectionTitle('Murottal pilihan', onMore: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen()))),
                const SizedBox(height: 8),
              ]),
            ),
          ),
          SliverToBoxAdapter(child: _FeaturedReciters()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _SectionTitle('Ayat hari ini', onMore: () {}),
                const SizedBox(height: 10),
                _VerseOfDay(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final SettingsProvider settings;
  const _Greeting({required this.settings});
  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 4
        ? 'Selamat malam'
        : hour < 11
            ? 'Selamat pagi'
            : hour < 15
                ? 'Selamat siang'
                : hour < 18
                    ? 'Selamat sore'
                    : 'Selamat malam';
    String hijri = '';
    try {
      hijri = DateFormat('d MMMM y', 'id').format(DateTime.now());
    } catch (_) {
      hijri = DateFormat('d MMM y').format(DateTime.now());
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greet, style: TextStyle(fontSize: 13, letterSpacing: 0.4, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                const Text('Noor Qur\'an', style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                const SizedBox(height: 2),
                Text(hijri, style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          _CircleIcon(icon: Icons.search_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen()))),
          const SizedBox(width: 8),
          _CircleIcon(
            icon: settings.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            onTap: () => settings.setDark(!settings.dark),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIcon({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(11), child: Icon(icon, size: 21)),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final Surah surah;
  final int ayah;
  final VoidCallback onTap;
  const _ContinueCard({required this.surah, required this.ayah, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final progress = (ayah / surah.ayahCount).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: Grad.emerald,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.32), blurRadius: 26, offset: const Offset(0, 12))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                  child: const Text('LANJUT MEMBACA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                ),
                const Spacer(),
                const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 40),
              ],
            ),
            const SizedBox(height: 14),
            Text('Surah ${surah.transliteration}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            const SizedBox(height: 2),
            Text('${surah.nameEn} • Ayat $ayah dari ${surah.ayahCount}', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.22),
                valueColor: const AlwaysStoppedAnimation(AppColors.goldSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final QiblahProvider qiblah;
  const _PrayerCard({required this.qiblah});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = qiblah.next;
    String countdown = '--';
    if (next != null) {
      final d = next.time.difference(DateTime.now());
      if (d.isNegative) {
        countdown = 'sekarang';
      } else {
        final h = d.inHours;
        final m = d.inMinutes % 60;
        countdown = h > 0 ? '${h}j ${m}m' : '${m}m';
      }
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 17, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(qiblah.locationLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis)),
              Text('$countdown lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 62,
            child: qiblah.prayers.isEmpty
                ? Center(child: Text('Atur lokasi untuk waktu shalat', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))))
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: qiblah.prayers.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final p = qiblah.prayers[i];
                      final isNext = next?.name == p.name;
                      return Container(
                        width: 78,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isNext ? theme.colorScheme.primary : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(p.name, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isNext ? Colors.white : theme.colorScheme.onSurface)),
                            const SizedBox(height: 3),
                            Text(DateFormat.Hm().format(p.time), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isNext ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                          ],
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

class _SectionTitle extends StatelessWidget {
  final String text;
  final VoidCallback onMore;
  const _SectionTitle(this.text, {required this.onMore});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const Spacer(),
        TextButton(onPressed: onMore, child: const Text('Semua')),
      ],
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid();
  @override
  Widget build(BuildContext context) {
    final items = [
      _QA(Icons.explore_rounded, 'Kiblat', const Color(0xFF16A085), (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const QiblahScreen()))),
      _QA(Icons.fingerprint_rounded, 'Tasbih', const Color(0xFFD4AF37), (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const TasbihScreen()))),
      _QA(Icons.auto_stories_rounded, 'Cari', const Color(0xFF8E44AD), (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const SearchScreen()))),
      _QA(Icons.diamond_rounded, 'Asmaul Husna', const Color(0xFF2980B9), (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const AsmaScreen()))),
      _QA(Icons.radio_rounded, 'Radio Qur\'an', const Color(0xFFE67E22), (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const RadioScreen()))),
      _QA(Icons.bookmark_rounded, 'Penanda', const Color(0xFFC0392B), (c) => Navigator.push(c, MaterialPageRoute(builder: (_) => const BookmarkScreen()))),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.05,
      children: items.map((e) => _QuickTile(item: e)).toList(),
    );
  }
}

class _QA {
  final IconData icon;
  final String label;
  final Color color;
  final void Function(BuildContext) onTap;
  _QA(this.icon, this.label, this.color, this.onTap);
}

class _QuickTile extends StatelessWidget {
  final _QA item;
  const _QuickTile({required this.item});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => item.onTap(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(color: item.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(item.label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FeaturedReciters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final reciters = QuranRepository.instance.reciters.take(12).toList();
    if (reciters.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(20, 0, 20, 8), child: Text('Qari terkenal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reciters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final r = reciters[i];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(initialReciterId: r.id))),
                child: SizedBox(
                  width: 92,
                  child: Column(
                    children: [
                      Container(
                        height: 72,
                        width: 72,
                        decoration: BoxDecoration(
                          gradient: Grad.gold,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(child: Text(r.name.trim().split(' ').first.characters.first, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800))),
                      ),
                      const SizedBox(height: 6),
                      Text(r.name, maxLines: 2, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VerseOfDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final repo = QuranRepository.instance;
    final day = DateTime.now().difference(DateTime(2024)).inDays;
    final idx = day % 6236;
    Surah s = repo.surah(1);
    Ayah a = s.ayahs.first;
    var acc = 0;
    for (final su in repo.surahs) {
      if (idx < acc + su.ayahCount) {
        s = su;
        a = su.ayahs[idx - acc];
        break;
      }
      acc += su.ayahCount;
    }
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(a.text, textAlign: TextAlign.right, textDirection: ui.TextDirection.rtl, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 26, height: 2.0)),
          const SizedBox(height: 14),
          Text('QS. ${s.transliteration}: ${a.numberInSurah}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: theme.colorScheme.primary)),
          const SizedBox(height: 4),
          FutureBuilder<List<String>>(
            future: repo.translation(context.read<SettingsProvider>().translationId),
            builder: (context, snap) {
              final t = snap.data;
              if (t == null) return const SizedBox(height: 14);
              return Text(t[repo.globalIndex(s.number, a.numberInSurah)], style: TextStyle(fontSize: 13.5, height: 1.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.75)));
            },
          ),
        ],
      ),
    );
  }
}
