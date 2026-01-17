import 'package:flutter/material.dart';

import '../core/app_strings.dart';
import 'home_page.dart';
import 'tools_page.dart';
import 'hex_map_page.dart';
import 'reports_page.dart';
import 'profile_page.dart';

/// Main Scaffold with bottom navigation bar (5 tabs)
/// Designed to match SmartVibes app style with deep gradient background
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Pages for each tab - using IndexedStack to preserve state
  final List<Widget> _pages = [
    const HomePage(),
    const ToolsPage(),
    HexMapPage(), // Existing map page
    const ReportsPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          border: Border(
            top: BorderSide(
              color: Colors.purpleAccent.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'nav_home'),
                _buildNavItem(1, Icons.handyman_rounded, 'nav_tools'),
                _buildNavItem(2, Icons.map_rounded, 'nav_map'),
                _buildNavItem(3, Icons.assessment_rounded, 'nav_reports'),
                _buildNavItem(4, Icons.person_rounded, 'nav_profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String labelKey) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.cyanAccent : Colors.white54,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              AppStrings.t(labelKey),
              style: TextStyle(
                color: isSelected ? Colors.cyanAccent : Colors.white54,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
