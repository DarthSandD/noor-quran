import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/repository.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import 'asma_screen.dart';
import 'bookmark_screen.dart';
import 'radio_screen.dart';
import 'search_screen.dart';
import 'tasbih_screen.dart';
import 'player_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  /// The APK is served from a dedicated static download host (no service
  /// worker, no SPA rewrites, no redirects) — the closest thing to the
  /// "click and it just downloads" behaviour of a normal website. GitHub
  /// Releases remains the fallback and carries the per-ABI + universal builds.
  static const String androidApkUrl =
      'https://noor-quran-download.vercel.app/noor-quran.apk';
  static const String releasesUrl = 'https://github.com/DarthSandD/noor-quran/releases';

  static Future<void> openApk(BuildContext context) async {
    final uri = Uri.parse(androidApkUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan unduhan')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final repo = QuranRepository.instance;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 130),
        children: [
          FadeRise(
            child: PageHeader(
              title: 'Lainnya',
              subtitle: "Noor Qur'an v1.0.0",
              trailing: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: Grad.goldSheen, borderRadius: BorderRadius.circular(15)),
                child: const Center(child: Text('نور', style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 22, color: AppColors.emeraldDeep))),
              ),
            ),
          ),
          FadeRise(
            delay: const Duration(milliseconds: 60),
            child: _Group(children: [
              _Tile(icon: Icons.search_rounded, color: const Color(0xFF16A085), title: 'Cari Ayat', subtitle: 'Teks Arab & terjemahan', onTap: () => _go(context, const SearchScreen())),
              _Tile(icon: Icons.fingerprint_rounded, color: AppColors.gold, title: 'Tasbih Digital', subtitle: 'Dzikir dengan hitungan', onTap: () => _go(context, const TasbihScreen())),
              _Tile(icon: Icons.diamond_rounded, color: const Color(0xFF2980B9), title: 'Asmaul Husna', subtitle: '99 nama Allah', onTap: () => _go(context, const AsmaScreen())),
              _Tile(icon: Icons.radio_rounded, color: const Color(0xFFE67E22), title: 'Radio Qur\'an', subtitle: '${repo.radios.length} stasiun live', onTap: () => _go(context, const RadioScreen())),
              _Tile(icon: Icons.bookmark_rounded, color: const Color(0xFFC0392B), title: 'Penanda', subtitle: '${settings.bookmarks.length} ayat ditandai', onTap: () => _go(context, const BookmarkScreen())),
              _Tile(icon: Icons.headphones_rounded, color: const Color(0xFF8E44AD), title: 'Pemutar Murottal', subtitle: 'Qari & YouTube', onTap: () => _go(context, const PlayerScreen())),
            ]),
          ),
          const SizedBox(height: 18),
          FadeRise(
            delay: const Duration(milliseconds: 110),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PressScale(
                onTap: () => openApk(context),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: Grad.emerald,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [BoxShadow(color: AppColors.emeraldDeep.withValues(alpha: 0.3), blurRadius: 22, offset: const Offset(0, 10))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.android_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Unduh Aplikasi Android', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                            SizedBox(height: 3),
                            Text('APK v1.0.0 • gratis, tanpa iklan', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(gradient: Grad.goldSheen, borderRadius: BorderRadius.circular(13)),
                        child: const Text('Unduh', style: TextStyle(color: AppColors.emeraldDeep, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          FadeRise(
            delay: const Duration(milliseconds: 150),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('PENGATURAN', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
            ),
          ),
          FadeRise(
            delay: const Duration(milliseconds: 170),
            child: _Group(children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_rounded),
                title: const Text('Mode gelap', style: TextStyle(fontWeight: FontWeight.w600)),
                value: settings.dark,
                onChanged: settings.setDark,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.brightness_auto_rounded),
                title: const Text('Ikuti tema sistem', style: TextStyle(fontWeight: FontWeight.w600)),
                value: settings.systemTheme,
                onChanged: settings.setSystemTheme,
              ),
              ListTile(
                leading: const Icon(Icons.translate_rounded),
                title: const Text('Terjemahan', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(switch (settings.translationId) {
                  'en.sahih' => 'English — Saheeh International',
                  'en.arberry' => 'English — Arberry',
                  _ => 'Bahasa Indonesia (Kemenag)',
                }, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showTranslationPicker(context, settings),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          FadeRise(
            delay: const Duration(milliseconds: 210),
            child: _Group(children: [
              _Tile(icon: Icons.info_outline_rounded, color: Colors.blueGrey, title: 'Tentang Noor Qur\'an', subtitle: 'Sumber data & lisensi', onTap: () => _about(context)),
            ]),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text('نور', style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 38, color: AppColors.emerald)),
                const SizedBox(height: 2),
                Text('Noor Qur\'an • v1.0.0', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _go(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));

  void _showTranslationPicker(BuildContext context, SettingsProvider s) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: RadioGroup<String>(
          groupValue: s.translationId,
          onChanged: (v) {
            if (v != null) s.setTranslation(v);
            Navigator.pop(context);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final e in const [
                ('id.indonesian', 'Bahasa Indonesia (Kemenag)'),
                ('en.sahih', 'English — Saheeh International'),
                ('en.arberry', 'English — Arberry'),
              ])
                RadioListTile<String>(
                  value: e.$1,
                  title: Text(e.$2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _about(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Noor Qur\'an',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.menu_book_rounded, size: 40, color: AppColors.emerald),
      children: const [
        SizedBox(height: 8),
        Text('Aplikasi Qur\'an lengkap dengan teks Uthmani yang tertanam (embedded), terjemahan, tafsir, kiblat, doa, tasbih, dan pemutar murottal.\n'),
        Text('Sumber data:', style: TextStyle(fontWeight: FontWeight.bold)),
        Text('• Teks Arab: Tanzil / Al-Qur\'an Cloud (Uthmani)'),
        Text('• Terjemahan: Kemenag (id), Saheeh International & Arberry (en)'),
        Text('• Tafsir: Jalalayn'),
        Text('• Audio murottal: mp3quran.net, islamic.network, everyayah.com'),
        Text('• Doa & dzikir: Hisnul Muslim'),
        Text('• Waktu shalat: adhan (batoulapps)'),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(children: children),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.color, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
