import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Holds all user preferences, bookmarks and last-read position.
class SettingsProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  bool _dark = false;
  bool get dark => _dark;

  bool _systemTheme = false;
  bool get systemTheme => _systemTheme;

  double _arabicScale = 1.0;
  double get arabicScale => _arabicScale;

  String _arabicFont = 'AmiriQuran';
  String get arabicFont => _arabicFont;

  String _translationId = 'id.indonesian';
  String get translationId => _translationId;

  bool _showTranslation = true;
  bool get showTranslation => _showTranslation;

  bool _showTransliteration = false;
  bool get showTransliteration => _showTransliteration;

  bool _wordByWord = false;
  bool get wordByWord => _wordByWord;

  bool _showTafsir = false;
  bool get showTafsir => _showTafsir;

  bool _keepScreenOn = false;
  bool get keepScreenOn => _keepScreenOn;

  int _reciterId = 0;
  int get reciterId => _reciterId;
  String _reciterName = '';
  String get reciterName => _reciterName;
  int _moshafId = 0;
  int get moshafId => _moshafId;

  bool _autoScroll = true;
  bool get autoScroll => _autoScroll;

  bool _hapticsEnabled = true;
  bool get hapticsEnabled => _hapticsEnabled;

  int _tasbihCount = 0;
  int get tasbihCount => _tasbihCount;
  int _tasbihTarget = 33;
  int get tasbihTarget => _tasbihTarget;

  LastRead? _lastRead;
  LastRead? get lastRead => _lastRead;

  final List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  bool isBookmarked(int surah, int ayah) => _bookmarks.any((b) => b.surah == surah && b.ayah == ayah);
  Bookmark? bookmarkFor(int surah, int ayah) {
    for (final b in _bookmarks) {
      if (b.surah == surah && b.ayah == ayah) return b;
    }
    return null;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    _dark = p.getBool('dark') ?? false;
    _systemTheme = p.getBool('systemTheme') ?? false;
    _arabicScale = p.getDouble('arabicScale') ?? 1.0;
    _arabicFont = p.getString('arabicFont') ?? 'AmiriQuran';
    _translationId = p.getString('translationId') ?? 'id.indonesian';
    // Retired editions (e.g. the removed Arberry translation) must not linger in
    // a saved preference, or the reader would request a file that no longer ships.
    const validEditions = {'id.indonesian', 'en.sahih'};
    if (!validEditions.contains(_translationId)) {
      _translationId = 'id.indonesian';
      _prefs?.setString('translationId', _translationId);
    }
    _showTranslation = p.getBool('showTranslation') ?? true;
    _showTransliteration = p.getBool('showTransliteration') ?? false;
    _wordByWord = p.getBool('wordByWord') ?? false;
    _showTafsir = p.getBool('showTafsir') ?? false;
    _keepScreenOn = p.getBool('keepScreenOn') ?? false;
    _reciterId = p.getInt('reciterId') ?? 0;
    _reciterName = p.getString('reciterName') ?? '';
    _moshafId = p.getInt('moshafId') ?? 0;
    _autoScroll = p.getBool('autoScroll') ?? true;
    _hapticsEnabled = p.getBool('haptics') ?? true;
    _tasbihCount = p.getInt('tasbihCount') ?? 0;
    _tasbihTarget = p.getInt('tasbihTarget') ?? 33;
    final lr = p.getString('lastRead');
    if (lr != null) {
      try {
        _lastRead = LastRead.fromJson(json.decode(lr) as Map<String, dynamic>);
      } catch (_) {}
    }
    final bm = p.getString('bookmarks');
    if (bm != null) {
      try {
        _bookmarks
          ..clear()
          ..addAll((json.decode(bm) as List).map((e) => Bookmark.fromJson(e as Map<String, dynamic>)));
      } catch (_) {}
    }
    notifyListeners();
  }

  void setDark(bool v) {
    _dark = v;
    _systemTheme = false;
    _prefs?.setBool('dark', v);
    _prefs?.setBool('systemTheme', false);
    notifyListeners();
  }

  void setSystemTheme(bool v) {
    _systemTheme = v;
    _prefs?.setBool('systemTheme', v);
    notifyListeners();
  }

  void setArabicScale(double v) {
    _arabicScale = v;
    _prefs?.setDouble('arabicScale', v);
    notifyListeners();
  }

  void setArabicFont(String f) {
    _arabicFont = f;
    _prefs?.setString('arabicFont', f);
    notifyListeners();
  }

  void setTranslation(String id) {
    _translationId = id;
    _prefs?.setString('translationId', id);
    notifyListeners();
  }

  void setShowTranslation(bool v) {
    _showTranslation = v;
    _prefs?.setBool('showTranslation', v);
    notifyListeners();
  }

  void setShowTransliteration(bool v) {
    _showTransliteration = v;
    _prefs?.setBool('showTransliteration', v);
    notifyListeners();
  }

  void setWordByWord(bool v) {
    _wordByWord = v;
    _prefs?.setBool('wordByWord', v);
    notifyListeners();
  }

  void setShowTafsir(bool v) {
    _showTafsir = v;
    _prefs?.setBool('showTafsir', v);
    notifyListeners();
  }

  void setKeepScreenOn(bool v) {
    _keepScreenOn = v;
    _prefs?.setBool('keepScreenOn', v);
    notifyListeners();
  }

  void setReciter(int id, String name, int moshafId) {
    _reciterId = id;
    _reciterName = name;
    _moshafId = moshafId;
    _prefs?.setInt('reciterId', id);
    _prefs?.setString('reciterName', name);
    _prefs?.setInt('moshafId', moshafId);
    notifyListeners();
  }

  void setAutoScroll(bool v) {
    _autoScroll = v;
    _prefs?.setBool('autoScroll', v);
    notifyListeners();
  }

  void setHaptics(bool v) {
    _hapticsEnabled = v;
    _prefs?.setBool('haptics', v);
    notifyListeners();
  }

  void setTasbihTarget(int v) {
    _tasbihTarget = v;
    _prefs?.setInt('tasbihTarget', v);
    notifyListeners();
  }

  void bumpTasbih() {
    _tasbihCount++;
    _prefs?.setInt('tasbihCount', _tasbihCount);
    notifyListeners();
  }

  void resetTasbih() {
    _tasbihCount = 0;
    _prefs?.setInt('tasbihCount', 0);
    notifyListeners();
  }

  void setLastRead(int surah, int ayah) {
    _lastRead = LastRead(surah: surah, ayah: ayah, timestamp: DateTime.now().millisecondsSinceEpoch);
    _prefs?.setString('lastRead', json.encode(_lastRead!.toJson()));
    notifyListeners();
  }

  void toggleBookmark(int surah, int ayah, String surahName, {int? color, String? note}) {
    final idx = _bookmarks.indexWhere((b) => b.surah == surah && b.ayah == ayah);
    if (idx >= 0) {
      _bookmarks.removeAt(idx);
    } else {
      _bookmarks.insert(
        0,
        Bookmark(
          surah: surah,
          ayah: ayah,
          surahName: surahName,
          color: color,
          note: note,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    }
    _prefs?.setString('bookmarks', json.encode(_bookmarks.map((b) => b.toJson()).toList()));
    notifyListeners();
  }
}
