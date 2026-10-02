import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../audio/audio_service.dart';
import '../data/repository.dart';
import '../models/models.dart';

/// UI-facing bridge over [AudioService]; exposes reactive playback state.
class AudioProvider extends ChangeNotifier {
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

  late final StreamSubscription _playSub;
  late final StreamSubscription _posSub;
  late final StreamSubscription _durSub;
  late final StreamSubscription _idxSub;
  late final StreamSubscription _stateSub;

  AudioProvider() {
    _playSub = _svc.playingStream.listen((v) {
      _playing = v;
      notifyListeners();
    });
    _posSub = _svc.positionStream.listen((v) {
      _position = v;
      notifyListeners();
    });
    _durSub = _svc.durationStream.listen((v) {
      _duration = v;
      notifyListeners();
    });
    _idxSub = _svc.currentIndexStream.listen((v) {
      _currentIndex = v;
      if (v != null) _svc.setCurrentIndexHint(v);
      notifyListeners();
    });
    _stateSub = _svc.playerStateStream.listen((s) {
      _buffering = s.processingState == ProcessingState.loading || s.processingState == ProcessingState.buffering;
      if (s.processingState == ProcessingState.completed && !_svc.verseRepeat) {
        // advance to next surah automatically at the end of the queue
        if (_svc.mode == AudioMode.ayah) _svc.nextSurah();
      }
      notifyListeners();
    });
  }

  void prime() {
    _svc.primeAyahReciters();
    notifyListeners();
  }

  Future<void> playSurah({required Reciter reciter, required Moshaf moshaf, required int surahNumber}) async {
    _error = null;
    try {
      await _svc.playSurah(reciter: reciter, moshaf: moshaf, surahNumber: surahNumber);
    } catch (e) {
      _error = 'Gagal memutar: ${e.toString().split('\n').first}';
      notifyListeners();
    }
  }

  Future<void> playAyahRecitation({required AyahReciter reciter, required int surahNumber, int fromAyah = 1}) async {
    _error = null;
    try {
      await _svc.playAyahRecitation(reciter: reciter, surahNumber: surahNumber, fromAyah: fromAyah);
    } catch (e) {
      _error = 'Gagal memutar: ${e.toString().split('\n').first}';
      notifyListeners();
    }
  }

  Future<void> playRadio(Radio r) async {
    _error = null;
    try {
      await _svc.playRadio(r);
    } catch (e) {
      _error = 'Gagal memutar radio: ${e.toString().split('\n').first}';
      notifyListeners();
    }
  }

  Future<void> toggle() => _svc.togglePlay();
  Future<void> next() => _svc.nextSurah();
  Future<void> previous() => _svc.previousSurah();
  Future<void> seek(Duration d) => _svc.player.seek(d);
  Future<void> seekToAyah(int i) => _svc.seekToAyah(i);
  Future<void> stop() => _svc.stop();

  void setVerseRepeat(bool v) {
    _svc.setVerseRepeat(v);
    notifyListeners();
  }

  Surah? get currentSurahObj =>
      _svc.currentSurah >= 1 && _svc.currentSurah <= 114 ? QuranRepository.instance.surah(_svc.currentSurah) : null;

  @override
  void dispose() {
    _playSub.cancel();
    _posSub.cancel();
    _durSub.cancel();
    _idxSub.cancel();
    _stateSub.cancel();
    super.dispose();
  }
}
