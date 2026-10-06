import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../data/youtube_library.dart';
import '../audio/audio_service.dart';
import '../models/models.dart';
import '../state/audio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/artwork.dart';
import '../widgets/motion.dart';

/// The now-playing screen.
///
/// Deliberately shaped like the music player everyone already knows: full-bleed
/// artwork, a colour wash pulled from that artwork, one huge white play button,
/// and the queue a tap away. The Qur'an content changes; the interaction
/// vocabulary does not have to be learned again.
class PlayerScreen extends StatefulWidget {
  final int? initialReciterId;
  const PlayerScreen({super.key, this.initialReciterId});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  /// Drag-to-dismiss progress (0 = fully open, 1 = dismissed).
  double _drag = 0;

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final surahNumber = audio.currentSurahObj?.number ?? 1;

    return Scaffold(
      backgroundColor: const Color(0xFF050A09),
      body: GestureDetector(
        onVerticalDragUpdate: (d) => setState(() {
          _drag = (_drag + d.delta.dy / 420).clamp(0.0, 1.0);
        }),
        onVerticalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (_drag > 0.26 || v > 700) {
            Navigator.pop(context);
          } else {
            setState(() => _drag = 0);
          }
        },
        child: Transform.translate(
          offset: Offset(0, _drag * 300),
          child: Transform.scale(
            scale: 1 - _drag * 0.06,
            child: Stack(
              children: [
                _Wash(surahNumber: surahNumber),
                SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      _TopBar(onClose: () => Navigator.pop(context)),
                      _Tabs(controller: _tab),
                      Expanded(
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            _NowPlaying(audio: audio),
                            const _YouTubeTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-bleed colour wash derived from the current surah's artwork, fading to
/// near-black at the bottom so the controls sit on a calm surface.
class _Wash extends StatelessWidget {
  const _Wash({required this.surahNumber});
  final int surahNumber;

  @override
  Widget build(BuildContext context) {
    final palette = paletteFor(surahNumber);
    return AnimatedContainer(
      duration: Motion.slow,
      curve: Motion.curve,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.mid,
            Color.lerp(palette.deep, const Color(0xFF050A09), 0.5)!,
            const Color(0xFF050A09),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.9),
            radius: 1.15,
            colors: [palette.glow.withValues(alpha: 0.42), Colors.transparent],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30),
            onPressed: onClose,
            tooltip: 'Tutup',
          ),
          const Spacer(),
          const Text(
            'SEDANG DIPUTAR',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 10.5, letterSpacing: 1.6),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded, color: Colors.white),
            onPressed: () {},
            tooltip: 'Opsi',
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      indicatorColor: Colors.white,
      indicatorSize: TabBarIndicatorSize.label,
      indicatorWeight: 2.5,
      dividerColor: Colors.transparent,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white38,
      labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, letterSpacing: 0.3),
      unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      tabs: const [Tab(text: 'Murottal'), Tab(text: 'YouTube')],
    );
  }
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.audio});
  final AudioProvider audio;

  @override
  Widget build(BuildContext context) {
    final svc = audio.service;
    final surah = audio.currentSurahObj;
    final hasQueue = svc.title.isNotEmpty;
    final isRadio = svc.mode == AudioMode.radio;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        _Art(surah: surah, playing: audio.playing, radioName: isRadio ? svc.title : null),
        const SizedBox(height: 28),
        _TitleRow(audio: audio, hasQueue: hasQueue),
        if (hasQueue) ...[
          const SizedBox(height: 18),
          // A live stream has no duration: show the LIVE equalizer ribbon
          // instead of a scrubber that could never move.
          if (isRadio)
            _RadioRibbon(playing: audio.playing, palette: paletteFor(1))
          else ...[
            _Progress(audio: audio),
            const SizedBox(height: 10),
            _Controls(audio: audio),
          ],
          const SizedBox(height: 16),
          _BottomRow(audio: audio),
          if (surah != null && svc.mode.name == 'ayah') ...[
            const SizedBox(height: 18),
            _AyahScrubber(audio: audio, surah: surah),
          ],
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 44),
            child: Text(
              'Pilih qari dari pustaka Murottal untuk mulai memutar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13.5, height: 1.5),
            ),
          ),
      ],
    );
  }
}

/// The LIVE ribbon shown on the player while a radio station streams.
class _RadioRibbon extends StatelessWidget {
  const _RadioRibbon({required this.playing, required this.palette});
  final bool playing;
  final ArtPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: const Color(0xFFFF3B5C).withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFFF3B5C).withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PulseDot(size: 8, color: const Color(0xFFFF3B5C)),
              const SizedBox(width: 9),
              Text(
                playing ? 'SEDANG LIVE' : 'LIVE DIJEDA',
                style: const TextStyle(color: Color(0xFFFF8FA3), fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        // The equalizer ribbon itself — the "audio is flowing" signal.
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 34,
            child: EqualizerBars(active: playing, color: palette.accent, bars: 44, height: 34, barWidth: 4),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_tethering_rounded, size: 15, color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 6),
            Text('Streaming langsung • tanpa batas waktu', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}

/// Large square artwork with a deep shadow — the visual anchor of the screen.
///
/// For a radio station there is no surah to draw, so it renders a broadcast
/// tile in the station's own colour with a radiating-signal motif.
class _Art extends StatelessWidget {
  const _Art({required this.surah, required this.playing, this.radioName});
  final Surah? surah;
  final bool playing;
  final String? radioName;

  @override
  Widget build(BuildContext context) {
    final isRadio = radioName != null;
    final n = surah?.number ?? 1;
    final palette = isRadio ? _radioPalette(radioName!) : paletteFor(n);

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.9, end: 1.0),
        duration: Motion.slow,
        curve: Motion.curve,
        builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
        child: AnimatedContainer(
          duration: Motion.slow,
          curve: Motion.curve,
          width: 296,
          height: 296,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: palette.glow.withValues(alpha: playing ? 0.5 : 0.32),
                blurRadius: playing ? 58 : 40,
                spreadRadius: playing ? 2 : 0,
                offset: const Offset(0, 22),
              ),
              const BoxShadow(color: Colors.black54, blurRadius: 30, offset: Offset(0, 14)),
            ],
          ),
          child: isRadio
              ? _RadioArt(palette: palette, name: radioName!, playing: playing)
              : Hero(
                  tag: 'art-$n',
                  child: SurahArt(
                    number: n,
                    juz: surah?.ayahs.first.juz,
                    radius: 24,
                    label: surah?.name,
                    showNumber: false,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Broadcast tile shown in place of surah art while a radio station plays.
class _RadioArt extends StatelessWidget {
  const _RadioArt({required this.palette, required this.name, required this.playing});
  final ArtPalette palette;
  final String name;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.deep, palette.mid, palette.glow],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _SignalPainter(color: palette.accent)),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: const Icon(Icons.radio_rounded, color: Colors.white, size: 46),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    name,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3, height: 1.25),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulseDot(size: 7, color: Colors.white),
                      const SizedBox(width: 7),
                      Text(playing ? 'LIVE' : 'PAUSED', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 1.6)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Concentric radiating arcs — a broadcast motif for the radio art.
class _SignalPainter extends CustomPainter {
  _SignalPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(c, size.width * 0.13 * i, paint);
    }
  }

  @override
  bool shouldRepaint(_SignalPainter old) => old.color != color;
}

/// Deterministic palette for a radio station, seeded by its name.
ArtPalette _radioPalette(String name) {
  var h = 0;
  for (final c in name.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return kArtPalettes[h % kArtPalettes.length];
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.audio, required this.hasQueue});
  final AudioProvider audio;
  final bool hasQueue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasQueue ? audio.service.title : 'Belum ada yang diputar',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 5),
              Text(
                hasQueue ? audio.service.subtitle : 'Pustaka Murottal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.62), fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        if (hasQueue) ...[
          const SizedBox(width: 10),
          _SpeedChip(audio: audio),
        ],
      ],
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({required this.audio});
  final AudioProvider audio;

  static String _label(double s) =>
      '${s.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}×';

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: audio.cycleSpeed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Text(
          _label(audio.speed),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12.5),
        ),
      ),
    );
  }
}

class _Progress extends StatefulWidget {
  const _Progress({required this.audio});
  final AudioProvider audio;

  @override
  State<_Progress> createState() => _ProgressState();
}

class _ProgressState extends State<_Progress> {
  double? _scrub;

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final dur = widget.audio.duration ?? Duration.zero;
    final pos = widget.audio.position;
    final max = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
    final value = (_scrub ?? pos.inMilliseconds.toDouble()).clamp(0.0, max);

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: Colors.white.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value,
            max: max,
            onChanged: (v) => setState(() => _scrub = v),
            onChangeEnd: (v) {
              widget.audio.seek(Duration(milliseconds: v.toInt()));
              setState(() => _scrub = null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(Duration(milliseconds: value.toInt())), style: const TextStyle(color: Colors.white60, fontSize: 11.5, fontWeight: FontWeight.w600)),
              Text(_fmt(dur), style: const TextStyle(color: Colors.white60, fontSize: 11.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shuffle · previous · PLAY · next · repeat — the canonical transport row.
class _Controls extends StatelessWidget {
  const _Controls({required this.audio});
  final AudioProvider audio;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _IconBtn(
          icon: Icons.shuffle_rounded,
          size: 24,
          enabled: audio.upNextCount > 1,
          onTap: () {
            audio.shuffleQueue();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Antrean diacak')),
            );
          },
        ),
        _IconBtn(icon: Icons.skip_previous_rounded, size: 38, enabled: audio.hasPrevious, onTap: audio.previous),
        _PlayButton(audio: audio),
        _IconBtn(icon: Icons.skip_next_rounded, size: 38, enabled: audio.hasNext, onTap: audio.next),
        _IconBtn(
          icon: audio.service.verseRepeat ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          size: 24,
          active: audio.service.verseRepeat,
          onTap: () => audio.setVerseRepeat(!audio.service.verseRepeat),
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.size, this.onTap, this.enabled = true, this.active = false});
  final IconData icon;
  final double size;
  final VoidCallback? onTap;
  final bool enabled;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.goldSoft : (enabled ? Colors.white : Colors.white24);
    return PressScale(
      scale: 0.88,
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.audio});
  final AudioProvider audio;

  @override
  Widget build(BuildContext context) {
    final busy = audio.buffering;
    return PressScale(
      scale: 0.93,
      onTap: audio.toggle,
      child: Container(
        width: 72,
        height: 72,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: busy && !audio.playing
            ? const Padding(
                padding: EdgeInsets.all(22),
                child: CircularProgressIndicator(strokeWidth: 2.6, color: Colors.black),
              )
            : Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black, size: 40),
      ),
    );
  }
}

class _BottomRow extends StatelessWidget {
  const _BottomRow({required this.audio});
  final AudioProvider audio;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.speed_rounded, color: Colors.white70, size: 22),
          tooltip: 'Kecepatan',
          onPressed: audio.cycleSpeed,
        ),
        TextButton.icon(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.nightSurface,
            builder: (_) => _QueueSheet(audio: audio),
          ),
          icon: const Icon(Icons.queue_music_rounded, color: Colors.white70, size: 20),
          label: Text(
            audio.upNextCount > 0 ? 'Antrean · ${audio.upNextCount}' : 'Antrean',
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.volume_up_rounded, color: Colors.white70, size: 22),
          tooltip: 'Volume',
          onPressed: () {},
        ),
      ],
    );
  }
}

/// "Berikutnya" — the rest of the queue, tap to jump.
class _QueueSheet extends StatelessWidget {
  const _QueueSheet({required this.audio});
  final AudioProvider audio;

  @override
  Widget build(BuildContext context) {
    final upNext = audio.upNext;
    final current = audio.currentSurahObj;
    final baseIndex = audio.service.queueIndex + 1;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      maxChildSize: 0.92,
      builder: (context, controller) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Berikutnya', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
            ),
          ),
          if (current != null)
            ListTile(
              leading: SizedBox(width: 44, height: 44, child: SurahArt(number: current.number, radius: 10, showNumber: false)),
              title: Text('Surah ${current.transliteration}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              subtitle: const Text('Sedang diputar', style: TextStyle(fontSize: 11.5, color: AppColors.goldSoft)),
            ),
          const Divider(height: 1, color: Colors.white12),
          Expanded(
            child: upNext.isEmpty
                ? const Center(child: Text('Tidak ada antrean berikutnya', style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    controller: controller,
                    itemCount: upNext.length,
                    itemBuilder: (_, i) {
                      final s = upNext[i];
                      return ListTile(
                        leading: SizedBox(width: 44, height: 44, child: SurahArt(number: s.number, radius: 10, showNumber: false)),
                        title: Text(s.transliteration, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: Text('${s.ayahCount} ayat • surah ${s.number}', style: const TextStyle(fontSize: 11, color: Colors.white38)),
                        onTap: () {
                          Navigator.pop(context);
                          audio.jumpToQueueIndex(baseIndex + i);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Verse grid for ayah-by-ayah recitation.
class _AyahScrubber extends StatelessWidget {
  const _AyahScrubber({required this.audio, required this.surah});
  final AudioProvider audio;
  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final idx = audio.service.currentAyahIndex;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ayat ${idx + 1} dari ${surah.ayahCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
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
                      color: i == idx ? Colors.white : Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: i == idx ? Colors.black : Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// YouTube murottal
// ---------------------------------------------------------------------------

class _YouTubeTab extends StatefulWidget {
  const _YouTubeTab();
  @override
  State<_YouTubeTab> createState() => _YouTubeTabState();
}

class _YouTubeTabState extends State<_YouTubeTab> {
  YoutubePlayerController? _controller;
  String? _currentTitle;
  bool _isPlaylist = false;

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  /// Opens a single video, embedded.
  void _openVideo(YoutubeClip c) {
    setState(() {
      _controller?.close();
      _controller = YoutubePlayerController.fromVideoId(
        videoId: c.videoId,
        autoPlay: true,
        params: const YoutubePlayerParams(showFullscreenButton: true, showControls: true, strictRelatedVideos: true),
      );
      _currentTitle = c.title;
      _isPlaylist = false;
    });
  }

  /// Opens a playlist, embedded — it advances continuously inside the app,
  /// which is the YouTube equivalent of "play album".
  Future<void> _openPlaylist(YoutubeClip c) async {
    final old = _controller;
    final controller = YoutubePlayerController(
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        strictRelatedVideos: true,
        loop: true,
      ),
    );
    setState(() {
      _controller = controller;
      _currentTitle = c.title;
      _isPlaylist = true;
    });
    old?.close();
    await controller.loadPlaylist(list: [c.videoId], listType: ListType.playlist, index: 0);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        // The embedded player sits at the top and stays while you browse.
        if (_controller != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: YoutubePlayer(controller: _controller!, aspectRatio: 16 / 9),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(_isPlaylist ? Icons.playlist_play_rounded : Icons.smart_display_rounded, color: Colors.white54, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_currentTitle ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        const Text('Putar lengkap', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        const Text('Bersambung otomatis — seperti memutar album.', style: TextStyle(color: Colors.white54, fontSize: 12.5)),
        const SizedBox(height: 12),
        for (final c in YoutubeLibrary.playlists)
          _YtTile(clip: c, badge: Icons.playlist_play_rounded, onTap: () => _openPlaylist(c)),

        const SizedBox(height: 22),
        const Text('Rekomendasi', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        for (final c in YoutubeLibrary.clips)
          _YtTile(clip: c, badge: Icons.play_arrow_rounded, onTap: () => _openVideo(c)),
      ],
    );
  }
}

class _YtTile extends StatelessWidget {
  const _YtTile({required this.clip, required this.badge, required this.onTap});
  final YoutubeClip clip;
  final IconData badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFFF4B4B), Color(0xFFB3121B)]),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(badge, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(clip.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.25)),
                  const SizedBox(height: 2),
                  Text(clip.channel, style: const TextStyle(color: Colors.white38, fontSize: 11.5)),
                ],
              ),
            ),
            const Icon(Icons.play_circle_fill_rounded, color: Colors.white38, size: 24),
          ],
        ),
      ),
    );
  }
}
