import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';

/// Loads and caches the embedded Qur'an bundle. Arabic text is loaded once;
/// translations are loaded lazily on first use to keep memory/disk light.
class QuranRepository {
  QuranRepository._();
  static final QuranRepository instance = QuranRepository._();

  List<Surah>? _surahs;
  final Map<String, List<String>> _translations = {};
  List<DuaSegment>? _duaSegments;
  List<Asma>? _asma;
  List<Reciter>? _reciters;
  List<Radio>? _radios;
  List<AyahReciter>? _ayahReciters;

  List<Surah> get surahs => _surahs!;
  bool get isLoaded => _surahs != null;
  List<DuaSegment> get duaSegments => _duaSegments ?? const [];
  List<Asma> get asma => _asma ?? const [];
  List<Reciter> get reciters => _reciters ?? const [];
  List<Radio> get radios => _radios ?? const [];
  List<AyahReciter> get ayahReciters => _ayahReciters ?? const [];

  Future<dynamic> _json(String asset) async =>
      json.decode(await rootBundle.loadString('assets/data/$asset'));

  Future<void> loadCore() async {
    if (_surahs != null) return;
    final data = await _json('quran.json');
    _surahs = (data['surahs'] as List).map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList(growable: false);
  }

  Future<void> loadExtras() async {
    if (_duaSegments == null) {
      final d = await _json('duas.json');
      _duaSegments = (d['segments'] as List).map((e) => DuaSegment.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (_asma == null) {
      final a = await _json('asma.json');
      _asma = (a['items'] as List).map((e) => Asma.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (_reciters == null) {
      final r = await _json('reciters.json');
      _reciters = (r['reciters'] as List).map((e) => Reciter.fromJson(e as Map<String, dynamic>)).toList();
      _radios = (r['radios'] as List).map((e) => Radio.fromJson(e as Map<String, dynamic>)).toList();
    }
    if (_ayahReciters == null) {
      final a = await _json('ayah_reciters.json');
      _ayahReciters = (a['reciters'] as List).map((e) => AyahReciter.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  /// Returns the flat 6236-entry translation list for an edition id.
  Future<List<String>> translation(String editionId) async {
    if (_translations.containsKey(editionId)) return _translations[editionId]!;
    final file = switch (editionId) {
      'id.indonesian' => 't_id.json',
      'en.sahih' => 't_en.json',
      'en.arberry' => 't_en_arberry.json',
      'id.jalalayn' => 'tafsir_id.json',
      _ => 't_en.json',
    };
    final list = (await _json(file) as List).cast<String>();
    _translations[editionId] = list;
    return list;
  }

  Surah surah(int number) => _surahs![number - 1];

  /// Global 0-based ayah index for (surah, ayahInSurah).
  int globalIndex(int surahNumber, int ayahInSurah) => surah(surahNumber).start - 1 + (ayahInSurah - 1);

  /// Simple substring search across Arabic + a translation list.
  List<SearchHit> search(String query, List<String>? translationList, {bool arabic = true}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final hits = <SearchHit>[];
    final needle = q.toLowerCase();
    for (final s in surahs) {
      for (final a in s.ayahs) {
        bool match = arabic && _normalizeArabic(a.text).contains(_normalizeArabic(q));
        if (!match && translationList != null) {
          final t = translationList[globalIndex(s.number, a.numberInSurah)];
          match = t.toLowerCase().contains(needle);
        }
        if (match) {
          final t = translationList != null ? translationList[globalIndex(s.number, a.numberInSurah)] : '';
          hits.add(SearchHit(surah: s.number, ayah: a.numberInSurah, surahName: s.transliteration, text: t.isEmpty ? a.text : t));
          if (hits.length >= 300) return hits;
        }
      }
    }
    return hits;
  }

  static String _normalizeArabic(String s) {
    var out = s;
    for (final c in ['\u064B', '\u064C', '\u064D', '\u064E', '\u064F', '\u0650', '\u0651', '\u0652', '\u0670', '\u0640', '\u0671', '\u0623', '\u0625', '\u0622', '\u0624', '\u0626', '\u0621']) {
      out = out.replaceAll(c, c == '\u0623' || c == '\u0625' || c == '\u0622' ? '\u0627' : '');
    }
    return out;
  }
}
