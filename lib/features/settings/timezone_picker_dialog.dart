import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Shows the searchable timezone picker dialog and returns the chosen
/// timezone id ('' for local device timezone), or null if cancelled.
/// Shared by the settings screen's timezone row and the clock screen's
/// "Add City" world-clock flow.
Future<String?> showTimezonePicker(BuildContext context, {required String selected}) {
  tz_data.initializeTimeZones();
  final allZones = tz.timeZoneDatabase.locations.keys.toList()..sort();
  return showDialog<String>(
    context: context,
    builder: (ctx) => TimezonePickerDialog(allZones: allZones, selected: selected),
  );
}

class TimezonePickerDialog extends StatefulWidget {
  final List<String> allZones;
  final String selected;

  const TimezonePickerDialog({super.key, required this.allZones, required this.selected});

  @override
  State<TimezonePickerDialog> createState() => _TimezonePickerDialogState();
}

class _TimezonePickerDialogState extends State<TimezonePickerDialog> {
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
