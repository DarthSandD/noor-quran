import 'dart:math' as math;

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../data/repository.dart';
import '../models/models.dart';

/// Playback source.
///
///  * [surah] – one mp3 per surah, streamed from an mp3quran server. The whole
///    reciter catalogue is loaded as a **queue**, so playback flows from the
///    chosen surah all the way to An-Nas without interruption (Spotify's
///    "play album from this track" behaviour).
///  * [ayah]  – one mp3 per ayah, from the islamic.network CDN, also queued so
///    verse repeat and ayah highlighting come for free.
///  * [radio] – a single live stream.
enum AudioMode { surah, ayah, radio }

/// Murottal engine.
///
/// Everything that is "currently playing" lives here, so the UI only has to
/// watch one object. The engine owns the queue; the player only owns the audio.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  /// Created lazily: `just_audio_background` requires its `init()` to have
  /// completed before the first [AudioPlayer] exists, so constructing this
  /// singleton must not touch the player.
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

  int _queueAyahOffset = 0;

  /// Surah numbers in the current surah-mode queue, in play order.
  List<int> _queue = const [];
  List<int> get queue => _queue;

  /// Position within [queue] (0-based), or -1 when unknown.
  int get queueIndex {
    final i = playerIfCreated?.currentIndex;
    return i == null || i < 0 ? -1 : i;
  }

  /// How many items are queued (used by the "up next" UI).
  int get queueLength => _mode == AudioMode.ayah ? _ayahQueueLength : _queue.length;
  int _ayahQueueLength = 0;

  Reciter? _reciter;
  Reciter? get reciter => _reciter;
  Moshaf? _moshaf;
  Moshaf? get moshaf => _moshaf;
  AyahReciter? _ayahReciter;
  AyahReciter? get ayahReciter => _ayahReciter;
  Radio? _radio;
  Radio? get radio => _radio;

  String _title = '';
  String get title => _title;
  String _subtitle = '';
  String get subtitle => _subtitle;

  bool _verseRepeat = false;
  bool get verseRepeat => _verseRepeat;

  /// True once something is loaded and playable.
  bool get hasQueue => _title.isNotEmpty;

  List<Surah> get _surahs => QuranRepository.instance.surahs;

  /// Called by the UI when the player's queue index changes.
  void setCurrentIndexHint(int queueIndex) {
    if (_mode == AudioMode.surah) {
      if (queueIndex >= 0 && queueIndex < _queue.length) {
        _surah = _queue[queueIndex];
        _refreshSurahTitle();
      }
    } else if (_mode == AudioMode.ayah) {
      _ayahIndex = _queueAyahOffset + queueIndex;
    }
  }

  void primeAyahReciters() {
    _ayahReciters = QuranRepository.instance.ayahReciters;
  }

  // ---------------------------------------------------------------- surah mode

  /// Plays [surahNumber] and **everything after it** for the chosen reciter,
  /// exactly like starting an album from one track: the queue runs to An-Nas
  /// and auto-advances. Set [single] to play just the one surah.
  Future<void> playSurah({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surahNumber,
    bool single = false,
  }) async {
    _mode = AudioMode.surah;
    _reciter = reciter;
    _moshaf = moshaf;
    _radio = null;
    _ayahReciter = null;
    _ayahQueueLength = 0;

    final list = _surahs
        .where((s) => moshaf.hasSurah(s.number) && (single ? s.number == surahNumber : s.number >= surahNumber))
        .toList(growable: false);
    if (list.isEmpty) return;

    _queue = list.map((s) => s.number).toList(growable: false);
    _surah = _queue.first;
    _refreshSurahTitle();

    final sources = [
      for (final s in list)
        AudioSource.uri(
          Uri.parse(moshaf.surahUrl(s.number)),
          tag: MediaItem(
            id: moshaf.surahUrl(s.number),
            title: 'Surah ${s.transliteration}',
            artist: reciter.name,
            album: moshaf.name,
          ),
        ),
    ];

    await player.setAudioSources(sources, initialIndex: 0, initialPosition: Duration.zero);
    _applyLoop();
    player.play();
  }

  /// Convenience for "Putar Semua": the whole reciter catalogue from Al-Fatihah.
  Future<void> playAll({required Reciter reciter, required Moshaf moshaf}) =>
      playSurah(reciter: reciter, moshaf: moshaf, surahNumber: 1);

  /// Plays an explicit, pre-shuffled list of surahs in that exact order.
  ///
  /// The queue order is whatever [surahNumbers] says, so shuffle actually
  /// shuffles the whole run rather than just its starting point.
  Future<void> playShuffled({
    required Reciter reciter,
    required Moshaf moshaf,
    required List<int> surahNumbers,
  }) async {
    _mode = AudioMode.surah;
    _reciter = reciter;
    _moshaf = moshaf;
    _radio = null;
    _ayahReciter = null;
    _ayahQueueLength = 0;

    final list = [
      for (final n in surahNumbers)
        if (n >= 1 && n <= 114 && moshaf.hasSurah(n)) _surahs[n - 1],
    ];
    if (list.isEmpty) return;

    _queue = list.map((s) => s.number).toList(growable: false);
    _surah = _queue.first;
    _refreshSurahTitle();

    final sources = [
      for (final s in list)
        AudioSource.uri(
          Uri.parse(moshaf.surahUrl(s.number)),
          tag: MediaItem(
            id: moshaf.surahUrl(s.number),
            title: 'Surah ${s.transliteration}',
            artist: reciter.name,
            album: moshaf.name,
          ),
        ),
    ];

    await player.setAudioSources(sources, initialIndex: 0, initialPosition: Duration.zero);
    _applyLoop();
    player.play();
  }

  void _refreshSurahTitle() {
    if (_surah < 1 || _surah > 114) return;
    final s = _surahs[_surah - 1];
    _title = 'Surah ${s.transliteration}';
    _subtitle = _reciter == null
        ? (_moshaf?.name ?? '')
        : '${_reciter!.name} • ${_moshaf?.name ?? ''}';
  }

  // ----------------------------------------------------------------- ayah mode

  Future<void> playAyahRecitation({
    required AyahReciter reciter,
    required int surahNumber,
    int fromAyah = 1,
  }) async {
    _mode = AudioMode.ayah;
    _ayahReciter = reciter;
    _surah = surahNumber;
    _ayahIndex = fromAyah - 1;
    _queueAyahOffset = fromAyah - 1;
    _reciter = null;
    _moshaf = null;
    _radio = null;
    _queue = const [];

    final s = _surahs[surahNumber - 1];
    _title = 'Surah ${s.transliteration}';
    _subtitle = reciter.name;

    final sources = <AudioSource>[];
    for (final a in s.ayahs) {
      if (a.numberInSurah < fromAyah) continue;
      final global = QuranRepository.instance.globalIndex(surahNumber, a.numberInSurah) + 1;
      final url = 'https://cdn.islamic.network/quran/audio/${reciter.bitrate}/${reciter.id}/$global.mp3';
      sources.add(AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url,
          title: 'Surah ${s.transliteration} : ${a.numberInSurah}',
          artist: reciter.name,
        ),
      ));
    }
    _ayahQueueLength = sources.length;
    await player.setAudioSources(sources, initialIndex: 0, initialPosition: Duration.zero);
    player.play();
  }

  // ---------------------------------------------------------------- radio mode

  Future<void> playRadio(Radio r) async {
    _mode = AudioMode.radio;
    _radio = r;
    _reciter = null;
    _moshaf = null;
    _ayahReciter = null;
    _queue = const [];
    _ayahQueueLength = 0;
    _title = r.name;
    _subtitle = "Radio Qur'an • Live";
    await player.setAudioSource(AudioSource.uri(
      Uri.parse(r.url),
      tag: MediaItem(id: r.url, title: r.name, artist: "Radio Qur'an"),
    ));
    player.play();
  }

  // ------------------------------------------------------------------- control

  Future<void> seekToAyah(int ayahIndex) async {
    if (_mode != AudioMode.ayah || ayahIndex < 0) return;
    // [ayahIndex] is absolute (0-based within the surah), but the queue starts
    // at the ayah playback began from — so convert before seeking, or tapping a
    // verse would jump to the wrong one whenever playback started mid-surah.
    final queueIndex = ayahIndex - _queueAyahOffset;
    if (queueIndex < 0 || queueIndex >= _ayahQueueLength) return;
    _ayahIndex = ayahIndex;
    await player.seek(Duration.zero, index: queueIndex);
  }

  /// Jumps to a surah already in the queue (used by the "up next" list).
  Future<void> jumpToQueueIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    await player.seek(Duration.zero, index: index);
    player.play();
  }

  void setVerseRepeat(bool v) {
    _verseRepeat = v;
    _applyLoop();
  }

  void _applyLoop() {
    // Verse repeat only makes sense per-ayah; for surah queues it would loop
    // a single surah forever, which is never what the user wants.
    final loopOne = _verseRepeat && _mode == AudioMode.ayah;
    player.setLoopMode(loopOne ? LoopMode.one : LoopMode.off);
  }

  Future<void> togglePlay() async {
    if (player.playing) {
      await player.pause();
    } else {
      player.play();
    }
  }

  /// Advances within the queue. Returns false at the end of the queue.
  Future<bool> nextSurah() async {
    if (_mode == AudioMode.surah) {
      final p = player;
      if (p.hasNext) {
        await p.seekToNext();
        p.play();
        return true;
      }
      return false;
    }
    final n = _surah + 1;
    if (n > 114 || _ayahReciter == null) return false;
    await playAyahRecitation(reciter: _ayahReciter!, surahNumber: n);
    return true;
  }

  Future<bool> previousSurah() async {
    if (_mode == AudioMode.surah) {
      final p = player;
      if (p.hasPrevious) {
        await p.seekToPrevious();
        p.play();
        return true;
      }
      return false;
    }
    final n = _surah - 1;
    if (n < 1 || _ayahReciter == null) return false;
    await playAyahRecitation(reciter: _ayahReciter!, surahNumber: n);
    return true;
  }

  /// Rebuilds the current surah queue in random order, keeping the currently
  /// playing surah first so the music never stops.
  Future<void> shuffleQueue() async {
    if (_mode != AudioMode.surah || _queue.length < 2) return;
    final current = _surah;
    final rest = _queue.where((n) => n != current).toList()..shuffle(math.Random());
    final ordered = [current, ...rest];
    final reciter = _reciter;
    final moshaf = _moshaf;
    if (reciter == null || moshaf == null) return;
    await playShuffled(reciter: reciter, moshaf: moshaf, surahNumbers: ordered);
  }

  Future<void> stop() async {
    await player.stop();
    _title = '';
    _subtitle = '';
    _queue = const [];
    _ayahQueueLength = 0;
  }

  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;
  Stream<bool> get playingStream => player.playingStream;
  Stream<int?> get currentIndexStream => player.currentIndexStream;
  Stream<PlayerState> get playerStateStream => player.playerStateStream;
}
