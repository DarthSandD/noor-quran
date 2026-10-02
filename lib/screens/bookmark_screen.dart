import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import 'surah_reader_screen.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final bookmarks = settings.bookmarks;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Penanda (${bookmarks.length})')),
      body: bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('Belum ada penanda', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                  const SizedBox(height: 4),
                  Text('Ketuk ikon penanda saat membaca', style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.45))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              itemCount: bookmarks.length,
              itemBuilder: (_, i) {
                final b = bookmarks[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.bookmark_rounded, color: AppColors.gold),
                    title: Text('Surah ${b.surahName}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                    subtitle: Text('Ayat ${b.ayah}', style: const TextStyle(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => settings.toggleBookmark(b.surah, b.ayah, b.surahName),
                    ),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReaderScreen(surahNumber: b.surah, initialAyah: b.ayah))),
                  ),
                );
              },
            ),
    );
  }
}
