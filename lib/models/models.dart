/// Immutable data models for the Qur'an app.
library;

class Ayah {
  final int numberInSurah;
  final String text;
  final int juz;
  final int page;
  final bool sajda;
  const Ayah({required this.numberInSurah, required this.text, required this.juz, required this.page, required this.sajda});

  factory Ayah.fromJson(Map<String, dynamic> j) => Ayah(
        numberInSurah: j['n'] as int,
        text: j['t'] as String,
        juz: j['j'] as int,
        page: j['p'] as int,
        sajda: (j['s'] as int) == 1,
      );
}

class Surah {
  final int number;
  final String name;
  final String transliteration;
  final String nameEn;
  final String nameId;
  final String revelation; // Meccan / Medinan
  final int? revelationOrder;
  final int ayahCount;
  final int start; // 1-based global ayah index of first ayah
  final bool bismillah; // render basmalah header before ayah 1
  final List<Ayah> ayahs;
  const Surah({
    required this.number,
    required this.name,
    required this.transliteration,
    required this.nameEn,
    required this.nameId,
    required this.revelation,
    required this.revelationOrder,
    required this.ayahCount,
    required this.start,
    required this.bismillah,
    required this.ayahs,
  });

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
        number: j['number'] as int,
        name: j['name'] as String,
        transliteration: j['transliteration'] as String,
        nameEn: j['name_en'] as String,
        nameId: j['name_id'] as String,
        revelation: j['revelation'] as String,
        revelationOrder: j['revelationOrder'] as int?,
        ayahCount: j['ayahCount'] as int,
        start: j['start'] as int,
        bismillah: (j['bismillah'] as int? ?? 0) == 1,
        ayahs: (j['ayahs'] as List).map((e) => Ayah.fromJson(e as Map<String, dynamic>)).toList(growable: false),
      );
}

class TranslationEdition {
  final String id;
  final String lang;
  final String name;
  const TranslationEdition({required this.id, required this.lang, required this.name});
  factory TranslationEdition.fromJson(Map<String, dynamic> j) =>
      TranslationEdition(id: j['id'] as String, lang: j['lang'] as String, name: j['name'] as String);
}

class Dua {
  final int id;
  final String arabic;
  final String latin;
  final String translation;
  final String source;
  final String benefits;
  const Dua({required this.id, required this.arabic, required this.latin, required this.translation, required this.source, required this.benefits});
  factory Dua.fromJson(Map<String, dynamic> j) => Dua(
        id: j['id'] as int,
        arabic: j['arabic'] as String,
        latin: j['latin'] as String? ?? '',
        translation: j['translation'] as String? ?? '',
        source: j['source'] as String? ?? '',
        benefits: j['benefits'] as String? ?? '',
      );
}

class DuaTitle {
  final String name;
  final List<Dua> duas;
  const DuaTitle({required this.name, required this.duas});
  factory DuaTitle.fromJson(Map<String, dynamic> j) =>
      DuaTitle(name: j['name'] as String, duas: (j['duas'] as List).map((e) => Dua.fromJson(e as Map<String, dynamic>)).toList());
}

class DuaCategory {
  final String name;
  final List<DuaTitle> titles;
  const DuaCategory({required this.name, required this.titles});
  factory DuaCategory.fromJson(Map<String, dynamic> j) =>
      DuaCategory(name: j['name'] as String, titles: (j['titles'] as List).map((e) => DuaTitle.fromJson(e as Map<String, dynamic>)).toList());
}

class DuaSegment {
  final String name;
  final List<DuaCategory> categories;
  const DuaSegment({required this.name, required this.categories});
  factory DuaSegment.fromJson(Map<String, dynamic> j) =>
      DuaSegment(name: j['name'] as String, categories: (j['categories'] as List).map((e) => DuaCategory.fromJson(e as Map<String, dynamic>)).toList());
}

class Asma {
  final int number;
  final String arabic;
  final String transliteration;
  final String en;
  final String enDesc;
  final String id;
  const Asma({required this.number, required this.arabic, required this.transliteration, required this.en, required this.enDesc, required this.id});
  factory Asma.fromJson(Map<String, dynamic> j) => Asma(
        number: j['number'] as int,
        arabic: j['arabic'] as String,
        transliteration: j['transliteration'] as String,
        en: j['en'] as String,
        enDesc: j['en_desc'] as String? ?? '',
        id: j['id'] as String? ?? '',
      );
}

class Moshaf {
  final int id;
  final String name;
  final String server;
  final int? rewaya;
  final int surahTotal;
  final String surahList;
  const Moshaf({required this.id, required this.name, required this.server, required this.rewaya, required this.surahTotal, required this.surahList});
  factory Moshaf.fromJson(Map<String, dynamic> j) => Moshaf(
        id: j['id'] as int,
        name: j['name'] as String,
        server: j['server'] as String,
        rewaya: j['rewaya'] as int?,
        surahTotal: j['surahTotal'] as int? ?? 114,
        surahList: j['surahList'] as String? ?? '',
      );

  bool hasSurah(int n) {
    if (surahList.isEmpty) return true;
    return surahList.split(',').contains('$n');
  }

  String surahUrl(int n) => '$server${n.toString().padLeft(3, '0')}.mp3';
}

class Reciter {
  final int id;
  final String name;
  final String letter;
  final List<Moshaf> moshafs;
  const Reciter({required this.id, required this.name, required this.letter, required this.moshafs});
  factory Reciter.fromJson(Map<String, dynamic> j) => Reciter(
        id: j['id'] as int,
        name: j['name'] as String,
        letter: j['letter'] as String? ?? '',
        moshafs: (j['moshafs'] as List).map((e) => Moshaf.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class Radio {
  final int id;
  final String name;
  final String url;
  const Radio({required this.id, required this.name, required this.url});
  factory Radio.fromJson(Map<String, dynamic> j) => Radio(id: j['id'] as int, name: j['name'] as String, url: j['url'] as String);
}

class Bookmark {
  final int surah;
  final int ayah;
  final String surahName;
  final int? color;
  final String? note;
  final int createdAt;
  const Bookmark({required this.surah, required this.ayah, required this.surahName, this.color, this.note, required this.createdAt});

  Map<String, dynamic> toJson() => {
        'surah': surah,
        'ayah': ayah,
        'surahName': surahName,
        'color': color,
        'note': note,
        'createdAt': createdAt,
      };
  factory Bookmark.fromJson(Map<String, dynamic> j) => Bookmark(
        surah: j['surah'] as int,
        ayah: j['ayah'] as int,
        surahName: j['surahName'] as String? ?? '',
        color: j['color'] as int?,
        note: j['note'] as String?,
        createdAt: j['createdAt'] as int? ?? 0,
      );
  String get key => '$surah:$ayah';
}

class LastRead {
  final int surah;
  final int ayah;
  final int timestamp;
  const LastRead({required this.surah, required this.ayah, required this.timestamp});
  Map<String, dynamic> toJson() => {'surah': surah, 'ayah': ayah, 'timestamp': timestamp};
  factory LastRead.fromJson(Map<String, dynamic> j) =>
      LastRead(surah: j['surah'] as int, ayah: j['ayah'] as int, timestamp: j['timestamp'] as int? ?? 0);
}

class SearchHit {
  final int surah;
  final int ayah;
  final String surahName;
  final String text;
  const SearchHit({required this.surah, required this.ayah, required this.surahName, required this.text});
}

/// A reciter available for verse-by-verse (per-ayah) playback.
class AyahReciter {
  final String id;
  final String name;
  final int bitrate;
  const AyahReciter({required this.id, required this.name, required this.bitrate});
  factory AyahReciter.fromJson(Map<String, dynamic> j) =>
      AyahReciter(id: j['id'] as String, name: j['name'] as String, bitrate: j['bitrate'] as int);
}
