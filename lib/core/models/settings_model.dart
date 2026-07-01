import 'package:flutter/material.dart';

class AppSettings {
  final ThemeMode themeMode;
  final bool use24Hour;
  final bool showSeconds;
  final bool showDate;
  final bool showWeekday;
  final double clockFontSize;
  // Empty string means local device timezone
  final String selectedTimezone;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.use24Hour = false,
    this.showSeconds = true,
    this.showDate = true,
    this.showWeekday = true,
    this.clockFontSize = 72,
    this.selectedTimezone = '',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? use24Hour,
    bool? showSeconds,
    bool? showDate,
    bool? showWeekday,
    double? clockFontSize,
    String? selectedTimezone,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      use24Hour: use24Hour ?? this.use24Hour,
      showSeconds: showSeconds ?? this.showSeconds,
      showDate: showDate ?? this.showDate,
      showWeekday: showWeekday ?? this.showWeekday,
      clockFontSize: clockFontSize ?? this.clockFontSize,
      selectedTimezone: selectedTimezone ?? this.selectedTimezone,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'use24Hour': use24Hour,
        'showSeconds': showSeconds,
        'showDate': showDate,
        'showWeekday': showWeekday,
        'clockFontSize': clockFontSize,
        'selectedTimezone': selectedTimezone,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
        use24Hour: json['use24Hour'] as bool? ?? false,
        showSeconds: json['showSeconds'] as bool? ?? true,
        showDate: json['showDate'] as bool? ?? true,
        showWeekday: json['showWeekday'] as bool? ?? true,
        clockFontSize: (json['clockFontSize'] as num?)?.toDouble() ?? 72,
        selectedTimezone: json['selectedTimezone'] as String? ?? '',
      );
}
