// lib/main.dart -- App entry point
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'providers/progress_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/materi_screen.dart';
import 'screens/tryout_screen.dart';
import 'screens/riwayat_screen.dart';
import 'screens/subtes_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  Intl.defaultLocale = 'id';
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProgressProvider()..init()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
      ],
      child: const SnbtApp(),
    ),
  );
}

class SnbtApp extends StatelessWidget {
  const SnbtApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNBT Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AppShell(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/subtes':
            final id = settings.arguments as String;
            return PageRouteBuilder(
              pageBuilder: (_, anim, _x) => SubtesScreen(subtestId: id),
              transitionsBuilder: (_, anim, _x, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                );
              },
            );
          default:
            return null;
        }
      },
    );
  }
}

// -- App Shell (4-tab bottom nav) --
class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardScreen(),
    MateriScreen(),
    TryoutScreen(),
    RiwayatScreen(),
  ];

  final _tabs = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Study'),
    _NavItem(icon: Icons.star_rounded, label: 'Tryout'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'History'),
  ];

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: child,
        ),
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        tabs: _tabs,
        onTap: _onTabTap,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> tabs;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 44 : 36,
                          height: 32,
                          decoration: isSelected
                              ? BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: AppRadius.pill,
                                )
                              : null,
                          child: Icon(
                            tab.icon,
                            size: 20,
                            color: isSelected
                                ? AppColors.bg
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
