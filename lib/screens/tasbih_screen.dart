import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';

class TasbihScreen extends StatelessWidget {
  const TasbihScreen({super.key});

  static const _phrases = [
    'سُبْحَانَ اللّٰهِ',
    'اَلْحَمْدُ لِلّٰهِ',
    'اَللّٰهُ أَكْبَرُ',
    'لَا إِلٰهَ إِلَّا اللّٰهُ',
    'أَسْتَغْفِرُ اللّٰهَ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ',
  ];

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final idx = (s.tasbihTarget == 33 ? 0 : s.tasbihTarget == 100 ? 2 : 1);
    final phrase = _phrases[idx];
    final progress = (s.tasbihCount % s.tasbihTarget) / s.tasbihTarget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbih Digital'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () => s.resetTasbih(),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(phrase, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 40)),
          const SizedBox(height: 30),
          Center(
            child: SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (s.hapticsEnabled) HapticFeedback.mediumImpact();
                      s.bumpTasbih();
                      if ((s.tasbihCount) % s.tasbihTarget == 0) {
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s.tasbihTarget} kali selesai — Alhamdulillah')));
                      }
                    },
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        gradient: Grad.emerald,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.4), blurRadius: 30, offset: const Offset(0, 12))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${s.tasbihCount}', style: const TextStyle(color: Colors.white, fontSize: 68, fontWeight: FontWeight.w800, letterSpacing: -2)),
                          const Text('KETUK UNTUK DZIKIR', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text('Target: ${s.tasbihTarget}', style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              for (final t in [33, 99, 100])
                ChoiceChip(
                  label: Text('$t'),
                  selected: s.tasbihTarget == t,
                  onSelected: (_) => s.setTasbihTarget(t),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            value: s.hapticsEnabled,
            onChanged: s.setHaptics,
            title: const Text('Getaran'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 40),
          ),
        ],
      ),
    );
  }
}
