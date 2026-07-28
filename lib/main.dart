// lib/main.dart — App entry point
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'providers/progress_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/subtes_list_screen.dart';
import 'screens/subtes_screen.dart';
import 'screens/tambah_screen.dart';
import 'screens/pengaturan_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow google_fonts to cache fonts
  GoogleFonts.config.allowRuntimeFetching = true;

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
      title: 'SNBT Study Tracker',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AppShell(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/subtes':
            final id = settings.arguments as String;
            return PageRouteBuilder(
              pageBuilder: (_, anim, __) => SubtesScreen(subtestId: id),
              transitionsBuilder: (_, anim, __, child) {
                return SlideTransition(
                  position: Tween(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                  child: child,
                );
              },
            );
        }
        return null;
      },
    );
  }
}

class _AppShell extends StatefulWidget {
  const _AppShell();

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<AnimationController> _tabControllers;

  final _pages = const [
    DashboardScreen(),
    SubtesListScreen(),
    TambahScreen(),
    PengaturanScreen(),
  ];

  final _tabs = const [
    _NavItem(icon: Icons.home_rounded, label: 'Beranda'),
    _NavItem(icon: Icons.menu_book_rounded, label: 'Subtes'),
    _NavItem(icon: Icons.add_circle_outline_rounded, label: 'Tambah'),
    _NavItem(icon: Icons.settings_rounded, label: 'Setelan'),
  ];

  @override
  void initState() {
    super.initState();
    _tabControllers = List.generate(
      _tabs.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
    _tabControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _tabControllers) c.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == _currentIndex) return;
    _tabControllers[_currentIndex].reverse();
    _tabControllers[index].forward();
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
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
        controllers: _tabControllers,
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
  final List<AnimationController> controllers;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.currentIndex,
    required this.tabs,
    required this.controllers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.dark, width: 2)),
        boxShadow: [BoxShadow(color: AppColors.dark, offset: Offset(0, -3), blurRadius: 0)],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isSelected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedBuilder(
                    animation: controllers[i],
                    builder: (_, __) {
                      final t = controllers[i].value;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.scale(
                            scale: 0.9 + 0.1 * t,
                            child: Container(
                              width: 40,
                              height: 32,
                              decoration: isSelected
                                  ? BoxDecoration(
                                      color: AppColors.yellow,
                                      borderRadius: AppRadius.pill,
                                    )
                                  : null,
                              child: Icon(
                                tab.icon,
                                size: 22,
                                color: isSelected ? AppColors.dark : AppColors.hint,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppColors.dark : AppColors.hint,
                            ),
                          ),
                        ],
                      );
                    },
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

