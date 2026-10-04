import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/motion.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final idx = (s.tasbihTarget == 33 ? 0 : s.tasbihTarget == 100 ? 2 : 1);
    final phrase = _phrases[idx];
    final progress = (s.tasbihCount % s.tasbihTarget) / s.tasbihTarget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbih Digital'),
        actions: [
          IconButton(icon: const Icon(Icons.restart_alt_rounded), onPressed: () => s.resetTasbih()),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 14),
          Text(phrase, style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 42, color: AppColors.emerald)),
          const SizedBox(height: 6),
          Text('Ketuk lingkaran untuk berdzikir', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: scheme.onSurface.withValues(alpha: 0.5))),
          const Spacer(),
          Center(
            child: SizedBox(
              width: 282,
              height: 282,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 282,
                    height: 282,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: Motion.med,
                      curve: Motion.curve,
                      builder: (_, v, _) => CircularProgressIndicator(
                        value: v,
                        strokeWidth: 11,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  PressScale(
                    scale: 0.94,
                    onTap: () {
                      if (s.hapticsEnabled) HapticFeedback.mediumImpact();
                      s.bumpTasbih();
                      if (s.tasbihCount % s.tasbihTarget == 0) {
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${s.tasbihTarget} kali selesai — Alhamdulillah')));
                      }
                    },
                    child: Container(
                      width: 224,
                      height: 224,
                      decoration: BoxDecoration(
                        gradient: Grad.emerald,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.42), blurRadius: 34, offset: const Offset(0, 14))],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: Motion.fast,
                            transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                            child: Text(
                              '${s.tasbihCount}',
                              key: ValueKey(s.tasbihCount),
                              style: const TextStyle(color: Colors.white, fontSize: 70, fontWeight: FontWeight.w800, letterSpacing: -2.5),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text('DARI ${s.tasbihTarget}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.8)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text('Target dzikir', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: scheme.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              for (final t in [33, 99, 100])
                PressScale(
                  onTap: () => s.setTasbihTarget(t),
                  child: AnimatedContainer(
                    duration: Motion.med,
                    curve: Motion.curve,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
                    decoration: BoxDecoration(
                      gradient: s.tasbihTarget == t ? Grad.emeraldSoft : null,
                      color: s.tasbihTarget == t ? null : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text('$t', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: s.tasbihTarget == t ? Colors.white : scheme.onSurface)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: s.hapticsEnabled,
            onChanged: s.setHaptics,
            title: const Text('Getaran', style: TextStyle(fontWeight: FontWeight.w600)),
            secondary: const Icon(Icons.vibration_rounded),
            contentPadding: const EdgeInsets.symmetric(horizontal: 32),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
