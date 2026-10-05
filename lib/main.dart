import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'app/app_error.dart';
import 'app/boot_gate.dart';
import 'app/bootstrap.dart';
import 'state/audio_provider.dart';
import 'state/qiblah_provider.dart';
import 'state/settings_provider.dart';
import 'theme/app_theme.dart';

/// Entry point.
///
/// The rule here is: **nothing may block the first frame**. `runApp` is called
/// immediately, so the user always sees the branded splash rather than a frozen
/// native launch screen.
///
/// The one ordering constraint is that `just_audio_background` must be
/// initialised before the first `AudioPlayer` is constructed (the player is
/// created when the provider tree builds). That init is therefore kicked off
/// now, but it is platform-guarded (it is a mobile-only plugin), bounded by a
/// timeout, and cannot throw — see [_initAudioBackground].
///
/// All the genuinely slow work — the 1.6 MB Qur'an bundle, preferences, locale
/// data, the compass — runs *inside* the tree, off the UI isolate where possible,
/// with real progress and a recoverable error screen. See [BootstrapController].
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppErrorHandlers.install();
  runApp(const NoorApp());
}

/// Initialises the background-audio service, in parallel with the first frame.
///
/// * Skipped entirely on web, where the plugin is unsupported.
/// * Bounded by a timeout, so a wedged platform channel cannot hang start-up.
/// * Never throws — if it fails, playback simply runs without a notification.
///
/// [AudioProvider] awaits this before constructing its player, so the ordering
/// contract is upheld without delaying `runApp`.
final Future<void> audioBackgroundReady = _initAudioBackground();

Future<void> _initAudioBackground() async {
  if (kIsWeb) return;
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.darrenlieu.noor_quran.audio',
      androidNotificationChannelName: "Noor Qur'an playback",
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ).timeout(const Duration(seconds: 15));
  } catch (e) {
    debugPrint('Noor: background audio unavailable — $e');
  }
}

class NoorApp extends StatelessWidget {
  const NoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => QiblahProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider(audioBackgroundReady)),
        ChangeNotifierProvider(
          create: (ctx) => BootstrapController()
            ..start(
              settings: ctx.read<SettingsProvider>(),
              qiblah: ctx.read<QiblahProvider>(),
            ),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final mode = settings.systemTheme
              ? ThemeMode.system
              : (settings.dark ? ThemeMode.dark : ThemeMode.light);
          return MaterialApp(
            title: "Noor Qur'an",
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            home: const BootstrapGate(),
          );
        },
      ),
    );
  }
}
