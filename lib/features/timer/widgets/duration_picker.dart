import 'package:flutter/material.dart';

class DurationPicker extends StatefulWidget {
  final Duration initial;
  final ValueChanged<Duration> onChanged;
  final double fontSize;

  const DurationPicker({
    super.key,
    required this.initial,
    required this.onChanged,
    this.fontSize = 72,
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
    final fs = widget.fontSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SET TIMER',
          style: TextStyle(fontSize: 11, letterSpacing: 4, color: color.withValues(alpha: 0.3)),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Spinner(
              label: 'HH',
              value: _hours,
              max: 23,
              fontSize: fs,
              onChanged: (v) { setState(() => _hours = v); _notify(); },
            ),
            _Sep(color: color, fontSize: fs),
            _Spinner(
              label: 'MM',
              value: _minutes,
              max: 59,
              fontSize: fs,
              onChanged: (v) { setState(() => _minutes = v); _notify(); },
            ),
            _Sep(color: color, fontSize: fs),
            _Spinner(
              label: 'SS',
              value: _seconds,
              max: 59,
              fontSize: fs,
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
  final double fontSize;
  const _Sep({required this.color, required this.fontSize});

  @override
  Widget build(BuildContext context) => Text(
        ':',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w200,
          color: color.withValues(alpha: 0.3),
        ),
      );
}

class _Spinner extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final double fontSize;
  final ValueChanged<int> onChanged;

  const _Spinner({
    required this.label,
    required this.value,
    required this.max,
    required this.fontSize,
    required this.onChanged,
  });

  void _increment() => onChanged((value + 1) > max ? 0 : value + 1);
  void _decrement() => onChanged((value - 1) < 0 ? max : value - 1);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final btnSize = (fontSize * 0.35).clamp(20.0, 36.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ArrowBtn(icon: Icons.keyboard_arrow_up_rounded, size: btnSize, color: color, onTap: _increment),
        const SizedBox(height: 4),
        GestureDetector(
          onVerticalDragUpdate: (d) {
            if (d.delta.dy < -5) _increment();
            if (d.delta.dy > 5) _decrement();
          },
          child: Text(
            value.toString().padLeft(2, '0'),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w200,
              color: color,
              letterSpacing: -2,
              height: 1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        _ArrowBtn(icon: Icons.keyboard_arrow_down_rounded, size: btnSize, color: color, onTap: _decrement),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 10, letterSpacing: 2, color: color.withValues(alpha: 0.25))),
      ],
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  const _ArrowBtn({required this.icon, required this.size, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: size, color: color.withValues(alpha: 0.3)),
    );
  }
}
