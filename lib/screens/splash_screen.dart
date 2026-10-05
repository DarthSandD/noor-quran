import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand.dart';

/// Branded start-up screen.
///
/// The emblem rises in, the tagline follows, and the progress bar reflects the
/// **real** boot progress reported by `BootstrapController` — so the screen
/// never lies about how far along the app is.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.progress, required this.label});

  /// 0.0–1.0, from the boot controller.
  final double progress;
  final String label;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.night : AppColors.emeraldDeep;

    return Scaffold(
      backgroundColor: bg,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: isDark ? Grad.night : Grad.emerald),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final markT = Curves.easeOutBack.transform((_c.value * 1.6).clamp(0.0, 1.0));
              final textT = ((_c.value - 0.3) / 0.5).clamp(0.0, 1.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: (_c.value * 2).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * markT,
                      child: const NoorMark(size: 128, color: AppColors.goldSoft),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Opacity(
                    opacity: textT,
                    child: Transform.translate(
                      offset: Offset(0, 12 * (1 - textT)),
                      child: const Text(
                        "Noor Qur'an",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Opacity(
                    opacity: textT,
                    child: Text(
                      'Cahaya Al-Qur\'an dalam genggaman',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  // Real progress — eased between steps.
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: widget.progress.clamp(0.0, 1.0)),
                    duration: Motion.med,
                    curve: Motion.curve,
                    builder: (context, value, _) => SizedBox(
                      width: 148,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.16),
                          valueColor: const AlwaysStoppedAnimation(AppColors.goldSoft),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Height reserved so the layout never jumps as labels change.
                  SizedBox(
                    height: 18,
                    child: AnimatedSwitcher(
                      duration: Motion.fast,
                      child: Text(
                        widget.label,
                        key: ValueKey(widget.label),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
