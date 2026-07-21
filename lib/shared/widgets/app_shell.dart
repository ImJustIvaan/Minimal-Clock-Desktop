import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ui_visibility_provider.dart';
import '../../features/clock/clock_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/countdowns/countdowns_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  static const _screens = [
    ClockScreen(),
    TimerScreen(),
    CountdownsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final railBg = Theme.of(context).navigationRailTheme.backgroundColor;
    final uiHidden = ref.watch(uiHiddenProvider);

    return Scaffold(
      body: Row(
        children: [
          if (!uiHidden) ...[
            Container(
              color: railBg,
              child: NavigationRail(
                backgroundColor: railBg,
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                indicatorColor: color.withValues(alpha: 0.08),
                selectedIconTheme: IconThemeData(color: color),
                unselectedIconTheme: IconThemeData(color: color.withValues(alpha: 0.35)),
                selectedLabelTextStyle: TextStyle(
                  fontSize: 11,
                  color: color,
                  letterSpacing: 0.5,
                ),
                unselectedLabelTextStyle: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.35),
                  letterSpacing: 0.5,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.access_time_outlined),
                    selectedIcon: Icon(Icons.access_time_filled),
                    label: Text('Clock'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.timer_outlined),
                    selectedIcon: Icon(Icons.timer),
                    label: Text('Timer'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: Text('Countdowns'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune),
                    label: Text('Settings'),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),
          ],
          Expanded(
            child: Stack(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: KeyedSubtree(
                    key: ValueKey(_index),
                    child: _screens[_index],
                  ),
                ),
                // Only show watermark on Clock, Timer, Countdowns (not Settings), and never while UI is hidden.
                if (_index != 3 && !uiHidden)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Text(
                      'Minimal Clock by Ivaan',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1,
                        color: color.withValues(alpha: 0.18),
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
