import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/repository.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key});
  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  String _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segments = QuranRepository.instance.duaSegments;
    final total = segments.fold<int>(0, (a, s) => a + s.categories.fold<int>(0, (b, c) => b + c.titles.fold<int>(0, (d, t) => d + t.duas.length)));
    final q = _query.toLowerCase().trim();
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          PageHeader(title: 'Doa & Dzikir', subtitle: '$total doa • Hisnul Muslim'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari doa…',
                prefixIcon: const Icon(Icons.search_rounded, size: 21),
                suffixIcon: _query.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () { _controller.clear(); setState(() => _query = ''); }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: q.isEmpty
                ? _Segments(segments: segments)
                : _SearchResults(segments: segments, q: q),
          ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  final List<DuaSegment> segments;
  const _Segments({required this.segments});

  @override
  Widget build(BuildContext context) {
    final colors = [const Color(0xFF16A085), const Color(0xFF2980B9), const Color(0xFF8E44AD), const Color(0xFFE67E22), const Color(0xFFC0392B), const Color(0xFFD4AF37), const Color(0xFF27AE60)];
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
      itemCount: segments.length,
      itemBuilder: (_, i) {
        final s = segments[i];
        final count = s.categories.fold<int>(0, (a, c) => a + c.titles.fold<int>(0, (b, t) => b + t.duas.length));
        final color = colors[i % colors.length];
        return FadeRise(
          delay: Duration(milliseconds: 45 * i),
          duration: const Duration(milliseconds: 400),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PressScale(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _CategoryList(segment: s))),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
                      child: Icon(_iconFor(s.name), color: color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_idName(s.name), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                          const SizedBox(height: 3),
                          Text('${s.categories.length} kategori • $count doa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.7)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static IconData _iconFor(String name) => switch (name) {
        'Daily Life' => Icons.wb_sunny_rounded,
        'Prayer' => Icons.mosque_rounded,
        'Remembrance' => Icons.favorite_rounded,
        'Life Situations' => Icons.psychology_rounded,
        'Faith & Hereafter' => Icons.auto_awesome_rounded,
        'Special Occasions' => Icons.celebration_rounded,
        'Quranic Duas' => Icons.menu_book_rounded,
        _ => Icons.star_rounded,
      };

  static String _idName(String n) => switch (n) {
        'Daily Life' => 'Kehidupan Sehari-hari',
        'Prayer' => 'Shalat',
        'Remembrance' => 'Dzikir',
        'Life Situations' => 'Situasi Hidup',
        'Faith & Hereafter' => 'Iman & Akhirat',
        'Special Occasions' => 'Acara Khusus',
        'Quranic Duas' => 'Doa dari Al-Qur\'an',
        _ => n,
      };
}

class _CategoryList extends StatelessWidget {
  final DuaSegment segment;
  const _CategoryList({required this.segment});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_Segments._idName(segment.name))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          for (final c in segment.categories) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
            for (final t in c.titles)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('${t.duas.length} doa', style: const TextStyle(fontSize: 11.5)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _DuaList(title: t.name, duas: t.duas))),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _DuaList extends StatelessWidget {
  final String title;
  final List<Dua> duas;
  const _DuaList({required this.title, required this.duas});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        itemCount: duas.length,
        itemBuilder: (_, i) => _DuaCard(dua: duas[i]),
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  final Dua dua;
  const _DuaCard({required this.dua});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(dua.arabic, textAlign: TextAlign.right, textDirection: TextDirection.rtl, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 25, height: 2.0)),
            if (dua.latin.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(dua.latin, style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5)),
            ],
            if (dua.translation.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(dua.translation, style: TextStyle(fontSize: 14, height: 1.6, color: theme.colorScheme.onSurface.withValues(alpha: 0.85))),
            ],
            if (dua.source.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(children: [
                Icon(Icons.book_outlined, size: 13, color: theme.colorScheme.primary),
                const SizedBox(width: 5),
                Text(dua.source, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
              ]),
            ],
            if (dua.benefits.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Text(dua.benefits, style: const TextStyle(fontSize: 12, height: 1.4)),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: '${dua.arabic}\n\n${dua.translation}\n\n(${dua.source})'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doa disalin')));
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Salin'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  final List<DuaSegment> segments;
  final String q;
  const _SearchResults({required this.segments, required this.q});
  @override
  Widget build(BuildContext context) {
    final hits = <Dua>[];
    for (final s in segments) {
      for (final c in s.categories) {
        for (final t in c.titles) {
          for (final d in t.duas) {
            if (d.translation.toLowerCase().contains(q) || d.latin.toLowerCase().contains(q) || d.arabic.contains(q)) {
              hits.add(d);
            }
          }
        }
      }
    }
    if (hits.isEmpty) {
      return Center(child: Text('Tidak ada doa untuk "$q"', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
      itemCount: hits.length,
      itemBuilder: (_, i) => _DuaCard(dua: hits[i]),
    );
  }
}
