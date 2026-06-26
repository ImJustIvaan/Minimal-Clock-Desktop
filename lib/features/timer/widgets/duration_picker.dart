import 'package:flutter/material.dart';

class DurationPicker extends StatefulWidget {
  final Duration initial;
  final ValueChanged<Duration> onChanged;

  const DurationPicker({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late int _hours;
  late int _minutes;
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _hours = widget.initial.inHours;
    _minutes = widget.initial.inMinutes % 60;
    _seconds = widget.initial.inSeconds % 60;
  }

  void _notify() {
    widget.onChanged(Duration(hours: _hours, minutes: _minutes, seconds: _seconds));
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SET TIMER',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 4,
            color: color.withValues(alpha: 0.3),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Scroll(
              label: 'HH',
              value: _hours,
              max: 23,
              onChanged: (v) { setState(() => _hours = v); _notify(); },
            ),
            _Sep(color: color),
            _Scroll(
              label: 'MM',
              value: _minutes,
              max: 59,
              onChanged: (v) { setState(() => _minutes = v); _notify(); },
            ),
            _Sep(color: color),
            _Scroll(
              label: 'SS',
              value: _seconds,
              max: 59,
              onChanged: (v) { setState(() => _seconds = v); _notify(); },
            ),
          ],
        ),
      ],
    );
  }
}

class _Sep extends StatelessWidget {
  final Color color;
  const _Sep({required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          ':',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w200,
            color: color.withValues(alpha: 0.3),
          ),
        ),
      );
}

class _Scroll extends StatefulWidget {
  final String label;
  final int value;
  final int max;
  final ValueChanged<int> onChanged;

  const _Scroll({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  State<_Scroll> createState() => _ScrollState();
}

class _ScrollState extends State<_Scroll> {
  late FixedExtentScrollController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = FixedExtentScrollController(initialItem: widget.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 140,
          child: ListWheelScrollView.useDelegate(
            controller: _ctrl,
            itemExtent: 56,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.003,
            onSelectedItemChanged: widget.onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final v = index % (widget.max + 1);
                final selected = v == widget.value;
                return Center(
                  child: Text(
                    v.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w200,
                      color: selected ? color : color.withValues(alpha: 0.18),
                      letterSpacing: -1,
                    ),
                  ),
                );
              },
              childCount: (widget.max + 1) * 100,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 2,
            color: color.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}
