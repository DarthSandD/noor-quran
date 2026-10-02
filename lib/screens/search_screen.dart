import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../state/settings_provider.dart';
import 'surah_reader_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<SearchHit> _hits = const [];
  bool _searching = false;
  bool _useTranslation = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _run(String q) async {
    if (q.trim().length < 2) {
      setState(() => _hits = const []);
      return;
    }
    setState(() => _searching = true);
    final repo = QuranRepository.instance;
    List<String>? t;
    if (_useTranslation) {
      t = await repo.translation(context.read<SettingsProvider>().translationId);
    }
    final hits = repo.search(q, t);
    if (mounted) {
      setState(() {
        _hits = hits;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Ayat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: _run,
              onChanged: (v) {
                if (v.length >= 3) _run(v);
              },
              decoration: InputDecoration(
                hintText: 'Ketik kata kunci…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: () => _run(_controller.text)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Cari di terjemahan'),
                  selected: _useTranslation,
                  onSelected: (v) => setState(() => _useTranslation = v),
                ),
                const Spacer(),
                if (_hits.isNotEmpty) Text('${_hits.length} hasil', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _hits.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.manage_search_rounded, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('Cari ayat dalam Al-Qur\'an', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                          const SizedBox(height: 4),
                          Text('Mendukung teks Arab dan terjemahan', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    itemCount: _hits.length,
                    itemBuilder: (_, i) {
                      final h = _hits[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text('QS. ${h.surahName}: ${h.ayah}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                          subtitle: Text(h.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, height: 1.5)),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahReaderScreen(surahNumber: h.surah, initialAyah: h.ayah))),
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
