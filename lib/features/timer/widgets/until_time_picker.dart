import 'package:flutter/material.dart';

/// Lets the user pick a target clock time (e.g. "9:40 AM") instead of a
/// raw duration. TimerScreen converts this to a Duration relative to now
/// when the timer is started.
class UntilTimePicker extends StatefulWidget {
  final TimeOfDay initial;
  final bool is24Hour;
  final double fontSize;
  final ValueChanged<TimeOfDay> onChanged;

  const UntilTimePicker({
    super.key,
    required this.initial,
    required this.is24Hour,
    required this.onChanged,
    this.fontSize = 72,
  });

  @override
  State<UntilTimePicker> createState() => _UntilTimePickerState();
}

class _UntilTimePickerState extends State<UntilTimePicker> {
  late int _hour24;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _hour24 = widget.initial.hour;
    _minute = widget.initial.minute;
  }

  void _notify() {
    widget.onChanged(TimeOfDay(hour: _hour24, minute: _minute));
  }

  bool get _isPm => _hour24 >= 12;

  int get _hourDisplay {
    if (widget.is24Hour) return _hour24;
    final h = _hour24 % 12;
    return h == 0 ? 12 : h;
  }

  void _setHourDisplay(int displayValue) {
    setState(() {
      if (widget.is24Hour) {
        _hour24 = displayValue;
      } else {
        final isPm = _isPm;
        var h = displayValue % 12;
        if (isPm) h += 12;
        _hour24 = h;
      }
      _notify();
    });
  }

  void _toggleAmPm() {
    setState(() {
      _hour24 = _isPm ? _hour24 - 12 : _hour24 + 12;
      _notify();
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final fs = widget.fontSize;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TIMER ENDS AT',
          style: TextStyle(fontSize: 11, letterSpacing: 4, color: color.withValues(alpha: 0.3)),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Spinner(
              label: 'HH',
              value: _hourDisplay,
              min: widget.is24Hour ? 0 : 1,
              max: widget.is24Hour ? 23 : 12,
              fontSize: fs,
              onChanged: _setHourDisplay,
            ),
            Text(
              ':',
              style: TextStyle(fontSize: fs, fontWeight: FontWeight.w200, color: color.withValues(alpha: 0.3)),
            ),
            _Spinner(
              label: 'MM',
              value: _minute,
              min: 0,
              max: 59,
              fontSize: fs,
              onChanged: (v) => setState(() {
                _minute = v;
                _notify();
              }),
            ),
            if (!widget.is24Hour) ...[
              SizedBox(width: (fs * 0.2).clamp(12.0, 24.0)),
              GestureDetector(
                onTap: _toggleAmPm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isPm ? 'PM' : 'AM',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final double fontSize;
  final ValueChanged<int> onChanged;

  const _Spinner({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.fontSize,
    required this.onChanged,
  });

  void _increment() => onChanged((value + 1) > max ? min : value + 1);
  void _decrement() => onChanged((value - 1) < min ? max : value - 1);

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
