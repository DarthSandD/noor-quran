import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand.dart';

/// Process-wide error handling.
///
/// Installed once, before `runApp`, so that:
///  * a widget that throws renders a small inline notice instead of the red
///    "grey screen of death" (release) or a broken layout;
///  * an uncaught asynchronous error is logged and swallowed rather than
///    tearing the process down.
class AppErrorHandlers {
  const AppErrorHandlers._();

  static void install() {
    FlutterError.onError = FlutterError.presentError;

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('Noor: uncaught error — $error\n$stack');
      return true; // handled: keep the app alive
    };

    ErrorWidget.builder = (FlutterErrorDetails details) => _InlineError(details: details);
  }
}

/// Replaces the default error box. Deliberately dependency-free (no `Theme`,
/// no `Directionality` from an ancestor) because it can be inserted anywhere.
class _InlineError extends StatelessWidget {
  const _InlineError({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final message = kReleaseMode
        ? 'Bagian ini tidak dapat ditampilkan.'
        : details.exceptionAsString();
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.nightCard,
        alignment: Alignment.center,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFEAF3F0), fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Full-screen failure state used when the app genuinely cannot start.
/// Always offers a way forward — never a dead end.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const NoorMark(size: 84, color: AppColors.goldSoft),
              const SizedBox(height: 24),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65), fontSize: 13.5, height: 1.5),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Coba lagi'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
