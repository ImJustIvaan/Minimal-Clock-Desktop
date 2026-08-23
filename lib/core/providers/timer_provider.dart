import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';

enum TimerKind { duration, stopwatch }

enum TimerStatus { idle, running, paused, finished }

class TimerEntry {
  final String id;
  final String label;
  final TimerKind kind;

  // Duration timers: total set at creation, remaining banked whenever the
  // timer isn't running. While running, the live value is derived from
  // `anchor` (the wall-clock time the timer is due to finish) rather than
  // ticked down, so time isn't lost while the app is suspended/inactive.
  final Duration total;
  final Duration remaining;

  // Stopwatches: elapsed time banked from completed run segments. While
  // running, the live value adds `now - anchor` (the current segment's
  // start time) on top of this.
  final Duration elapsedSoFar;

  final DateTime? anchor;
  final TimerStatus status;

  const TimerEntry({
    required this.id,
    this.label = '',
    required this.kind,
    this.total = Duration.zero,
    this.remaining = Duration.zero,
    this.elapsedSoFar = Duration.zero,
    this.anchor,
    this.status = TimerStatus.idle,
  });

  double progressAt(DateTime now) => total.inMilliseconds == 0
      ? 0
      : remainingAt(now).inMilliseconds / total.inMilliseconds;

  Duration elapsedAt(DateTime now) {
    if (status == TimerStatus.running && anchor != null) {
      return elapsedSoFar + now.difference(anchor!);
    }
    return elapsedSoFar;
  }

  Duration remainingAt(DateTime now) {
    if (status == TimerStatus.running && anchor != null) {
      final r = anchor!.difference(now);
      return r.isNegative ? Duration.zero : r;
    }
    return remaining;
  }

  TimerEntry copyWith({
    String? label,
    Duration? total,
    Duration? remaining,
    Duration? elapsedSoFar,
    DateTime? anchor,
    bool clearAnchor = false,
    TimerStatus? status,
  }) =>
      TimerEntry(
        id: id,
        label: label ?? this.label,
        kind: kind,
        total: total ?? this.total,
        remaining: remaining ?? this.remaining,
        elapsedSoFar: elapsedSoFar ?? this.elapsedSoFar,
        anchor: clearAnchor ? null : (anchor ?? this.anchor),
        status: status ?? this.status,
      );
}

/// Manages every running/paused timer and stopwatch as a keyed collection,
/// so any number of them can run independently at once. Displayed values
/// are always derived from a wall-clock anchor (see [TimerEntry]) — this
/// notifier's own periodic tick exists only to detect when a duration timer
/// reaches zero so it can flip to `finished` and fire a notification: it
/// never writes a ticked-down value into state.
class TimersNotifier extends Notifier<Map<String, TimerEntry>>
    with WidgetsBindingObserver {
  Timer? _ticker;
  int _nextId = 0;

  @override
  Map<String, TimerEntry> build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _ticker?.cancel();
    });
    return const {};
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (lifecycleState == AppLifecycleState.resumed) {
      _checkFinished();
    }
  }

  String _generateId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_nextId++}';

  String addDurationTimer({required Duration total, String label = ''}) {
    final id = _generateId();
    final now = DateTime.now();
    final entry = TimerEntry(
      id: id,
      label: label,
      kind: TimerKind.duration,
      total: total,
      remaining: total,
      anchor: now.add(total),
      status: TimerStatus.running,
    );
    state = {...state, id: entry};
    _ensureTicking();
    return id;
  }

  String addStopwatch({String label = ''}) {
    final id = _generateId();
    final entry = TimerEntry(
      id: id,
      label: label,
      kind: TimerKind.stopwatch,
      anchor: DateTime.now(),
      status: TimerStatus.running,
    );
    state = {...state, id: entry};
    return id;
  }

  void start(String id) {
    final entry = state[id];
    if (entry == null || entry.status != TimerStatus.idle) return;
    final now = DateTime.now();
    _updateEntry(entry.copyWith(
      anchor: entry.kind == TimerKind.duration ? now.add(entry.total) : now,
      status: TimerStatus.running,
    ));
    if (entry.kind == TimerKind.duration) _ensureTicking();
  }

  void pause(String id) {
    final entry = state[id];
    if (entry == null || entry.status != TimerStatus.running) return;
    final now = DateTime.now();
    _updateEntry(entry.copyWith(
      remaining: entry.remainingAt(now),
      elapsedSoFar: entry.elapsedAt(now),
      clearAnchor: true,
      status: TimerStatus.paused,
    ));
  }

  void resume(String id) {
    final entry = state[id];
    if (entry == null || entry.status != TimerStatus.paused) return;
    final now = DateTime.now();
    _updateEntry(entry.copyWith(
      anchor:
          entry.kind == TimerKind.duration ? now.add(entry.remaining) : now,
      status: TimerStatus.running,
    ));
    if (entry.kind == TimerKind.duration) _ensureTicking();
  }

  void reset(String id) {
    final entry = state[id];
    if (entry == null) return;
    if (entry.kind == TimerKind.stopwatch) {
      _updateEntry(entry.copyWith(
        elapsedSoFar: Duration.zero,
        clearAnchor: true,
        status: TimerStatus.idle,
      ));
    } else {
      _updateEntry(entry.copyWith(
        remaining: entry.total,
        clearAnchor: true,
        status: TimerStatus.idle,
      ));
    }
  }

  void remove(String id) {
    final next = {...state}..remove(id);
    state = next;
  }

  void _updateEntry(TimerEntry entry) {
    state = {...state, entry.id: entry};
  }

  void _ensureTicking() {
    _ticker ??=
        Timer.periodic(const Duration(milliseconds: 250), (_) => _checkFinished());
  }

  void _checkFinished() {
    if (state.isEmpty) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    final now = DateTime.now();
    var anyDurationRunning = false;
    Map<String, TimerEntry>? next;
    for (final entry in state.values) {
      if (entry.status != TimerStatus.running || entry.kind != TimerKind.duration) {
        continue;
      }
      if (entry.remainingAt(now) <= Duration.zero) {
        (next ??= {...state})[entry.id] = entry.copyWith(
          remaining: Duration.zero,
          clearAnchor: true,
          status: TimerStatus.finished,
        );
        NotificationService.instance
            .showTimerFinished(label: entry.label.isEmpty ? null : entry.label);
      } else {
        anyDurationRunning = true;
      }
    }
    if (next != null) state = next;
    if (!anyDurationRunning) {
      _ticker?.cancel();
      _ticker = null;
    }
  }
}

final timersProvider =
    NotifierProvider<TimersNotifier, Map<String, TimerEntry>>(TimersNotifier.new);
