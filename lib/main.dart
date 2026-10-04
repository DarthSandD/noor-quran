import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'theme/app_theme.dart';
import 'state/settings_provider.dart';
import 'state/qiblah_provider.dart';
import 'state/audio_provider.dart';
import 'data/repository.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/surah_list_screen.dart';
import 'screens/qiblah_screen.dart';
import 'screens/dua_screen.dart';
import 'screens/more_screen.dart';
import 'widgets/mini_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  await initializeDateFormatting('en', null);
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.darrenlieu.noor_quran.audio',
    androidNotificationChannelName: "Noor Qur'an playback",
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );
  await QuranRepository.instance.loadCore();
  runApp(const NoorApp());
}

class NoorApp extends StatelessWidget {
  const NoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
        ChangeNotifierProvider(create: (_) => QiblahProvider()..init()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          final mode = settings.systemTheme
              ? ThemeMode.system
              : (settings.dark ? ThemeMode.dark : ThemeMode.light);
          return MaterialApp(
            title: 'Noor Qur\'an',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: mode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _splashDone = false;

  /// Bumped once the extra bundles (duas, asma, reciters, radios) finish loading.
  /// It keys the tab pages so they are rebuilt with the freshly-loaded data:
  /// `const` pages are canonicalised to the same widget instance, so without a
  /// changing key Flutter would skip rebuilding them and the tabs would stay empty.
  int _dataVersion = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));
    _loadExtras();
  }

  Future<void> _loadExtras() async {
    await QuranRepository.instance.loadExtras();
    if (mounted) {
      setState(() => _dataVersion++);
      context.read<AudioProvider>().prime();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = Scaffold(
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );

    return AnimatedSwitcher(
      duration: Motion.slow,
      switchInCurve: Motion.curve,
      child: _splashDone
          ? KeyedSubtree(key: const ValueKey('shell'), child: shell)
          : SplashScreen(key: const ValueKey('splash'), onDone: () => setState(() => _splashDone = true)),
    );
  }
}
