import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/timer_provider.dart';
import 'widgets/duration_picker.dart';
import 'widgets/timer_list_tile.dart';
import 'widgets/until_time_picker.dart';

enum _TimerInputMode { duration, until, stopwatch }

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  _TimerInputMode _mode = _TimerInputMode.duration;
  Duration _pickedDuration = Duration.zero;
  TimeOfDay _untilTime = TimeOfDay.now();

  void _add(TimersNotifier notifier) {
    switch (_mode) {
      case _TimerInputMode.duration:
        if (_pickedDuration == Duration.zero) return;
        notifier.addDurationTimer(total: _pickedDuration);
      case _TimerInputMode.until:
        final now = DateTime.now();
        var target = DateTime(
            now.year, now.month, now.day, _untilTime.hour, _untilTime.minute);
        if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
        notifier.addDurationTimer(total: target.difference(now));
      case _TimerInputMode.stopwatch:
        notifier.addStopwatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timers = ref.watch(timersProvider);
    final notifier = ref.read(timersProvider.notifier);
    final color = Theme.of(context).colorScheme.onSurface;
    final settings = ref.watch(settingsProvider).valueOrNull;
    final fontSize = settings?.clockFontSize ?? 72;
    final is24Hour = settings?.use24Hour ?? false;
    final ids = timers.keys.toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _ModeToggle(
                mode: _mode,
                color: color,
                onChanged: (m) => setState(() => _mode = m),
              ),
              const SizedBox(height: 24),
              if (_mode == _TimerInputMode.duration)
                DurationPicker(
                  onChanged: (d) => setState(() => _pickedDuration = d),
                  initial: _pickedDuration,
                  fontSize: (fontSize * 0.55).clamp(36.0, 72.0),
                )
              else if (_mode == _TimerInputMode.until)
                UntilTimePicker(
                  initial: _untilTime,
                  is24Hour: is24Hour,
                  fontSize: (fontSize * 0.55).clamp(36.0, 72.0),
                  onChanged: (t) => setState(() => _untilTime = t),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Counts up from zero, and keeps running\nwhile you do other things.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: color.withValues(alpha: 0.4)),
                  ),
                ),
              const SizedBox(height: 16),
              _CircleButton(
                icon: Icons.add_rounded,
                onTap: () => _add(notifier),
                color: color,
                size: 56,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ids.isEmpty
                    ? Center(
                        child: Text(
                          'No timers running.',
                          style: TextStyle(color: color.withValues(alpha: 0.3)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: ids.length,
                        itemBuilder: (context, i) => TimerListTile(key: ValueKey(ids[i]), id: ids[i]),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _TimerInputMode mode;
  final Color color;
  final ValueChanged<_TimerInputMode> onChanged;

  const _ModeToggle({required this.mode, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeButton(
            label: 'Duration',
            selected: mode == _TimerInputMode.duration,
            color: color,
            onTap: () => onChanged(_TimerInputMode.duration),
          ),
          _ModeButton(
            label: 'Until Time',
            selected: mode == _TimerInputMode.until,
            color: color,
            onTap: () => onChanged(_TimerInputMode.until),
          ),
          _ModeButton(
            label: 'Stopwatch',
            selected: mode == _TimerInputMode.stopwatch,
            color: color,
            onTap: () => onChanged(_TimerInputMode.stopwatch),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Theme.of(context).colorScheme.surface : color.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.color,
    required this.size,
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
          color: Theme.of(context).colorScheme.surface,
          size: size * 0.45,
        ),
      ),
    );
  }
}
