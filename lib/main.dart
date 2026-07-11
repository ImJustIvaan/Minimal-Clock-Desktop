import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'core/providers/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'shared/widgets/app_shell.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(const Size(600, 480));
  await windowManager.setSize(const Size(800, 600));
  await windowManager.setTitle('Minimal Clock');
  await windowManager.center();

  await SupabaseService.init();
  await NotificationService.instance.init();

  runApp(const ProviderScope(child: MinimalClockApp()));

  DeepLinkService.instance.init(navigatorKey);
}

class MinimalClockApp extends ConsumerWidget {
  const MinimalClockApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final themeMode = settingsAsync.valueOrNull?.themeMode ?? ThemeMode.system;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Minimal Clock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // Clock/timer/countdown displays are custom-sized digit layouts, not
      // scrollable text — clamp OS-level text scaling so they don't clip.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: child!,
      ),
      home: const AppShell(),
    );
  }
}
