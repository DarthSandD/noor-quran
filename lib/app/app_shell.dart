import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../data/repository.dart';
import '../screens/dua_screen.dart';
import '../screens/home_screen.dart';
import '../screens/more_screen.dart';
import '../screens/qiblah_screen.dart';
import '../screens/surah_list_screen.dart';
import '../state/audio_provider.dart';
import '../state/settings_provider.dart';
import '../widgets/mini_player.dart';

/// Lets any descendant jump to a top-level tab.
///
/// The five tab pages are plain bodies with no `Scaffold`, so pushing them as
/// routes (as the Home shortcuts used to do) produced a screen with **no back
/// button**. Switching tabs is the correct behaviour for those shortcuts.
class ShellTabs extends InheritedWidget {
  const ShellTabs({super.key, required this.select, required super.child});

  final void Function(int index) select;

  /// Tab indices, so callers do not have to hard-code magic numbers.
  static const int home = 0;
  static const int quran = 1;
  static const int qiblah = 2;
  static const int dua = 3;
  static const int more = 4;

  /// Looks up the nearest shell.
  ///
  /// Uses `getInheritedWidgetOfExactType` (not `dependOn…`) because this is
  /// called from tap handlers, not `build` — it must not register a dependency
  /// or assert if the caller is being torn down.
  static ShellTabs? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ShellTabs>();

  @override
  bool updateShouldNotify(ShellTabs oldWidget) => select != oldWidget.select;
}

/// The five-tab shell.
///
/// The five pages are kept alive in an [IndexedStack] so switching tabs is
/// instant and scroll positions survive. The non-critical data bundles are
/// fetched *after* the first frame and applied through a version key, so the
/// first paint never waits on them.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// Bumped once the optional bundles (duas, asma, reciters, radios) arrive.
  ///
  /// It keys the tab pages so they rebuild with the freshly-loaded data: the
  /// pages are `const`, so Flutter canonicalises them to the same instance and
  /// would otherwise skip the rebuild, leaving the tabs empty.
  int _dataVersion = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
    _warmExtras();
  }

  @override
  void dispose() {
    // Never leave the screen pinned on after the shell goes away.
    _setWakelock(false);
    super.dispose();
  }

  /// Last wake-lock state we asked the platform for, so we only call across the
  /// platform channel when the answer actually changes.
  bool? _wakelockOn;

  void _setWakelock(bool on) {
    if (_wakelockOn == on) return;
    _wakelockOn = on;
    try {
      if (on) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    } catch (e) {
      // Unsupported platform or blocked by the browser: not fatal.
      debugPrint('Noor: wakelock unavailable — $e');
    }
  }

  /// Applies the "layar tetap menyala" preference.
  ///
  /// The screen is kept awake only while something is actually playing, so the
  /// setting has a visible effect without draining the battery on idle screens.
  void _syncWakelock() {
    final keepOn = context.read<SettingsProvider>().keepScreenOn;
    final audio = context.read<AudioProvider>();
    final playing = audio.playing && audio.service.title.isNotEmpty;
    _setWakelock(keepOn && playing);
  }

  Future<void> _warmExtras() async {
    try {
      await QuranRepository.instance.loadExtras();
    } catch (e) {
      // Optional data: the app is fully usable without it.
      debugPrint('Noor: extras failed to load — $e');
    }
    if (!mounted) return;
    // Reciters arrive with the extras, so prime the player now.
    context.read<AudioProvider>().prime();
    setState(() => _dataVersion++);
  }

  @override
  Widget build(BuildContext context) {
    // Re-evaluate the wake lock whenever playback or the preference changes.
    context.watch<AudioProvider>();
    context.watch<SettingsProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncWakelock();
    });

    return ShellTabs(
      select: (i) => setState(() => _index = i),
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _index,
              children: [
                KeyedSubtree(key: ValueKey('home$_dataVersion'), child: const HomeScreen()),
                KeyedSubtree(key: ValueKey('surah$_dataVersion'), child: const SurahListScreen()),
                KeyedSubtree(key: ValueKey('qiblah$_dataVersion'), child: const QiblahScreen()),
                KeyedSubtree(key: ValueKey('dua$_dataVersion'), child: const DuaScreen()),
                KeyedSubtree(key: ValueKey('more$_dataVersion'), child: const MoreScreen()),
              ],
            ),
            const Positioned(left: 0, right: 0, bottom: 0, child: MiniPlayer()),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Beranda'),
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: "Qur'an"),
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded), label: 'Kiblat'),
            NavigationDestination(icon: Icon(Icons.favorite_outline_rounded), selectedIcon: Icon(Icons.favorite_rounded), label: 'Doa'),
            NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view_rounded), label: 'Lainnya'),
          ],
        ),
      ),
    );
  }
}
