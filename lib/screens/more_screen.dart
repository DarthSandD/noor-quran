import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/repository.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork.dart';
import '../widgets/motion.dart';
import 'asma_screen.dart';
import 'bookmark_screen.dart';
import 'murottal_screen.dart';
import 'radio_screen.dart';
import 'search_screen.dart';
import 'tasbih_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  /// The APK is served from a dedicated static download host (no service
  /// worker, no SPA rewrites, no redirects) — the closest thing to the
  /// "click and it just downloads" behaviour of a normal website. GitHub
  /// Releases remains the fallback and carries the per-ABI + universal builds.
  static const String androidApkUrl =
      'https://noor-quran-download.vercel.app/noor-quran.apk';
  static const String releasesUrl = 'https://github.com/DarthSandD/noor-quran/releases';

  /// Served as a real static page by the web deployment (see `web/privacy-policy.html`).
  static const String privacyUrl = 'https://noor-quran-wheat.vercel.app/privacy-policy.html';

  /// Opens the APK download.
  ///
  /// The launch mode matters per platform: `externalApplication` is what makes
  /// Android hand the URL to the browser/download manager, but `url_launcher`'s
  /// web implementation only supports `platformDefault` and would otherwise
  /// ignore the request. So the mode is chosen by platform.
  static Future<void> openApk(BuildContext context) async {
    final uri = Uri.parse(androidApkUrl);
    final ok = await launchUrl(
      uri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_self' : null,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka tautan unduhan')),
      );
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
                        _Tile(icon: Icons.search_rounded, paletteIdx: 0, title: 'Cari Ayat', subtitle: 'Teks Arab & terjemahan', onTap: () => _go(context, const SearchScreen())),
                        _Tile(icon: Icons.fingerprint_rounded, paletteIdx: 1, title: 'Tasbih Digital', subtitle: 'Dzikir dengan hitungan', onTap: () => _go(context, const TasbihScreen())),
                        _Tile(icon: Icons.diamond_rounded, paletteIdx: 3, title: 'Asmaul Husna', subtitle: '99 nama Allah', onTap: () => _go(context, const AsmaScreen())),
                        _Tile(icon: Icons.radio_rounded, paletteIdx: 4, title: 'Radio Qur\'an', subtitle: '${repo.radios.length} stasiun live', onTap: () => _go(context, const RadioScreen())),
                        _Tile(icon: Icons.bookmark_rounded, paletteIdx: 5, title: 'Penanda', subtitle: '${settings.bookmarks.length} ayat ditandai', onTap: () => _go(context, const BookmarkScreen())),
                        _Tile(icon: Icons.headphones_rounded, paletteIdx: 2, title: 'Pustaka Murottal', subtitle: '${repo.reciters.length} qari • putar berurutan', onTap: () => _go(context, const MurottalScreen())),
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
              _Tile(icon: Icons.info_outline_rounded, paletteIdx: 1, title: 'Tentang Noor Qur\'an', subtitle: 'Sumber data & lisensi', onTap: () => _about(context)),
              _Tile(icon: Icons.privacy_tip_outlined, paletteIdx: 0, title: 'Kebijakan Privasi', subtitle: 'Cara aplikasi menangani data Anda', onTap: () => _openPrivacy(context)),
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

  /// Opens the privacy policy — in the browser on mobile, in-page on web.
  void _openPrivacy(BuildContext context) async {
    final ok = await launchUrl(
      Uri.parse(privacyUrl),
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka kebijakan privasi')),
      );
    }
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
        Text('• Teks Arab: Tanzil Project (Uthmani) — CC BY 3.0'),
        Text('• Terjemahan: Kemenag (id), Saheeh International (en)'),
        Text('• Tafsir: Jalalayn'),
        Text('• Audio murottal: mp3quran.net, islamic.network'),
        Text('• Doa & dzikir: Hisnul Muslim'),
        Text('• Waktu shalat: adhan (batoulapps) — MIT'),
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
  final int paletteIdx;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _Tile({required this.icon, required this.paletteIdx, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final palette = kArtPalettes[paletteIdx % kArtPalettes.length];
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [palette.deep, palette.mid], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: palette.mid.withValues(alpha: 0.34), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
