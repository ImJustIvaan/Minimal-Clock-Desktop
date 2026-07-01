import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:local_notifier/local_notifier.dart';

class HourlyNotifierService {
  HourlyNotifierService._();
  static final instance = HourlyNotifierService._();

  Timer? _timer;
  final _player = AudioPlayer();
  bool _enabled = false;

  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    if (enabled) {
      _scheduleNext();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    final now = DateTime.now();
    // Time until the top of the next hour
    final next = DateTime(now.year, now.month, now.day, now.hour + 1);
    final delay = next.difference(now);

    _timer = Timer(delay, () async {
      if (!_enabled) return;
      await _chime();
      // Schedule the next one exactly 1 hour later
      _timer = Timer.periodic(const Duration(hours: 1), (_) async {
        if (!_enabled) {
          _timer?.cancel();
          return;
        }
        await _chime();
      });
    });
  }

  Future<void> _chime() async {
    // Play gong sound
    await _player.play(AssetSource('sounds/gong.wav'));

    // Show notification
    final hour = DateTime.now().hour;
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final amPm = hour < 12 ? 'AM' : 'PM';
    final notification = LocalNotification(
      title: 'Minimal Clock',
      body: "$h12:00 $amPm — it's the top of the hour.",
    );
    await notification.show();
  }

  void dispose() {
    _timer?.cancel();
    _player.dispose();
  }
}
