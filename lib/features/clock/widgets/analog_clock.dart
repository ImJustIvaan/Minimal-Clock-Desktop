import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnalogClock extends StatelessWidget {
  final DateTime time;
  final Color color;
  final bool showSeconds;
  final double size;

  const AnalogClock({
    super.key,
    required this.time,
    required this.color,
    this.showSeconds = true,
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AnalogClockPainter(
          time: time,
          color: color,
          showSeconds: showSeconds,
        ),
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final DateTime time;
  final Color color;
  final bool showSeconds;

  _AnalogClockPainter({
    required this.time,
    required this.color,
    required this.showSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final handPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Outer circle
    canvas.drawCircle(center, radius * 0.96, trackPaint);

    // Hour ticks
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final isQuarter = i % 3 == 0;
      tickPaint
        ..color = color.withValues(alpha: isQuarter ? 0.5 : 0.2)
        ..strokeWidth = isQuarter ? 1.5 : 1.0;
      final outer = Offset(
        center.dx + (radius * 0.90) * math.sin(angle),
        center.dy - (radius * 0.90) * math.cos(angle),
      );
      final inner = Offset(
        center.dx + (radius * (isQuarter ? 0.78 : 0.83)) * math.sin(angle),
        center.dy - (radius * (isQuarter ? 0.78 : 0.83)) * math.cos(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }

    // Hour hand
    final hourAngle = ((time.hour % 12) + time.minute / 60.0) * 30 * math.pi / 180;
    _drawHand(canvas, center, hourAngle, radius * 0.52, 2.5, handPaint..color = color);

    // Minute hand
    final minuteAngle = (time.minute + time.second / 60.0) * 6 * math.pi / 180;
    _drawHand(canvas, center, minuteAngle, radius * 0.72, 1.8, handPaint..color = color);

    // Second hand
    if (showSeconds) {
      final secondAngle = time.second * 6 * math.pi / 180;
      _drawHand(canvas, center, secondAngle, radius * 0.80, 1.0,
          handPaint..color = color.withValues(alpha: 0.5));
      // Counter tail
      _drawHand(canvas, center, secondAngle + math.pi, radius * 0.18, 1.0,
          handPaint..color = color.withValues(alpha: 0.5));
    }

    // Center dot
    canvas.drawCircle(
      center,
      3,
      Paint()..color = color,
    );
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length,
      double width, Paint paint) {
    final end = Offset(
      center.dx + length * math.sin(angle),
      center.dy - length * math.cos(angle),
    );
    canvas.drawLine(center, end, paint..strokeWidth = width);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter old) =>
      old.time.second != time.second ||
      old.time.minute != time.minute ||
      old.time.hour != time.hour;
}
