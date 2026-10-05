import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/repository.dart';
import '../models/models.dart';
import '../state/settings_provider.dart';
import 'surah_reader_screen.dart';

/// Full-text search over the Qur'an.
///
/// Typing is debounced and every run carries a sequence number, so a slow
/// earlier query can never overwrite the results of a later one — the classic
/// "results flicker back to an older search" bug on fast typing.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  int _seq = 0;

  List<SearchHit> _hits = const [];
  bool _searching = false;
  bool _useTranslation = true;

  /// True once a search has been run for a non-empty query.
  bool _hasSearched = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // Wait for a pause in typing before touching the data.
    _debounce = Timer(const Duration(milliseconds: 320), () => _run(value));
  }

  Future<void> _run(String q) async {
    final query = q.trim();
    final seq = ++_seq;

    if (query.length < 2) {
      if (!mounted) return;
      setState(() {
        _hits = const [];
        _searching = false;
        _hasSearched = query.isNotEmpty;
      });
      return;
    }

    setState(() => _searching = true);

    final repo = QuranRepository.instance;
    List<String>? translation;
    if (_useTranslation) {
      translation = await repo.translation(context.read<SettingsProvider>().translationId);
    }
    final hits = repo.search(query, translation);

    // Discard the result if a newer query has started since.
    if (!mounted || seq != _seq) return;
    setState(() {
      _hits = hits;
      _searching = false;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

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
              onChanged: _onChanged,
              onSubmitted: (v) {
                _debounce?.cancel();
                _run(v);
              },
              decoration: InputDecoration(
                hintText: 'Ketik kata kunci…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Hapus',
                        onPressed: () {
                          _controller.clear();
                          _debounce?.cancel();
                          _run('');
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Cari di terjemahan'),
                  selected: _useTranslation,
                  onSelected: (v) {
                    setState(() => _useTranslation = v);
                    if (_controller.text.trim().length >= 2) _run(_controller.text);
                  },
                ),
                const Spacer(),
                if (_hits.isNotEmpty)
                  Text('${_hits.length} hasil', style: TextStyle(fontSize: 12, color: onSurface.withValues(alpha: 0.5))),
              ],
            ),
          ),
          if (_searching) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _hits.isEmpty ? _empty(context, onSurface) : _results(),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context, Color onSurface) {
    final theme = Theme.of(context);
    final (icon, title, subtitle) = _hasSearched
        ? (Icons.search_off_rounded, 'Tidak ditemukan', 'Coba kata kunci lain atau ubah pengaturan bahasa')
        : (Icons.manage_search_rounded, "Cari ayat dalam Al-Qur'an", 'Mendukung teks Arab dan terjemahan');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: onSurface.withValues(alpha: 0.7))),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.5, color: onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _results() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      itemCount: _hits.length,
      itemBuilder: (_, i) {
        final h = _hits[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('QS. ${h.surahName}: ${h.ayah}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            subtitle: Text(h.text, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, height: 1.5)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SurahReaderScreen(surahNumber: h.surah, initialAyah: h.ayah)),
            ),
          ),
        );
      },
    );
  }
}
