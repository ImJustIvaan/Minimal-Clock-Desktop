import 'dart:async';
import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  // local_notifier has no OS-level scheduling, so countdown alerts are timed
  // with an in-memory Timer. This only fires while the app is running —
  // unlike mobile, it won't survive an app restart or the machine sleeping.
  final _scheduled = <String, Timer>{};

  Future<void> init() async {
    await localNotifier.setup(appName: 'Minimal Clock');
  }

  Future<void> showTimerFinished() async {
    final notification = LocalNotification(
      title: 'Minimal Clock',
      body: 'Timer Finished',
    );
    await notification.show();
  }

  Future<void> scheduleCountdownNotification({
    required String countdownId,
    required String title,
    required DateTime targetDate,
  }) async {
    _scheduled.remove(countdownId)?.cancel();
    final delay = targetDate.difference(DateTime.now());
    if (delay.isNegative) return;
    _scheduled[countdownId] = Timer(delay, () async {
      _scheduled.remove(countdownId);
      final notification = LocalNotification(title: title, body: "It's time!");
      await notification.show();
    });
  }

  Future<void> cancelCountdownNotification(String countdownId) async {
    _scheduled.remove(countdownId)?.cancel();
  }
}
