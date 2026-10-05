import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import '../widgets/brand.dart';
import '../state/settings_provider.dart';
import '../state/qiblah_provider.dart';
import '../data/repository.dart';
import '../models/models.dart';
import 'surah_reader_screen.dart';
import 'search_screen.dart';
import 'murottal_screen.dart';
import 'reciter_screen.dart';
import 'surah_list_screen.dart';
import 'tasbih_screen.dart';
import 'asma_screen.dart';
import 'radio_screen.dart';
import 'qiblah_screen.dart';
import 'dua_screen.dart';
import 'more_screen.dart';
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
          SliverToBoxAdapter(child: FadeRise(child: _Greeting(settings: settings))),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                FadeRise(
                  delay: const Duration(milliseconds: 60),
                  child: _ContinueCard(
                    surah: surah,
                    ayah: lastRead?.ayah ?? 1,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SurahReaderScreen(surahNumber: surah.number, initialAyah: lastRead?.ayah ?? 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FadeRise(delay: const Duration(milliseconds: 110), child: _PrayerCard(qiblah: qiblah)),
                const SizedBox(height: 22),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeRise(
              delay: const Duration(milliseconds: 150),
              child: SectionHeader('Jelajahi', action: 'Semua', onAction: () => _go(context, const MoreScreen())),
            ),
          ),
          SliverToBoxAdapter(child: FadeRise(delay: const Duration(milliseconds: 190), child: const _QuickGrid())),
          SliverToBoxAdapter(
            child: FadeRise(
              delay: const Duration(milliseconds: 240),
              child: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: SectionHeader('Murottal pilihan', action: 'Buka', onAction: () => _go(context, const MurottalScreen())),
              ),
            ),
          ),
          SliverToBoxAdapter(child: FadeRise(delay: const Duration(milliseconds: 280), child: _FeaturedReciters())),
          SliverToBoxAdapter(
            child: FadeRise(
              delay: const Duration(milliseconds: 330),
              child: const Padding(
                padding: EdgeInsets.only(top: 24),
                child: SectionHeader('Ayat hari ini'),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
            sliver: SliverToBoxAdapter(child: FadeRise(delay: const Duration(milliseconds: 370), child: const _VerseOfDay())),
          ),
        ],
      ),
    );
  }

  static void _go(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _Greeting extends StatelessWidget {
  final SettingsProvider settings;
  const _Greeting({required this.settings});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
    String date;
    try {
      date = DateFormat('EEEE, d MMMM y', 'id').format(DateTime.now());
    } catch (_) {
      date = DateFormat('EEEE, d MMM y').format(DateTime.now());
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const NoorMark(size: 26, glow: false),
                    const SizedBox(width: 8),
                    Text(
                      greet,
                      style: TextStyle(fontSize: 13, letterSpacing: 0.2, color: scheme.onSurface.withValues(alpha: 0.6), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text("Noor Qur'an", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.9)),
                const SizedBox(height: 3),
                Text(date, style: TextStyle(fontSize: 12.5, color: scheme.onSurface.withValues(alpha: 0.5), fontWeight: FontWeight.w500)),
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
    final scheme = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      scale: 0.9,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Icon(icon, size: 20, color: scheme.onSurface.withValues(alpha: 0.85)),
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
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: Grad.emerald,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: AppColors.emeraldDeep.withValues(alpha: 0.34), blurRadius: 30, offset: const Offset(0, 14))],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -22,
              top: -26,
              child: Opacity(opacity: 0.12, child: const NoorMark(size: 140, glow: false, color: Colors.white)),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                      child: const Text('LANJUT MEMBACA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                    ),
                    const Spacer(),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Surah ${surah.transliteration}', style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 3),
                Text('${surah.nameEn} • Ayat $ayah dari ${surah.ayahCount}', style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: Motion.slow,
                    curve: Motion.curve,
                    builder: (_, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(AppColors.goldSoft),
                    ),
                  ),
                ),
              ],
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
    final scheme = Theme.of(context).colorScheme;
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
    return NoorCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 17, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(child: Text(qiblah.locationLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis)),
              if (next != null) ...[
                const PulseDot(size: 7, color: AppColors.gold),
                const SizedBox(width: 6),
                Text('$countdown lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.primary)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (qiblah.prayers.isEmpty)
            // Compact empty state: one clear line + a single call to action.
            PressScale(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QiblahScreen())),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(Icons.my_location_rounded, size: 18, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Aktifkan lokasi untuk melihat waktu shalat hari ini',
                        style: TextStyle(fontSize: 12.5, height: 1.35, color: scheme.onSurface.withValues(alpha: 0.75), fontWeight: FontWeight.w500),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 20, color: scheme.primary),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: qiblah.prayers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final p = qiblah.prayers[i];
                  final isNext = next?.name == p.name;
                  return AnimatedContainer(
                    duration: Motion.med,
                    curve: Motion.curve,
                    width: 80,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      gradient: isNext ? Grad.emeraldSoft : null,
                      color: isNext ? null : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(p.name, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isNext ? Colors.white : scheme.onSurface)),
                        const SizedBox(height: 3),
                        Text(DateFormat.Hm().format(p.time),
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isNext ? Colors.white.withValues(alpha: 0.9) : scheme.onSurface.withValues(alpha: 0.65))),
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

class _QuickGrid extends StatelessWidget {
  const _QuickGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      _QA(Icons.explore_rounded, 'Kiblat', const Color(0xFF16A085), (c) => _go(c, const QiblahScreen())),
      _QA(Icons.fingerprint_rounded, 'Tasbih', const Color(0xFFD4AF37), (c) => _go(c, const TasbihScreen())),
      _QA(Icons.auto_stories_rounded, 'Qur\'an', const Color(0xFF8E44AD), (c) => _go(c, const SurahListScreen())),
      _QA(Icons.diamond_rounded, 'Asmaul Husna', const Color(0xFF2980B9), (c) => _go(c, const AsmaScreen())),
      _QA(Icons.radio_rounded, 'Radio Qur\'an', const Color(0xFFE67E22), (c) => _go(c, const RadioScreen())),
      _QA(Icons.favorite_rounded, 'Doa & Dzikir', const Color(0xFFC0392B), (c) => _go(c, const DuaScreen())),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
        children: items.asMap().entries.map((e) => FadeRise(delay: Duration(milliseconds: 60 * e.key), child: _QuickTile(item: e.value))).toList(),
      ),
    );
  }

  static void _go(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return PressScale(
      onTap: () => item.onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightCard : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          boxShadow: isDark ? null : [BoxShadow(color: AppColors.ink.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [item.color.withValues(alpha: 0.22), item.color.withValues(alpha: 0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(height: 9),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(item.label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedReciters extends StatelessWidget {
  const _FeaturedReciters();

  @override
  Widget build(BuildContext context) {
    final reciters = QuranRepository.instance.reciters.take(12).toList();
    if (reciters.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: reciters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, i) {
          final r = reciters[i];
          return FadeRise(
            delay: Duration(milliseconds: 40 * i),
            child: PressScale(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReciterScreen(reciterId: r.id))),
              child: SizedBox(
                width: 88,
                child: Column(
                  children: [
                    Container(
                      height: 74,
                      width: 74,
                      decoration: BoxDecoration(
                        gradient: Grad.goldSheen,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.32), blurRadius: 16, offset: const Offset(0, 8))],
                      ),
                      child: Center(
                        child: Text(
                          r.name.trim().split(' ').first.characters.first,
                          style: const TextStyle(color: AppColors.emeraldDeep, fontSize: 28, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(r.name, maxLines: 2, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.25, color: scheme.onSurface.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerseOfDay extends StatelessWidget {
  const _VerseOfDay();

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
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return PressScale(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SurahReaderScreen(surahNumber: s.number, initialAyah: a.numberInSurah)),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightCard : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 1.2),
          boxShadow: isDark ? null : [BoxShadow(color: AppColors.gold.withValues(alpha: 0.1), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.gold),
                ),
                const SizedBox(width: 8),
                Text('QS. ${s.transliteration}: ${a.numberInSurah}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: scheme.primary)),
              ],
            ),
            const SizedBox(height: 18),
            Text(a.text, textAlign: TextAlign.right, textDirection: ui.TextDirection.rtl, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 27, height: 2.05)),
            const SizedBox(height: 16),
            Container(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
            FutureBuilder<List<String>>(
              future: repo.translation(context.read<SettingsProvider>().translationId),
              builder: (context, snap) {
                final t = snap.data;
                if (t == null) return const SizedBox(height: 14);
                return Text(t[repo.globalIndex(s.number, a.numberInSurah)],
                    style: TextStyle(fontSize: 13.5, height: 1.6, color: scheme.onSurface.withValues(alpha: 0.78), fontWeight: FontWeight.w500));
              },
            ),
          ],
        ),
      ),
    );
  }
}
