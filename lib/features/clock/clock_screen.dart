import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../core/providers/settings_provider.dart';
import 'widgets/animated_digit.dart';
import 'widgets/analog_clock.dart';

class ClockScreen extends ConsumerStatefulWidget {
  const ClockScreen({super.key});

  @override
  ConsumerState<ClockScreen> createState() => _ClockScreenState();
}

class _ClockScreenState extends ConsumerState<ClockScreen> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  bool _tzInitialized = false;

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _tzInitialized = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  DateTime _localizedNow(String tzId) {
    if (!_tzInitialized || tzId.isEmpty) return _now;
    try {
      final location = tz.getLocation(tzId);
      final tzNow = tz.TZDateTime.now(location);
      return DateTime(tzNow.year, tzNow.month, tzNow.day,
          tzNow.hour, tzNow.minute, tzNow.second);
    } catch (_) {
      return _now;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    return settingsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (settings) {
        final displayNow = _localizedNow(settings.selectedTimezone);
        final color = Theme.of(context).colorScheme.onSurface;

        return Scaffold(
          body: settings.analogMode
              ? _buildAnalog(displayNow, settings, color)
              : _buildDigital(displayNow, settings, color),
        );
      },
    );
  }

  Widget _buildAnalog(DateTime now, dynamic settings, Color color) {
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    final weekdayStr = DateFormat('EEEE').format(now);
    final fill = settings.fillDisplay as bool;

    if (fill) {
      return LayoutBuilder(builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.9;
        return Center(
          child: AnalogClock(
            time: now,
            color: color,
            showSeconds: settings.showSeconds as bool,
            size: size,
          ),
        );
      });
    }

    final clockSize = (settings.clockFontSize as double) * 2.8;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (settings.selectedTimezone.isNotEmpty) ...[
            Text(
              (settings.selectedTimezone as String).replaceAll('_', ' '),
              style: TextStyle(fontSize: 11, letterSpacing: 3, color: color.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 4),
          ],
          AnalogClock(
            time: now,
            color: color,
            showSeconds: settings.showSeconds as bool,
            size: clockSize.clamp(200.0, 500.0),
          ),
          if (settings.showWeekday || settings.showDate) const SizedBox(height: 28),
          if (settings.showWeekday)
            Text(
              weekdayStr.toUpperCase(),
              style: TextStyle(fontSize: 13, letterSpacing: 4, color: color.withValues(alpha: 0.4), fontWeight: FontWeight.w400),
            ),
          if (settings.showDate) ...[
            const SizedBox(height: 6),
            Text(
              dateStr,
              style: TextStyle(fontSize: 16, letterSpacing: 1, color: color.withValues(alpha: 0.45), fontWeight: FontWeight.w300),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDigital(DateTime now, dynamic settings, Color color) {
    final timeFormat = settings.use24Hour
        ? (settings.showSeconds ? 'HH:mm:ss' : 'HH:mm')
        : (settings.showSeconds ? 'hh:mm:ss' : 'hh:mm');
    final timeStr = DateFormat(timeFormat).format(now);
    final amPm = settings.use24Hour ? '' : DateFormat('a').format(now);
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    final weekdayStr = DateFormat('EEEE').format(now);
    final fill = settings.fillDisplay as bool;
    final fontSize = settings.clockFontSize as double;

    if (fill) {
      // Fill mode: scale the time string to fill the available width
      return LayoutBuilder(builder: (context, constraints) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FittedBox(
              fit: BoxFit.contain,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 500,
                      fontWeight: FontWeight.w200,
                      color: color,
                      letterSpacing: -8,
                      height: 1,
                    ),
                  ),
                  if (!settings.use24Hour && amPm.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Text(
                        amPm,
                        style: TextStyle(
                          fontSize: 120,
                          color: color.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      });
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (settings.selectedTimezone.isNotEmpty) ...[
              Text(
                (settings.selectedTimezone as String).replaceAll('_', ' '),
                style: TextStyle(fontSize: 11, letterSpacing: 3, color: color.withValues(alpha: 0.3)),
              ),
              const SizedBox(height: 4),
            ],
            if (settings.showWeekday) ...[
              Text(
                weekdayStr.toUpperCase(),
                style: TextStyle(fontSize: 13, letterSpacing: 4, color: color.withValues(alpha: 0.4), fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AnimatedClockText(text: timeStr, fontSize: fontSize, color: color),
                if (!settings.use24Hour && amPm.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Padding(
                    padding: EdgeInsets.only(bottom: fontSize * 0.08),
                    child: Text(
                      amPm,
                      style: TextStyle(
                        fontSize: fontSize * 0.22,
                        color: color.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (settings.showDate) ...[
              const SizedBox(height: 16),
              Text(
                dateStr,
                style: TextStyle(fontSize: 16, letterSpacing: 1, color: color.withValues(alpha: 0.45), fontWeight: FontWeight.w300),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
