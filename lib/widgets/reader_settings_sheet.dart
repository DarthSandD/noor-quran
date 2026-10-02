import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/settings_provider.dart';

class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            const Text('Tampilan Bacaan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            const _Label('Ukuran teks Arab'),
            Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: s.arabicScale,
                    min: 0.7,
                    max: 1.8,
                    divisions: 11,
                    label: '${(s.arabicScale * 100).round()}%',
                    onChanged: s.setArabicScale,
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 22)),
              ],
            ),
            const _Label('Jenis huruf Arab'),
            Wrap(
              spacing: 8,
              children: [
                _FontChip(name: 'AmiriQuran', label: 'Amiri Quran', selected: s.arabicFont, onTap: s.setArabicFont),
                _FontChip(name: 'Amiri', label: 'Amiri', selected: s.arabicFont, onTap: s.setArabicFont),
                _FontChip(name: 'ScheherazadeNew', label: 'Scheherazade', selected: s.arabicFont, onTap: s.setArabicFont),
              ],
            ),
            const SizedBox(height: 18),
            const _Label('Terjemahan'),
            RadioGroup<String>(
              groupValue: s.translationId,
              onChanged: (v) {
                if (v != null) s.setTranslation(v);
              },
              child: Column(
                children: [
                  for (final e in const [
                    ('id.indonesian', 'Bahasa Indonesia (Kemenag)'),
                    ('en.sahih', 'English — Saheeh International'),
                    ('en.arberry', 'English — Arberry'),
                  ])
                    RadioListTile<String>(
                      value: e.$1,
                      title: Text(e.$2, style: const TextStyle(fontSize: 14)),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: s.showTranslation,
              onChanged: s.setShowTranslation,
              title: const Text('Tampilkan terjemahan'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: s.showTafsir,
              onChanged: s.setShowTafsir,
              title: const Text('Tampilkan Tafsir Jalalayn'),
              subtitle: const Text('Bahasa Indonesia', style: TextStyle(fontSize: 11)),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 30),
            SwitchListTile(
              value: s.autoScroll,
              onChanged: s.setAutoScroll,
              title: const Text('Gulir otomatis saat diputar'),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              value: s.keepScreenOn,
              onChanged: s.setKeepScreenOn,
              title: const Text('Layar tetap menyala'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
      );
}

class _FontChip extends StatelessWidget {
  final String name;
  final String label;
  final String selected;
  final void Function(String) onTap;
  const _FontChip({required this.name, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final sel = name == selected;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontFamily: name, fontSize: 13)),
      selected: sel,
      onSelected: (_) => onTap(name),
    );
  }
}
