import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../data/repository.dart';
import '../state/qiblah_provider.dart';
import '../state/settings_provider.dart';

/// Where the app is in its start-up sequence.
enum BootStatus { loading, ready, failed }

/// Runs the heavy start-up work *inside* the widget tree.
///
/// The previous design awaited every dependency in `main()` before calling
/// `runApp()`, so a single slow or throwing step (locale data, the background
/// audio service, a 1.6 MB JSON parse) left the user on the launch screen with
/// no widget tree to show an error — and no way to recover.
///
/// Here instead:
///  * the first frame paints immediately;
///  * only the Qur'an bundle is fatal — every other step is optional;
///  * each step is bounded by a timeout, so start-up can never hang;
///  * progress is real, so the splash tells the truth.
class BootstrapController extends ChangeNotifier {
  BootStatus _status = BootStatus.loading;
  BootStatus get status => _status;

  double _progress = 0.0;
  double get progress => _progress;

  String _label = 'Menyiapkan…';
  String get label => _label;

  Object? _error;
  String get errorMessage =>
      _error == null ? 'Terjadi kesalahan yang tidak terduga.' : _error.toString();

  SettingsProvider? _settings;
  QiblahProvider? _qiblah;
  bool _running = false;

  Future<void> start({
    required SettingsProvider settings,
    required QiblahProvider qiblah,
  }) {
    _settings = settings;
    _qiblah = qiblah;
    return _run();
  }

  Future<void> retry() => _run();

  Future<void> _run() async {
    if (_running) return;
    _running = true;
    _status = BootStatus.loading;
    _error = null;
    _progress = 0;
    _label = 'Menyiapkan…';
    notifyListeners();

    final clock = Stopwatch()..start();
    try {
      // The one dependency the app cannot run without.
      _report(0.15, 'Memuat Al-Qur\'an…');
      await QuranRepository.instance.loadCore().timeout(const Duration(seconds: 45));

      // Everything below is optional: a failure is logged and skipped.
      _report(0.60, 'Memuat preferensi…');
      await _soft(_settings!.init, const Duration(seconds: 10));

      _report(0.74, 'Menyiapkan bahasa…');
      await _soft(() => initializeDateFormatting('id', null), const Duration(seconds: 12));
      await _soft(() => initializeDateFormatting('en', null), const Duration(seconds: 12));

      _report(0.88, 'Menyiapkan kiblat…');
      await _soft(_qiblah!.init, const Duration(seconds: 10));

      _report(0.96, 'Hampir siap…');
      // The reciter list arrives with the optional bundles, so priming happens
      // in the shell once those land — see AppShell._warmExtras.

      // Hold the splash just long enough to read — never longer.
      const minSplash = Duration(milliseconds: 900);
      if (clock.elapsed < minSplash) {
        await Future<void>.delayed(minSplash - clock.elapsed);
      }

      _report(1.0, 'Siap');
      _status = BootStatus.ready;
    } catch (e, s) {
      debugPrint('Noor: bootstrap failed — $e\n$s');
      _error = e;
      _status = BootStatus.failed;
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  /// Awaits a non-critical step, bounded by [timeout]; never throws.
  Future<void> _soft(Future<void> Function() body, Duration timeout) async {
    try {
      await body().timeout(timeout);
    } catch (e) {
      debugPrint('Noor: non-critical start-up step failed — $e');
    }
  }

  void _report(double progress, String label) {
    _progress = progress;
    _label = label;
    notifyListeners();
  }
}
