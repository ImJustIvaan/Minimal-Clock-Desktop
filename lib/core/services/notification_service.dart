import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

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
}
