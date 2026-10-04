import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/audio_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';
import '../screens/player_screen.dart';

/// Compact now-playing bar that floats above the navigation bar. Shows live
/// progress and animates in/out as playback starts and stops.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final svc = audio.service;
    final visible = svc.title.isNotEmpty;

    return AnimatedSlide(
      duration: Motion.med,
      curve: Motion.curve,
      offset: visible ? Offset.zero : const Offset(0, 1.4),
      child: AnimatedOpacity(
        duration: Motion.med,
        opacity: visible ? 1 : 0,
        child: visible ? _bar(context, audio) : const SizedBox(height: 0),
      ),
    );
  }

  Widget _bar(BuildContext context, AudioProvider audio) {
    final svc = audio.service;
    final dur = audio.duration;
    final pos = audio.position;
    final progress = (dur != null && dur.inMilliseconds > 0)
        ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: PressScale(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen())),
        child: Container(
          decoration: BoxDecoration(
            gradient: Grad.emeraldSoft,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(gradient: Grad.goldSheen, borderRadius: BorderRadius.circular(13)),
                        child: const Icon(Icons.music_note_rounded, color: AppColors.emeraldDeep, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(svc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5, letterSpacing: -0.1)),
                            Text(svc.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11.5, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
                        onPressed: audio.toggle,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24),
                        onPressed: audio.next,
                      ),
                    ],
                  ),
                ),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.5,
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  valueColor: const AlwaysStoppedAnimation(AppColors.goldSoft),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
