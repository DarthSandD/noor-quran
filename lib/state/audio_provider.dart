import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../audio/audio_service.dart';
import '../data/repository.dart';
import '../models/models.dart';

/// UI-facing bridge over [AudioService]; exposes reactive playback state.
///
/// Construction is cheap and safe: the player is not touched until
/// [audioBackgroundReady] completes, because `just_audio_background` requires
/// its `init()` to finish before the first [AudioPlayer] exists.
class AudioProvider extends ChangeNotifier {
  AudioProvider(this._ready);

  final Future<void> _ready;
  final AudioService _svc = AudioService.instance;
  AudioService get service => _svc;

  bool _playing = false;
  bool get playing => _playing;

  Duration _position = Duration.zero;
  Duration get position => _position;

  Duration? _duration;
  Duration? get duration => _duration;

  int? _currentIndex;
  int? get currentIndex => _currentIndex;

  bool _buffering = false;
  bool get buffering => _buffering;

  String? _error;
  String? get error => _error;

  final List<StreamSubscription<dynamic>> _subs = [];
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  /// Attaches to the player once the background service is ready.
  /// Called by [prime]; idempotent.
  bool _attached = false;
  Future<void> _attach() async {
    if (_attached) return;
    await _ready;
    if (_disposed) return;
    _attached = true;
    _svc.player; // force creation now that init() has completed

    _subs.addAll([
      _svc.playingStream.listen((v) => _set(() => _playing = v)),
      _svc.positionStream.listen((v) => _set(() => _position = v)),
      _svc.durationStream.listen((v) => _set(() => _duration = v)),
      _svc.currentIndexStream.listen((v) {
        _currentIndex = v;
        if (v != null) _svc.setCurrentIndexHint(v);
        if (!_disposed) notifyListeners();
      }),
      _svc.playerStateStream.listen((s) {
        _buffering = s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering;
        // A completed queue item is handled by just_audio's own advance for
        // surah queues; only ayah mode needs an explicit push to the next surah.
        if (s.processingState == ProcessingState.completed && !_svc.verseRepeat) {
          if (_svc.mode == AudioMode.ayah && !(_svc.playerIfCreated?.hasNext ?? false)) {
            _svc.nextSurah();
          }
        }
        if (!_disposed) notifyListeners();
      }),
    ]);
  }

  void _set(void Function() mutate) {
    mutate();
    if (!_disposed) notifyListeners();
  }

  /// Called once the optional bundles (and therefore the reciter list) land.
  Future<void> prime() async {
    await _attach();
    _svc.primeAyahReciters();
    if (!_disposed) notifyListeners();
  }

  // ------------------------------------------------------------------ playback

  Future<void> playSurah({
    required Reciter reciter,
    required Moshaf moshaf,
    required int surahNumber,
    bool single = false,
  }) async {
    _error = null;
    try {
      await _attach();
      await _svc.playSurah(
        reciter: reciter,
        moshaf: moshaf,
        surahNumber: surahNumber,
        single: single,
      );
    } catch (e) {
      _error = 'Gagal memutar: ${e.toString().split('\n').first}';
      if (!_disposed) notifyListeners();
    }
  }

  /// Spotify's "play album": the whole reciter catalogue, from Al-Fatihah.
  Future<void> playAll({required Reciter reciter, required Moshaf moshaf}) async {
    _error = null;
    try {
      await _attach();
      await _svc.playAll(reciter: reciter, moshaf: moshaf);
    } catch (e) {
      _error = 'Gagal memutar: ${e.toString().split('\n').first}';
      if (!_disposed) notifyListeners();
    }
  }

  /// Plays a pre-shuffled run of surahs (see [AudioService.playShuffled]).
  Future<void> playShuffled({
    required Reciter reciter,
    required Moshaf moshaf,
    required List<int> surahNumbers,
  }) async {
    _error = null;
    try {
      await _attach();
      await _svc.playShuffled(reciter: reciter, moshaf: moshaf, surahNumbers: surahNumbers);
    } catch (e) {
      _error = 'Gagal memutar: ${e.toString().split('\n').first}';
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> playAyahRecitation({
    required AyahReciter reciter,
    required int surahNumber,
    int fromAyah = 1,
  }) async {
    _error = null;
    try {
      await _attach();
      await _svc.playAyahRecitation(reciter: reciter, surahNumber: surahNumber, fromAyah: fromAyah);
    } catch (e) {
      _error = 'Gagal memutar: ${e.toString().split('\n').first}';
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> playRadio(Radio r) async {
    _error = null;
    try {
      await _attach();
      await _svc.playRadio(r);
    } catch (e) {
      _error = 'Gagal memutar radio: ${e.toString().split('\n').first}';
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> toggle() async {
    await _attach();
    await _svc.togglePlay();
  }

  Future<void> next() async {
    await _attach();
    await _svc.nextSurah();
  }

  Future<void> previous() async {
    await _attach();
    await _svc.previousSurah();
  }

  Future<void> seek(Duration d) async {
    await _attach();
    await _svc.player.seek(d);
  }

  Future<void> seekToAyah(int i) async {
    await _attach();
    await _svc.seekToAyah(i);
  }

  Future<void> jumpToQueueIndex(int index) async {
    await _attach();
    await _svc.jumpToQueueIndex(index);
  }

  Future<void> stop() async {
    await _attach();
    await _svc.stop();
  }

  /// Rebuilds the current queue in random order (current surah stays first).
  Future<void> shuffleQueue() async {
    await _attach();
    await _svc.shuffleQueue();
    if (!_disposed) notifyListeners();
  }

  void setVerseRepeat(bool v) {
    _svc.setVerseRepeat(v);
    if (!_disposed) notifyListeners();
  }

  /// Playback speed. Reads the player only once it exists.
  double get speed => _svc.playerIfCreated?.speed ?? 1.0;

  Future<void> cycleSpeed() async {
    const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    await _attach();
    final cur = _svc.player.speed;
    final i = speeds.indexOf(cur);
    await _svc.player.setSpeed(speeds[(i + 1) % speeds.length]);
    if (!_disposed) notifyListeners();
  }

  // -------------------------------------------------------------------- queue

  /// The surahs queued after the current one (the "Berikutnya" list).
  List<Surah> get upNext {
    final q = _svc.queue;
    if (q.isEmpty) return const [];
    final i = _svc.queueIndex;
    if (i < 0) return const [];
    final repo = QuranRepository.instance;
    return [
      for (var k = i + 1; k < q.length; k++) repo.surah(q[k]),
    ];
  }

  /// How many items remain after the current one.
  int get upNextCount => upNext.length;

  bool get hasNext => _svc.playerIfCreated?.hasNext ?? false;
  bool get hasPrevious => _svc.playerIfCreated?.hasPrevious ?? false;

  Surah? get currentSurahObj {
    final n = _svc.currentSurah;
    return n >= 1 && n <= 114 ? QuranRepository.instance.surah(n) : null;
  }
}
