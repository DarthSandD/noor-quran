import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/splash_screen.dart';
import '../theme/app_theme.dart';
import 'app_error.dart';
import 'app_shell.dart';
import 'bootstrap.dart';

/// Chooses what the user sees: the splash while starting, the app when ready,
/// or a recoverable error screen when the app truly cannot start.
///
/// Because [BootstrapController] bounds every step, the splash can never hang.
class BootstrapGate extends StatelessWidget {
  const BootstrapGate({super.key});

  @override
  Widget build(BuildContext context) {
    final boot = context.watch<BootstrapController>();

    final Widget child = switch (boot.status) {
      BootStatus.ready => const AppShell(key: ValueKey('shell')),
      BootStatus.failed => ErrorView(
          key: const ValueKey('boot-error'),
          title: 'Gagal memuat data',
          message: boot.errorMessage,
          onRetry: () => context.read<BootstrapController>().retry(),
        ),
      BootStatus.loading => SplashScreen(
          key: const ValueKey('splash'),
          progress: boot.progress,
          label: boot.label,
        ),
    };

    return AnimatedSwitcher(
      duration: Motion.slow,
      switchInCurve: Motion.curve,
      child: child,
    );
  }
}
