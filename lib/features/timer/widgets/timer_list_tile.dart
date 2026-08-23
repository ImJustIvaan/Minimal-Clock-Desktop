import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/timer_provider.dart';

String formatCountdown(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

String formatStopwatch(Duration d) {
  final h = d.inHours;
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  final hundredths = ((d.inMilliseconds % 1000) ~/ 10).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s.$hundredths' : '$m:$s.$hundredths';
}

class TimerListTile extends ConsumerStatefulWidget {
  final String id;
  const TimerListTile({super.key, required this.id});

  @override
  ConsumerState<TimerListTile> createState() => _TimerListTileState();
}

class _TimerListTileState extends ConsumerState<TimerListTile> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Purely a display refresh — the provider is the source of truth for
    // elapsed/remaining time, derived from a wall-clock anchor.
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = ref.watch(timersProvider)[widget.id];
    if (entry == null) return const SizedBox.shrink();

    final notifier = ref.read(timersProvider.notifier);
    final color = Theme.of(context).colorScheme.onSurface;
    final now = DateTime.now();
    final isStopwatch = entry.kind == TimerKind.stopwatch;
    final display = isStopwatch
        ? formatStopwatch(entry.elapsedAt(now))
        : formatCountdown(entry.remainingAt(now));
    final isFinished = entry.status == TimerStatus.finished;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: isFinished ? 0.3 : 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (entry.label.isNotEmpty) ...[
                  Text(
                    entry.label,
                    style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.5)),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  isFinished ? 'Finished' : display,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -1,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (entry.status == TimerStatus.running)
            _SmallCircleButton(
              icon: Icons.pause_rounded,
              color: color,
              onTap: () => notifier.pause(entry.id),
            )
          else if (entry.status == TimerStatus.paused)
            _SmallCircleButton(
              icon: Icons.play_arrow_rounded,
              color: color,
              onTap: () => notifier.resume(entry.id),
            )
          else if (entry.status == TimerStatus.idle)
            _SmallCircleButton(
              icon: Icons.play_arrow_rounded,
              color: color,
              onTap: () => notifier.start(entry.id),
            ),
          const SizedBox(width: 8),
          _SmallCircleButton(
            icon: isFinished ? Icons.close_rounded : Icons.refresh_rounded,
            color: color.withValues(alpha: 0.3),
            onTap: () =>
                isFinished ? notifier.remove(entry.id) : notifier.reset(entry.id),
          ),
        ],
      ),
    );
  }
}

class _SmallCircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SmallCircleButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Theme.of(context).colorScheme.surface, size: 18),
      ),
    );
  }
}
