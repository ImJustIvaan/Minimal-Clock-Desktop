import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../../core/models/settings_model.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/ui_visibility_provider.dart';
import '../settings/timezone_picker_dialog.dart';
import 'widgets/animated_digit.dart';
import 'widgets/analog_clock.dart';
import 'widgets/world_clock_tile.dart';

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

  Future<void> _addCity(BuildContext context, AppSettings settings) async {
    final picked = await showTimezonePicker(context, selected: '');
    if (picked == null || picked.isEmpty) return;
    if (settings.worldClocks.contains(picked)) return;
    ref.read(settingsProvider.notifier).save(
          settings.copyWith(worldClocks: [...settings.worldClocks, picked]),
        );
  }

  void _removeCity(AppSettings settings, String tzId) {
    ref.read(settingsProvider.notifier).save(
          settings.copyWith(
            worldClocks: settings.worldClocks.where((z) => z != tzId).toList(),
          ),
        );
  }

  Widget _buildWorldClocks(BuildContext context, AppSettings settings, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final tzId in settings.worldClocks)
            WorldClockTile(
              tzId: tzId,
              use24Hour: settings.use24Hour,
              onRemove: () => _removeCity(settings, tzId),
            ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _addCity(context, settings),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.public, size: 16, color: color.withValues(alpha: 0.5)),
                    const SizedBox(height: 2),
                    Text(
                      'ADD CITY',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        color: color.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
        final uiHidden = ref.watch(uiHiddenProvider);

        return Scaffold(
          body: GestureDetector(
            // While hidden, clicking anywhere brings the UI back.
            onTap: uiHidden ? () => ref.read(uiHiddenProvider.notifier).state = false : null,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                settings.analogMode
                    ? _buildAnalog(context, displayNow, settings, color, uiHidden)
                    : _buildDigital(context, displayNow, settings, color, uiHidden),
                if (!uiHidden)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      onPressed: () => ref.read(uiHiddenProvider.notifier).state = true,
                      icon: Icon(Icons.visibility_off_outlined, color: color.withValues(alpha: 0.35), size: 20),
                      tooltip: 'Hide UI',
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalog(BuildContext context, DateTime now, AppSettings settings, Color color, bool uiHidden) {
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    final weekdayStr = DateFormat('EEEE').format(now);
    final fill = settings.fillDisplay;

    if (fill) {
      return LayoutBuilder(builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.9;
        return Center(
          child: AnalogClock(
            time: now,
            color: color,
            showSeconds: settings.showSeconds,
            size: size,
          ),
        );
      });
    }

    final clockSize = settings.clockFontSize * 2.8;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!uiHidden && settings.selectedTimezone.isNotEmpty) ...[
            Text(
              settings.selectedTimezone.replaceAll('_', ' '),
              style: TextStyle(fontSize: 11, letterSpacing: 3, color: color.withValues(alpha: 0.3)),
            ),
            const SizedBox(height: 4),
          ],
          AnalogClock(
            time: now,
            color: color,
            showSeconds: settings.showSeconds,
            size: clockSize.clamp(200.0, 500.0),
          ),
          if (!uiHidden && (settings.showWeekday || settings.showDate)) const SizedBox(height: 28),
          if (!uiHidden && settings.showWeekday)
            Text(
              weekdayStr.toUpperCase(),
              style: TextStyle(fontSize: 13, letterSpacing: 4, color: color.withValues(alpha: 0.4), fontWeight: FontWeight.w400),
            ),
          if (!uiHidden && settings.showDate) ...[
            const SizedBox(height: 6),
            Text(
              dateStr,
              style: TextStyle(fontSize: 16, letterSpacing: 1, color: color.withValues(alpha: 0.45), fontWeight: FontWeight.w300),
            ),
          ],
          if (!uiHidden) _buildWorldClocks(context, settings, color),
        ],
      ),
    );
  }

  Widget _buildDigital(BuildContext context, DateTime now, AppSettings settings, Color color, bool uiHidden) {
    final timeFormat = settings.use24Hour
        ? (settings.showSeconds ? 'HH:mm:ss' : 'HH:mm')
        : (settings.showSeconds ? 'hh:mm:ss' : 'hh:mm');
    final timeStr = DateFormat(timeFormat).format(now);
    final amPm = settings.use24Hour ? '' : DateFormat('a').format(now);
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    final weekdayStr = DateFormat('EEEE').format(now);
    final fill = settings.fillDisplay;
    final fontSize = settings.clockFontSize;
    final fontFamily = settings.clockFontFamily;

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
                  AnimatedClockText(
                    text: timeStr,
                    fontSize: 500,
                    color: color,
                    fontFamily: fontFamily,
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
            if (!uiHidden && settings.selectedTimezone.isNotEmpty) ...[
              Text(
                settings.selectedTimezone.replaceAll('_', ' '),
                style: TextStyle(fontSize: 11, letterSpacing: 3, color: color.withValues(alpha: 0.3)),
              ),
              const SizedBox(height: 4),
            ],
            if (!uiHidden && settings.showWeekday) ...[
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
                AnimatedClockText(text: timeStr, fontSize: fontSize, color: color, fontFamily: fontFamily),
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
            if (!uiHidden && settings.showDate) ...[
              const SizedBox(height: 16),
              Text(
                dateStr,
                style: TextStyle(fontSize: 16, letterSpacing: 1, color: color.withValues(alpha: 0.45), fontWeight: FontWeight.w300),
              ),
            ],
            if (!uiHidden) _buildWorldClocks(context, settings, color),
          ],
        ),
      ),
    );
  }
}
