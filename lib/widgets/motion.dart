import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Fade + rise entrance used for staggered lists and cards.
class FadeRise extends StatefulWidget {
  const FadeRise({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = Motion.slow,
    this.offset = 18,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  @override
  State<FadeRise> createState() => _FadeRiseState();
}

class _FadeRiseState extends State<FadeRise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Motion.curve);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(offset: Offset(0, widget.offset * (1 - curved.value)), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Scales down slightly while pressed — tactile feedback for any tappable card.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.onTap, this.scale = 0.97, this.borderRadius});

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTapCancel: widget.onTap == null ? null : () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: Motion.fast,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}

/// Soft elevated surface with a hairline border — the app's default card look.
class NoorCard extends StatelessWidget {
  const NoorCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.color,
    this.gradient,
    this.onTap,
    this.border = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final r = BorderRadius.circular(radius);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? (isDark ? AppColors.nightCard : Colors.white)) : null,
        gradient: gradient,
        borderRadius: r,
        border: border && gradient == null
            ? Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.9 : 0.7))
            : null,
        boxShadow: gradient == null && !isDark
            ? [BoxShadow(color: AppColors.ink.withValues(alpha: 0.045), blurRadius: 18, offset: const Offset(0, 6))]
            : null,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return PressScale(onTap: onTap, borderRadius: r, child: content);
  }
}

/// Section heading with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 10),
      child: Row(
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const Spacer(),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

/// Pulsing "live"/recording dot.
class PulseDot extends StatefulWidget {
  const PulseDot({super.key, this.color = AppColors.gold, this.size = 8});
  final Color color;
  final double size;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        return SizedBox(
          width: widget.size * 2.4,
          height: widget.size * 2.4,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: (1 - t) * 0.55,
                  child: Container(
                    width: widget.size + widget.size * 1.5 * t,
                    height: widget.size + widget.size * 1.5 * t,
                    decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                  ),
                ),
                Container(width: widget.size, height: widget.size, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Consistent large page title with an optional subtitle and trailing action.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: scheme.onSurface.withValues(alpha: 0.5))),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Animated equalizer bars — the universal "audio is playing" cue.
///
/// Used as a *ribbon* under the mini-player and the full player whenever a live
/// radio stream is active (a stream has no duration, so a progress bar there
/// would be meaningless). Also usable inline at any height.
class EqualizerBars extends StatefulWidget {
  const EqualizerBars({
    super.key,
    this.active = true,
    required this.color,
    this.bars = 28,
    this.height = 3,
    this.barWidth = 2,
  });

  final bool active;
  final Color color;
  final int bars;
  final double height;
  final double barWidth;

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          painter: _EqPainter(
            t: widget.active ? _c.value : 0.0,
            color: widget.color,
            bars: widget.bars,
            barWidth: widget.barWidth,
          ),
        ),
      ),
    );
  }
}

class _EqPainter extends CustomPainter {
  _EqPainter({required this.t, required this.color, required this.bars, required this.barWidth});
  final double t;
  final Color color;
  final int bars;
  final double barWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width / bars;
    final w = math.max(1.2, math.min(barWidth, gap * 0.6));
    final paint = Paint()..color = color;
    for (var i = 0; i < bars; i++) {
      // Two overlapping sine waves so the pattern never reads as a simple loop.
      final a = math.sin((i * 0.55) + t * math.pi * 2);
      final b = math.sin((i * 0.23) - t * math.pi * 2 * 0.7);
      final h = (0.22 + 0.78 * ((a + b) / 4 + 0.5).clamp(0.0, 1.0)) * size.height;
      final x = i * gap + (gap - w) / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, w, h), const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EqPainter old) => old.t != t || old.color != color || old.bars != bars;
}
