import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/settings_model.dart';
import '../../core/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    return settingsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (settings) => _SettingsBody(settings: settings),
    );
  }
}

class _SettingsBody extends ConsumerWidget {
  final AppSettings settings;
  const _SettingsBody({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    final color = Theme.of(context).colorScheme.onSurface;

    void update(AppSettings s) => notifier.save(s);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
              child: Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 4,
                  color: color.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _Section(label: 'APPEARANCE', children: [
                _SegmentedRow(
                  label: 'Theme',
                  value: settings.themeMode,
                  options: const {
                    ThemeMode.light: 'Light',
                    ThemeMode.dark: 'Dark',
                    ThemeMode.system: 'Auto',
                  },
                  onChanged: (v) => update(settings.copyWith(themeMode: v)),
                ),
              ]),
              _Section(label: 'TIMEZONE', children: [
                _TimezoneRow(
                  value: settings.selectedTimezone,
                  onChanged: (v) => update(settings.copyWith(selectedTimezone: v)),
                ),
              ]),
              _Section(label: 'CLOCK', children: [
                _FontRow(
                  value: settings.clockFontFamily,
                  onChanged: (v) => update(settings.copyWith(clockFontFamily: v)),
                ),
                _SwitchRow(
                  label: 'Analog mode',
                  value: settings.analogMode,
                  onChanged: (v) => update(settings.copyWith(analogMode: v)),
                ),
                _SwitchRow(
                  label: 'Fill display',
                  value: settings.fillDisplay,
                  onChanged: (v) => update(settings.copyWith(fillDisplay: v)),
                ),
                _SwitchRow(
                  label: '24-hour format',
                  value: settings.use24Hour,
                  onChanged: (v) => update(settings.copyWith(use24Hour: v)),
                ),
                _SwitchRow(
                  label: 'Show seconds',
                  value: settings.showSeconds,
                  onChanged: (v) => update(settings.copyWith(showSeconds: v)),
                ),
                _SwitchRow(
                  label: 'Show date',
                  value: settings.showDate,
                  onChanged: (v) => update(settings.copyWith(showDate: v)),
                ),
                _SwitchRow(
                  label: 'Show weekday',
                  value: settings.showWeekday,
                  onChanged: (v) => update(settings.copyWith(showWeekday: v)),
                ),
                _SliderRow(
                  label: 'Clock size',
                  value: settings.clockFontSize,
                  min: 48,
                  max: 240,
                  onChanged: (v) => update(settings.copyWith(clockFontSize: v)),
                ),
              ]),
              _Section(label: 'NOTIFICATIONS', children: [
                _SwitchRow(
                  label: 'Hourly Notifier',
                  value: settings.hourlyNotifier,
                  onChanged: (v) => update(settings.copyWith(hourlyNotifier: v)),
                ),
              ]),
              const _Section(label: 'CREDITS', children: [
                _LinkRow(
                  label: 'Made By @ImJustIvaan (a.k.a Ivaan S)',
                  url: 'https://ivaan.cc',
                ),
                _LinkRow(
                  label: 'Visit the Minimal Clock website',
                  url: 'https://time.ivaan.cc',
                ),
              ]),
              const SizedBox(height: 48),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _Section({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 3,
              color: color.withValues(alpha: 0.28),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final String label;
  final String url;

  const _LinkRow({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
              ),
            ),
            Icon(Icons.open_in_new, size: 16, color: color.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
                ),
              ),
              Text(
                '${value.round()}',
                style: TextStyle(fontSize: 14, color: color.withValues(alpha: 0.4)),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              thumbColor: color,
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.12),
              overlayColor: color.withValues(alpha: 0.08),
              trackHeight: 1.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimezoneRow extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TimezoneRow({required this.value, required this.onChanged});

  @override
  State<_TimezoneRow> createState() => _TimezoneRowState();
}

class _TimezoneRowState extends State<_TimezoneRow> {
  List<String> _allZones = [];

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _allZones = tz.timeZoneDatabase.locations.keys.toList()..sort();
  }

  String _label(String id) => id.isEmpty ? 'Local' : id.replaceAll('_', ' ');

  Future<void> _openPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _TimezonePicker(
        allZones: _allZones,
        selected: widget.value,
      ),
    );
    if (result != null) widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Timezone',
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
            ),
          ),
          GestureDetector(
            onTap: _openPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: color.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label(widget.value),
                    style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.expand_more, size: 16, color: color.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimezonePicker extends StatefulWidget {
  final List<String> allZones;
  final String selected;

  const _TimezonePicker({required this.allZones, required this.selected});

  @override
  State<_TimezonePicker> createState() => _TimezonePickerState();
}

class _TimezonePickerState extends State<_TimezonePicker> {
  late List<String> _filtered;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = ['', ...widget.allZones]; // '' = Local
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? ['', ...widget.allZones]
            : widget.allZones.where((z) => z.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _label(String id) => id.isEmpty ? 'Local (device timezone)' : id.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final bg = Theme.of(context).colorScheme.surface;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 420,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                style: TextStyle(fontSize: 14, color: color),
                decoration: InputDecoration(
                  hintText: 'Search timezones…',
                  hintStyle: TextStyle(color: color.withValues(alpha: 0.35)),
                  prefixIcon: Icon(Icons.search, color: color.withValues(alpha: 0.4), size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color.withValues(alpha: 0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color.withValues(alpha: 0.15)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final id = _filtered[i];
                  final isSelected = id == widget.selected;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _label(id),
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected ? color : color.withValues(alpha: 0.7),
                                fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check, size: 16, color: color),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FontRow extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FontRow({required this.value, required this.onChanged});

  Future<void> _openPicker(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => _FontPicker(selected: value),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Clock Font',
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
            ),
          ),
          GestureDetector(
            onTap: () => _openPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: color.withValues(alpha: 0.15)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.isEmpty ? 'Default' : value,
                    style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.expand_more, size: 16, color: color.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FontPicker extends StatefulWidget {
  final String selected;

  const _FontPicker({required this.selected});

  @override
  State<_FontPicker> createState() => _FontPickerState();
}

class _FontPickerState extends State<_FontPicker> {
  late final List<String> _allFonts = GoogleFonts.asMap().keys.toList()..sort();
  late List<String> _filtered;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = ['', ..._allFonts];
    _ctrl.addListener(() {
      final q = _ctrl.text.toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? ['', ..._allFonts]
            : _allFonts.where((f) => f.toLowerCase().contains(q)).toList();
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final bg = Theme.of(context).colorScheme.surface;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 420,
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                style: TextStyle(fontSize: 14, color: color),
                decoration: InputDecoration(
                  hintText: 'Search fonts…',
                  hintStyle: TextStyle(color: color.withValues(alpha: 0.35)),
                  prefixIcon: Icon(Icons.search, color: color.withValues(alpha: 0.4), size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color.withValues(alpha: 0.15)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: color.withValues(alpha: 0.15)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final name = _filtered[i];
                  final isSelected = name == widget.selected;
                  final isDefault = name.isEmpty;
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(name),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isDefault ? 'Default' : name,
                              style: isDefault
                                  ? TextStyle(
                                      fontSize: 14,
                                      color: isSelected ? color : color.withValues(alpha: 0.7),
                                      fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                                    )
                                  : GoogleFonts.getFont(
                                      name,
                                      textStyle: TextStyle(
                                        fontSize: 14,
                                        color: isSelected ? color : color.withValues(alpha: 0.7),
                                        fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
                                      ),
                                    ),
                            ),
                          ),
                          if (isSelected) Icon(Icons.check, size: 16, color: color),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  const _SegmentedRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w300),
            ),
          ),
          SegmentedButton<T>(
            segments: options.entries
                .map((e) => ButtonSegment(value: e.key, label: Text(e.value)))
                .toList(),
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            style: const ButtonStyle(
              textStyle: WidgetStatePropertyAll(
                TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
              padding: WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
