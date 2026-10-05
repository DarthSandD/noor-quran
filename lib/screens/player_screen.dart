import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/models.dart';
import '../state/audio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/motion.dart';
import '../widgets/reciter_picker.dart';

class PlayerScreen extends StatefulWidget {
  final int? initialReciterId;
  const PlayerScreen({super.key, this.initialReciterId});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Grad.night),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  const Text('Sedang Diputar', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.more_horiz_rounded, color: Colors.white), onPressed: () {}),
                ],
              ),
              TabBar(
                controller: _tab,
                indicatorColor: AppColors.gold,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Murottal'),
                  Tab(text: 'YouTube'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tab,
                  children: [
                    _MurottalTab(audio: audio),
                    const _YouTubeTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MurottalTab extends StatelessWidget {
  final AudioProvider audio;
  const _MurottalTab({required this.audio});

  @override
  Widget build(BuildContext context) {
    final svc = audio.service;
    final surah = audio.currentSurahObj;
    final hasQueue = svc.title.isNotEmpty;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            children: [
              _Artwork(surah: surah, playing: audio.playing),
              const SizedBox(height: 28),
              Text(
                hasQueue ? svc.title : 'Pilih Murottal',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.4),
              ),
              const SizedBox(height: 6),
              Text(
                hasQueue ? svc.subtitle : 'Pilih qari untuk mulai memutar',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60, fontSize: 13.5),
              ),
              const SizedBox(height: 22),
              if (hasQueue) _Progress(audio: audio),
              if (hasQueue) const SizedBox(height: 6),
              if (hasQueue) _Controls(audio: audio),
              const SizedBox(height: 18),
              _Extras(audio: audio),
              const SizedBox(height: 10),
              if (surah != null && svc.mode.name == 'ayah') _AyahScrubber(audio: audio, surah: surah),
            ],
          ),
        ),
        if (hasQueue) _QueueBar(audio: audio),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  final Surah? surah;
  final bool playing;
  const _Artwork({required this.surah, required this.playing});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.94, end: 1.0),
        duration: Motion.slow,
        curve: Motion.curve,
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: AnimatedContainer(
          duration: Motion.slow,
          curve: Motion.curve,
          height: 248,
          width: 248,
          decoration: BoxDecoration(
            gradient: playing ? Grad.goldSheen : Grad.emerald,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: (playing ? AppColors.gold : AppColors.emerald).withValues(alpha: playing ? 0.5 : 0.4),
                blurRadius: playing ? 56 : 40,
                spreadRadius: playing ? 2 : 0,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -26,
                bottom: -30,
                child: Opacity(
                  opacity: 0.16,
                  child: NoorMark(size: 170, glow: false, color: playing ? AppColors.emeraldDeep : Colors.white),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Text(
                    surah?.name ?? '﷽',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      color: playing ? AppColors.emeraldDeep : Colors.white,
                      fontSize: 46,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final AudioProvider audio;
  const _Progress({required this.audio});
  @override
  Widget build(BuildContext context) {
    final dur = audio.duration ?? Duration.zero;
    final pos = audio.position;
    final max = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.gold,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: AppColors.gold.withValues(alpha: 0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: pos.inMilliseconds.clamp(0, max.toInt()).toDouble(),
            max: max,
            onChanged: (v) => audio.seek(Duration(milliseconds: v.toInt())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(pos), style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
              Text(_fmt(dur), style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _Controls extends StatelessWidget {
  final AudioProvider audio;
  const _Controls({required this.audio});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PressScale(
          scale: 0.88,
          onTap: audio.previous,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(width: 22),
        PressScale(
          scale: 0.9,
          onTap: audio.toggle,
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: Grad.goldSheen,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.emeraldDeep, size: 42),
          ),
        ),
        const SizedBox(width: 22),
        PressScale(
          scale: 0.88,
          onTap: audio.next,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 26),
          ),
        ),
      ],
    );
  }
}

class _Extras extends StatelessWidget {
  final AudioProvider audio;
  const _Extras({required this.audio});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Pill(
          icon: Icons.repeat_rounded,
          label: 'Ulang',
          active: audio.service.verseRepeat,
          onTap: () => audio.setVerseRepeat(!audio.service.verseRepeat),
        ),
        _Pill(
          icon: Icons.speed_rounded,
          label: _speedLabel(audio),
          active: audio.speed != 1.0,
          onTap: audio.cycleSpeed,
        ),
        _Pill(
          icon: Icons.headphones_rounded,
          label: 'Qari',
          active: false,
          onTap: () => showReciterPicker(context, startSurah: audio.service.currentSurah),
        ),
      ],
    );
  }

  static String _speedLabel(AudioProvider a) {
    final s = a.speed;
    return '${s.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}x';
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Pill({required this.icon, required this.label, required this.active, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: active ? AppColors.gold : Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: active ? AppColors.emeraldDeep : Colors.white, size: 20),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AyahScrubber extends StatelessWidget {
  final AudioProvider audio;
  final Surah surah;
  const _AyahScrubber({required this.audio, required this.surah});
  @override
  Widget build(BuildContext context) {
    final idx = audio.service.currentAyahIndex;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ayat ${idx + 1} dari ${surah.ayahCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 0; i < surah.ayahCount; i++)
                GestureDetector(
                  onTap: () => audio.seekToAyah(i),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == idx ? AppColors.gold : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text('${i + 1}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: i == idx ? AppColors.emeraldDeep : Colors.white70)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueueBar extends StatelessWidget {
  final AudioProvider audio;
  const _QueueBar({required this.audio});
  @override
  Widget build(BuildContext context) {
    final surah = audio.currentSurahObj;
    if (surah == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        children: [
          const Icon(Icons.queue_music_rounded, color: Colors.white54, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Surah ${surah.transliteration} • ${surah.ayahCount} ayat', style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _YouTubeTab extends StatefulWidget {
  const _YouTubeTab();
  @override
  State<_YouTubeTab> createState() => _YouTubeTabState();
}

class _YouTubeTabState extends State<_YouTubeTab> {
  YoutubePlayerController? _controller;
  String? _currentTitle;

  // Curated, freely-available Qur'an recitation videos on YouTube.
  static const _videos = [
    ('Surah Al-Fatihah', '7ZlRZ9EhF3o'),
    ('Surah Yasin', 'lHrx4B8wJgM'),
    ('Surah Ar-Rahman', 'x1iBcP9wZ6o'),
    ('Surah Al-Mulk', 'Y5Qm6q5Z3cU'),
    ('Surah Al-Kahfi', 'Fbc5tq3v5cY'),
    ('Surah Al-Waqiah', 'g1jR3C6L0zE'),
  ];

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  void _open(String id, String title) {
    setState(() {
      _controller?.close();
      _controller = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true, showControls: true, strictRelatedVideos: true),
      );
      _currentTitle = title;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        if (_controller != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.smart_display_rounded, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Text(_currentTitle ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
        ],
        const Text('Murottal di YouTube', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Putar rekaman qari lengkap langsung dari YouTube.', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
        const SizedBox(height: 14),
        for (final v in _videos)
          Card(
            color: Colors.white.withValues(alpha: 0.07),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () => _open(v.$2, v.$1),
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              ),
              title: Text(v.$1, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('YouTube • Ketuk untuk memutar', style: TextStyle(color: Colors.white38, fontSize: 11.5)),
              trailing: const Icon(Icons.open_in_new_rounded, color: Colors.white38, size: 18),
            ),
          ),
      ],
    );
  }
}
