import 'package:flutter/material.dart';
import '../../features/clock/clock_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/settings/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    ClockScreen(),
    TimerScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final railBg = Theme.of(context).navigationRailTheme.backgroundColor;

    return Scaffold(
      body: Row(
        children: [
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
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('Settings'),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: KeyedSubtree(
                key: ValueKey(_index),
                child: _screens[_index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
