import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/countdown_model.dart';
import '../../core/providers/countdown_provider.dart';
import '../../core/services/notification_service.dart';
import 'countdown_detail_screen.dart';

const List<String> kSuggestedCountdownCategories = [
  'Birthdays',
  'Trips',
  'Work',
  'Holidays',
];

class CreateCountdownScreen extends ConsumerStatefulWidget {
  final Countdown? existing;

  const CreateCountdownScreen({super.key, this.existing});

  @override
  ConsumerState<CreateCountdownScreen> createState() =>
      _CreateCountdownScreenState();
}

class _CreateCountdownScreenState
    extends ConsumerState<CreateCountdownScreen> {
  late final _titleCtrl =
      TextEditingController(text: widget.existing?.title ?? '');
  late final _categoryCtrl =
      TextEditingController(text: widget.existing?.category ?? '');
  late DateTime _date =
      widget.existing?.targetDate ?? DateTime.now().add(const Duration(days: 1));
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null) return;
    setState(() {
      _date = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give your countdown a title.');
      return;
    }
    final category = _categoryCtrl.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(countdownRepositoryProvider);
      if (_isEditing) {
        final countdown = await repo.updateCountdown(
          id: widget.existing!.id,
          title: title,
          targetDate: _date,
          category: category.isEmpty ? null : category,
        );
        await NotificationService.instance.scheduleCountdownNotification(
          countdownId: countdown.id,
          title: countdown.title,
          targetDate: countdown.targetDate,
        );
        ref.invalidate(myCountdownsProvider);
        ref.invalidate(countdownByIdProvider(countdown.id));
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }
      final countdown = await repo.createCountdown(
        title: title,
        targetDate: _date,
        category: category.isEmpty ? null : category,
      );
      await NotificationService.instance.scheduleCountdownNotification(
        countdownId: countdown.id,
        title: countdown.title,
        targetDate: countdown.targetDate,
      );
      ref.invalidate(myCountdownsProvider);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CountdownDetailScreen(countdownId: countdown.id),
        ),
      );
    } catch (e) {
      setState(() => _error = 'Could not save countdown. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Countdown' : 'New Countdown')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleCtrl,
                style: TextStyle(color: color, fontSize: 18),
                decoration: InputDecoration(
                  hintText: 'Title (e.g. Birthday Trip)',
                  hintStyle: TextStyle(color: color.withValues(alpha: 0.3)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color.withValues(alpha: 0.6)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _categoryCtrl,
                style: TextStyle(color: color, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Category (optional, e.g. Birthdays)',
                  hintStyle: TextStyle(color: color.withValues(alpha: 0.3)),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color.withValues(alpha: 0.15)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: color.withValues(alpha: 0.6)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kSuggestedCountdownCategories
                    .map((c) => GestureDetector(
                          onTap: () => setState(() {
                            _categoryCtrl.text = c;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: color.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              c,
                              style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.6)),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: color.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 18, color: color.withValues(alpha: 0.5)),
                      const SizedBox(width: 12),
                      Text(
                        '${_date.month}/${_date.day}/${_date.year}  ${TimeOfDay.fromDateTime(_date).format(context)}',
                        style: TextStyle(color: color, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
              const Spacer(),
              GestureDetector(
                onTap: _saving ? null : _create,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _saving ? color.withValues(alpha: 0.3) : color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _saving ? '...' : (_isEditing ? 'Save Changes' : 'Create Countdown'),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
