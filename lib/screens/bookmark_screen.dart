import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork.dart';
import '../widgets/motion.dart';
import 'surah_reader_screen.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final bookmarks = settings.bookmarks;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Penanda',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800, letterSpacing: -0.5,
                          )),
                      const SizedBox(height: 4),
                      Text('${bookmarks.length} ayat ditandai untuk dibaca kembali',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          )),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: bookmarks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                                begin: Alignment.topLeft, end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.36), blurRadius: 22, offset: const Offset(0, 10))],
                            ),
                            child: const Icon(Icons.bookmark_border_rounded, color: Colors.white, size: 42),
                          ),
                          const SizedBox(height: 16),
                          Text('Belum ada penanda', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.75))),
                          const SizedBox(height: 4),
                          Text('Ketuk ikon penanda saat membaca untuk menyimpan ayat',
                              style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 130),
                      itemCount: bookmarks.length,
                      itemBuilder: (_, i) {
                        final b = bookmarks[i];
                        final palette = paletteFor(b.surah, juz: ((b.surah - 1) ~/ 20) + 1);
                        return FadeRise(
                          delay: Duration(milliseconds: 18 * i),
                          duration: const Duration(milliseconds: 280),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: PressScale(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReaderScreen(surahNumber: b.surah, initialAyah: b.ayah))),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [palette.deep.withValues(alpha: 0.95), palette.mid.withValues(alpha: 0.85)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: SurahArt(number: b.surah, radius: 16, showNumber: false),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(b.surahName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: -0.2)),
                                          const SizedBox(height: 2),
                                          Text('Ayat ${b.ayah}',
                                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.78))),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                      onPressed: () => settings.toggleBookmark(b.surah, b.ayah, b.surahName),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}