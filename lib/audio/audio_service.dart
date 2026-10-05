import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/models.dart';
import '../data/repository.dart';

/// Qur'anify-style murottal engine.
///
/// Two modes:
///  * [AudioMode.surah]  – one mp3 per surah, streamed from an mp3quran server.
///  * [AudioMode.ayah]   – one mp3 per ayah, streamed from the islamic.network
///    CDN; a playlist is built so playback flows ayah-by-ayah (verse repeat and
///    ayah-by-ayah highlighting come for free).
enum AudioMode { surah, ayah }

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  /// Created lazily, on first use.
  ///
  /// `just_audio_background` requires its `init()` to have completed before an
  /// [AudioPlayer] is constructed, so the player is not built here (touching
  /// the singleton must be free); it is built the first time it is needed,
  /// which is after the background service has signalled readiness.
  AudioPlayer? _player;
  AudioPlayer get player => _player ??= AudioPlayer();

  /// The player if it has already been created, without creating it.
  AudioPlayer? get playerIfCreated => _player;

  List<AyahReciter> _ayahReciters = const [];
  List<AyahReciter> get ayahReciters => _ayahReciters;

  AudioMode _mode = AudioMode.surah;
  AudioMode get mode => _mode;

  int _surah = 1;
  int get currentSurah => _surah;

  int _ayahIndex = 0;
  int get currentAyahIndex => _ayahIndex;

  int _queueAyahOffset = 0; // ayah index (0-based) that queue position 0 maps to

  /// Called by the UI layer when the player's queue index changes.
  void setCurrentIndexHint(int queueIndex) {
    if (_mode == AudioMode.ayah) _ayahIndex = _queueAyahOffset + queueIndex;
  }

  Reciter? _reciter;
  Reciter? get reciter => _reciter;
  Moshaf? _moshaf;
  Moshaf? get moshaf => _moshaf;
  AyahReciter? _ayahReciter;
  AyahReciter? get ayahReciter => _ayahReciter;
  Radio? _radio;
  Radio? get radio => _radio;

  String? _title;
  String get title => _title ?? '';
  String? _subtitle;
  String get subtitle => _subtitle ?? '';

  bool _verseRepeat = false;
  bool get verseRepeat => _verseRepeat;

  bool get hasQueue => _title != null;

  List<Surah> get _surahs => QuranRepository.instance.surahs;

  Future<void> loadAyahReciters() async {
    if (_ayahReciters.isNotEmpty) return;
    _ayahReciters = QuranRepository.instance.ayahReciters;
  }

  /// Called after repository.loadExtras() so ayah reciters are ready.
  void primeAyahReciters() {
    _ayahReciters = QuranRepository.instance.ayahReciters;
  }

  Future<void> playSurah({required Reciter reciter, required Moshaf moshaf, required int surahNumber}) async {
    _mode = AudioMode.surah;
    _reciter = reciter;
    _moshaf = moshaf;
    _surah = surahNumber;
    _ayahIndex = 0;
    _radio = null;
    final s = _surahs[surahNumber - 1];
    _title = 'Surah ${s.transliteration}';
    _subtitle = '${reciter.name} • ${moshaf.name}';
    final url = moshaf.surahUrl(surahNumber);
    await player.setAudioSource(AudioSource.uri(
      Uri.parse(url),
      tag: MediaItem(
        id: url,
        title: _title!,
        artist: reciter.name,
        album: moshaf.name,
      ),
    ));
    _applyLoop();
    player.play();
  }

  Future<void> playAyahRecitation({required AyahReciter reciter, required int surahNumber, int fromAyah = 1}) async {
    _mode = AudioMode.ayah;
    _ayahReciter = reciter;
    _surah = surahNumber;
    _ayahIndex = fromAyah - 1;
    _queueAyahOffset = fromAyah - 1;
    _reciter = null;
    _moshaf = null;
    _radio = null;
    final s = _surahs[surahNumber - 1];
    _title = 'Surah ${s.transliteration}';
    _subtitle = reciter.name;
    await _loadAyahQueue(surahNumber, fromAyah);
    player.play();
  }

  Future<void> _loadAyahQueue(int surahNumber, int fromAyah) async {
    final rec = _ayahReciter!;
    final s = _surahs[surahNumber - 1];
    final sources = <AudioSource>[];
    for (final a in s.ayahs) {
      if (a.numberInSurah < fromAyah) continue;
      final global = QuranRepository.instance.globalIndex(surahNumber, a.numberInSurah) + 1;
      final url = 'https://cdn.islamic.network/quran/audio/${rec.bitrate}/${rec.id}/$global.mp3';
      sources.add(AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url,
          title: 'Surah ${s.transliteration} : ${a.numberInSurah}',
          artist: rec.name,
        ),
      ));
    }
    await player.setAudioSources(sources);
  }

  Future<void> playRadio(Radio r) async {
    _mode = AudioMode.surah;
    _radio = r;
    _title = r.name;
    _subtitle = "Radio Qur'an • Live";
    _reciter = null;
    _moshaf = null;
    await player.setAudioSource(AudioSource.uri(
      Uri.parse(r.url),
      tag: MediaItem(id: r.url, title: r.name, artist: "Radio Qur'an"),
    ));
    player.play();
  }

  Future<void> seekToAyah(int ayahIndex) async {
    if (_mode != AudioMode.ayah) return;
    if (ayahIndex < 0) return;
    _ayahIndex = ayahIndex;
    await player.seek(Duration.zero, index: ayahIndex);
  }

  void setVerseRepeat(bool v) {
    _verseRepeat = v;
    _applyLoop();
  }

  void _applyLoop() {
    player.setLoopMode(_verseRepeat ? LoopMode.one : LoopMode.off);
  }

  Future<void> togglePlay() async {
    if (player.playing) {
      await player.pause();
    } else {
      player.play();
    }
  }

  Future<void> nextSurah() async {
    final n = _surah + 1;
    if (n > 114) return;
    if (_mode == AudioMode.surah && _reciter != null && _moshaf != null) {
      await playSurah(reciter: _reciter!, moshaf: _moshaf!, surahNumber: n);
    } else if (_mode == AudioMode.ayah && _ayahReciter != null) {
      await playAyahRecitation(reciter: _ayahReciter!, surahNumber: n);
    }
  }

  Future<void> previousSurah() async {
    final n = _surah - 1;
    if (n < 1) return;
    if (_mode == AudioMode.surah && _reciter != null && _moshaf != null) {
      await playSurah(reciter: _reciter!, moshaf: _moshaf!, surahNumber: n);
    } else if (_mode == AudioMode.ayah && _ayahReciter != null) {
      await playAyahRecitation(reciter: _ayahReciter!, surahNumber: n);
    }
  }

  Future<void> stop() async {
    await player.stop();
    _title = null;
    _subtitle = null;
  }

  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<bool> get playingStream => player.playingStream;
  Stream<int?> get currentIndexStream => player.currentIndexStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
}
