import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/timer_provider.dart';
import 'widgets/duration_picker.dart';
import 'widgets/timer_progress_ring.dart';

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(timerProvider);
    final notifier = ref.read(timerProvider.notifier);
    final color = Theme.of(context).colorScheme.onSurface;
    final fontSize = ref.watch(settingsProvider).valueOrNull?.clockFontSize ?? 72;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const Spacer(flex: 2),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: state.status == TimerStatus.idle
                  ? DurationPicker(
                      key: const ValueKey('picker'),
                      onChanged: (d) => notifier.setDuration(d),
                      initial: state.total,
                      fontSize: fontSize,
                    )
                  : TimerProgressRing(
                      key: const ValueKey('ring'),
                      state: state,
                      color: color,
                      fontSize: fontSize,
                    ),
            ),
            const Spacer(flex: 2),
            _Controls(state: state, notifier: notifier, color: color),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  final TimerState state;
  final TimerNotifier notifier;
  final Color color;

  const _Controls({required this.state, required this.notifier, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state.status != TimerStatus.idle) ...[
          _CircleButton(
            icon: Icons.refresh_rounded,
            onTap: notifier.reset,
            color: color.withValues(alpha: 0.3),
            size: 56,
          ),
          const SizedBox(width: 24),
        ],
        _CircleButton(
          icon: _primaryIcon(state.status),
          onTap: () => _primaryAction(state.status, notifier),
          color: color,
          size: 72,
          iconColor: Theme.of(context).colorScheme.surface,
        ),
      ],
    );
  }

  IconData _primaryIcon(TimerStatus s) {
    switch (s) {
      case TimerStatus.running:  return Icons.pause_rounded;
      case TimerStatus.paused:   return Icons.play_arrow_rounded;
      case TimerStatus.finished: return Icons.refresh_rounded;
      case TimerStatus.idle:     return Icons.play_arrow_rounded;
    }
  }

  void _primaryAction(TimerStatus s, TimerNotifier n) {
    switch (s) {
      case TimerStatus.idle:     n.start();
      case TimerStatus.running:  n.pause();
      case TimerStatus.paused:   n.resume();
      case TimerStatus.finished: n.reset();
    }
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;
  final Color? iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.size,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(
          icon,
          color: iconColor ?? Theme.of(context).colorScheme.surface,
          size: size * 0.45,
        ),
      ),
    );
  }
}
