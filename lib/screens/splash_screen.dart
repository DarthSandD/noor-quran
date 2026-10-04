import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';

/// Branded splash shown while the app boots. Fades the emblem in, draws a
/// gold progress arc, then dissolves into the shell.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900))
    ..forward();

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone?.call();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.night : AppColors.emeraldDeep;

    return Scaffold(
      backgroundColor: bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isDark ? Grad.night : Grad.emerald,
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_c.value);
              final markT = Curves.easeOutBack.transform((_c.value * 1.6).clamp(0.0, 1.0));
              final textT = ((_c.value - 0.35) / 0.4).clamp(0.0, 1.0);
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: (_c.value * 2).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * markT,
                      child: const NoorMark(size: 132, color: AppColors.goldSoft),
                    ),
                  ),
                  const SizedBox(height: 28),
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
                  const SizedBox(height: 8),
                  Opacity(
                    opacity: textT,
                    child: Text(
                      'Cahaya Al-Qur\'an dalam genggaman',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 46),
                  SizedBox(
                    width: 132,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: t,
                        minHeight: 3,
                        backgroundColor: Colors.white.withValues(alpha: 0.16),
                        valueColor: const AlwaysStoppedAnimation(AppColors.goldSoft),
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
