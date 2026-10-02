import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/repository.dart';
import '../state/audio_provider.dart';
import '../theme/app_theme.dart';

class RadioScreen extends StatelessWidget {
  const RadioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final radios = QuranRepository.instance.radios;
    final audio = context.watch<AudioProvider>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Radio Qur\'an')),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(gradient: Grad.emerald, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.radio_rounded, color: Colors.white, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Radio Murottal Live', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('${radios.length} stasiun streaming 24 jam', style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              itemCount: radios.length,
              itemBuilder: (_, i) {
                final r = radios[i];
                final isCurrent = audio.service.radio?.id == r.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (isCurrent ? AppColors.gold : theme.colorScheme.primary).withValues(alpha: 0.15),
                      child: Icon(Icons.radio_rounded, color: isCurrent ? AppColors.gold : theme.colorScheme.primary, size: 20),
                    ),
                    title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: const Text('Live streaming', style: TextStyle(fontSize: 11.5)),
                    trailing: Icon(isCurrent && audio.playing ? Icons.equalizer_rounded : Icons.play_circle_fill_rounded, color: theme.colorScheme.primary),
                    onTap: () => audio.playRadio(r),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
