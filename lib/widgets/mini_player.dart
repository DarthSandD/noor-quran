import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/audio_provider.dart';
import '../theme/app_theme.dart';
import '../screens/player_screen.dart';

/// Compact now-playing bar that floats above the navigation bar.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final svc = audio.service;
    if (svc.title.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerScreen())),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: Grad.emeraldDeepBar,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(gradient: Grad.gold, borderRadius: BorderRadius.circular(13)),
                child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(svc.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Text(svc.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(audio.playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white),
                onPressed: audio.toggle,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                onPressed: audio.next,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}
