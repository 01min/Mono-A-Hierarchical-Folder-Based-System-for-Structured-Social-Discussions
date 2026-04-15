import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'spaces_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    const SpacesScreen(),
    const ProfileScreen(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tabParam = GoRouterState.of(context).uri.queryParameters['tab'];
    if (tabParam != null) {
      final tabIndex = int.tryParse(tabParam);
      if (tabIndex != null && tabIndex >= 0 && tabIndex < _screens.length) {
        if (_currentIndex != tabIndex) {
          setState(() => _currentIndex = tabIndex);
        }
      }
    }
  }

  void _onTabTapped(int index) {
    if (_currentIndex != index) {
      HapticFeedback.lightImpact();
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    const creamColor = Color(0xFFF7F2E8);
    const pureBlack = Color(0xFF000000);

    return Scaffold(
      backgroundColor: pureBlack,
      extendBody: true,
      body: Stack(
        children: [
          // Background Depth Hints
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    creamColor.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Screen Content
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),

          // Navigation Bar (4 Items)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 72,
                  decoration: BoxDecoration(
                    color: creamColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: creamColor.withValues(alpha: 0.1),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.auto_awesome_motion_rounded, Icons.auto_awesome_motion_outlined),
                      _buildNavItem(1, Icons.search_rounded, Icons.search_outlined),
                      _buildNavItem(2, Icons.folder_copy_rounded, Icons.folder_copy_outlined),
                      _buildNavItem(3, Icons.person_rounded, Icons.person_outlined),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon) {
    final isSelected = _currentIndex == index;
    const creamColor = Color(0xFFF7F2E8);

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? creamColor : creamColor.withValues(alpha: 0.3),
              size: 26,
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(top: 6),
              width: isSelected ? 4 : 0,
              height: 4,
              decoration: const BoxDecoration(
                color: creamColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
