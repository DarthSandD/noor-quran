import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/models.dart';

/// Parses the embedded Qur'an bundle into models.
///
/// Runs off the UI isolate via [compute] on native platforms, so the ~1.6 MB
/// payload never causes a dropped frame. On web [compute] runs inline (there
/// are no isolates), which is fine because the bundle is fetched in parallel.
List<Surah> _parseQuran(String raw) {
  final data = json.decode(raw) as Map<String, dynamic>;
  return (data['surahs'] as List)
      .map((e) => Surah.fromJson(e as Map<String, dynamic>))
      .toList(growable: false);
}

List<DuaSegment> _parseDuas(String raw) {
  final data = json.decode(raw) as Map<String, dynamic>;
  return (data['segments'] as List)
      .map((e) => DuaSegment.fromJson(e as Map<String, dynamic>))
      .toList();
}

List<Asma> _parseAsma(String raw) {
  final data = json.decode(raw) as Map<String, dynamic>;
  return (data['items'] as List).map((e) => Asma.fromJson(e as Map<String, dynamic>)).toList();
}

List<Reciter> _parseReciters(String raw) {
  final data = json.decode(raw) as Map<String, dynamic>;
  return (data['reciters'] as List).map((e) => Reciter.fromJson(e as Map<String, dynamic>)).toList();
}

List<Radio> _parseRadios(String raw) {
  final data = json.decode(raw) as Map<String, dynamic>;
  return (data['radios'] as List).map((e) => Radio.fromJson(e as Map<String, dynamic>)).toList();
}

List<AyahReciter> _parseAyahReciters(String raw) {
  final data = json.decode(raw) as Map<String, dynamic>;
  return (data['reciters'] as List).map((e) => AyahReciter.fromJson(e as Map<String, dynamic>)).toList();
}

List<String> _parseStringList(String raw) => (json.decode(raw) as List).cast<String>();

/// Loads and caches the embedded Qur'an bundle.
///
/// The Arabic text is required before the app can render; translations and
/// tafsir are loaded lazily on first use to keep start-up and memory light.
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

  bool get isLoaded => _surahs != null;

  List<Surah> get surahs {
    final s = _surahs;
    if (s == null) {
      throw StateError('QuranRepository.loadCore() has not completed yet.');
    }
    return s;
  }

  List<DuaSegment> get duaSegments => _duaSegments ?? const [];
  List<Asma> get asma => _asma ?? const [];
  List<Reciter> get reciters => _reciters ?? const [];
  List<Radio> get radios => _radios ?? const [];
  List<AyahReciter> get ayahReciters => _ayahReciters ?? const [];

  Future<String> _asset(String name) => rootBundle.loadString('assets/data/$name');

  /// Fatal dependency: the Arabic Qur'an text. Idempotent.
  Future<void> loadCore() async {
    if (_surahs != null) return;
    _surahs = await compute(_parseQuran, await _asset('quran.json'));
  }

  /// Optional bundles. Each is independent: one failing does not block the rest,
  /// and the app stays fully usable without any of them.
  Future<void> loadExtras() async {
    await _load('duas', () async {
      _duaSegments = await compute(_parseDuas, await _asset('duas.json'));
    });
    await _load('asma', () async {
      _asma = await compute(_parseAsma, await _asset('asma.json'));
    });
    await _load('reciters', () async {
      final raw = await _asset('reciters.json');
      _reciters = await compute(_parseReciters, raw);
      _radios = await compute(_parseRadios, raw);
    });
    await _load('ayah reciters', () async {
      _ayahReciters = await compute(_parseAyahReciters, await _asset('ayah_reciters.json'));
    });
  }

  Future<void> _load(String name, Future<void> Function() body) async {
    try {
      await body();
    } catch (e) {
      debugPrint('Noor: optional bundle "$name" failed — $e');
    }
  }

  /// Returns the flat 6 236-entry translation list for an edition id.
  ///
  /// Unknown or retired edition ids fall back to Indonesian rather than
  /// failing, so a preference saved by an older build can never break the app.
  Future<List<String>> translation(String editionId) async {
    final cached = _translations[editionId];
    if (cached != null) return cached;
    final file = switch (editionId) {
      'id.indonesian' => 't_id.json',
      'en.sahih' => 't_en.json',
      'id.jalalayn' => 'tafsir_id.json',
      _ => 't_id.json',
    };
    final list = await compute(_parseStringList, await _asset(file));
    _translations[editionId] = list;
    return list;
  }

  Surah surah(int number) => surahs[number - 1];

  /// Global 0-based ayah index for (surah, ayahInSurah).
  int globalIndex(int surahNumber, int ayahInSurah) =>
      surah(surahNumber).start - 1 + (ayahInSurah - 1);

  /// Simple substring search across Arabic + an optional translation list.
  List<SearchHit> search(String query, List<String>? translationList, {bool arabic = true}) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final needle = q.toLowerCase();
    final normalizedQuery = _normalizeArabic(q);
    final hits = <SearchHit>[];
    for (final s in surahs) {
      for (final a in s.ayahs) {
        var match = arabic && _normalizeArabic(a.text).contains(normalizedQuery);
        final idx = globalIndex(s.number, a.numberInSurah);
        if (!match && translationList != null) {
          match = translationList[idx].toLowerCase().contains(needle);
        }
        if (match) {
          final t = translationList == null ? '' : translationList[idx];
          hits.add(SearchHit(
            surah: s.number,
            ayah: a.numberInSurah,
            surahName: s.transliteration,
            text: t.isEmpty ? a.text : t,
          ));
          if (hits.length >= 300) return hits;
        }
      }
    }
    return hits;
  }

  static const _arabicMarks = [
    '\u064B', '\u064C', '\u064D', '\u064E', '\u064F',
    '\u0650', '\u0651', '\u0652', '\u0670', '\u0640',
    '\u0671', '\u0623', '\u0625', '\u0622', '\u0624', '\u0626', '\u0621',
  ];

  /// Strips diacritics and unifies alef forms so search matches what the eye sees.
  static String _normalizeArabic(String s) {
    var out = s;
    for (final c in _arabicMarks) {
      final replacement = (c == '\u0623' || c == '\u0625' || c == '\u0622') ? '\u0627' : '';
      out = out.replaceAll(c, replacement);
    }
    return out;
  }
}
