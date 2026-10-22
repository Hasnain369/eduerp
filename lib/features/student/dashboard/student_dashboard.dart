import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../screens/student_home_tab.dart';
import '../screens/student_menu_screen.dart';
import '../screens/student_results_screen.dart';
import '../screens/student_tasks_screen.dart';

class StudentDashboard extends ConsumerStatefulWidget {
  const StudentDashboard({super.key});

  @override
  ConsumerState<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends ConsumerState<StudentDashboard> {
  int _currentIndex = 0;

  static const _tabs = [
    _TabConfig(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _TabConfig(
      label: 'Tasks',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
    ),
    _TabConfig(
      label: 'Results',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
    ),
    _TabConfig(
      label: 'Menu',
      icon: Icons.menu_outlined,
      activeIcon: Icons.menu_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateNotifierProvider).user;
    if (user == null || !user.isStudent) {
      return const Scaffold(
        body: Center(child: Text('Please sign in with a student account.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        titleSpacing: 14,
        title: Row(
          children: [
            // School logo
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1A3A5C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 9),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Taleem Punjab',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  TextSpan(
                    text: '  |  ',
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: 'Educative',
                    style: TextStyle(
                      color: AppTheme.teal,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language toggle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'EN',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  ' | ',
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                ),
                Text(
                  'اُردو',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                    fontFamily: 'NotoNastaliqUrdu',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppTheme.accent,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(38),
          child: _OfflineStatusBar(),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          StudentHomeTab(),
          StudentTasksScreen(),
          StudentResultsScreen(),
          StudentMenuScreen(),
        ],
      ),
      bottomNavigationBar: _StudentBottomNav(
        currentIndex: _currentIndex,
        tabs: _tabs,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Offline Status Bar ───────────────────────────────────────────────────────
class _OfflineStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 38,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFBEB),
        border: Border(
          top: BorderSide(color: Color(0xFFFDE68A)),
          bottom: BorderSide(color: Color(0xFFFDE68A)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 14,
            color: Color(0xFF92400E),
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Working Offline',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            'Last synced 1 hr ago',
            style: TextStyle(
              color: Color(0xFFB45309),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.upload_rounded, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Tap to Sync',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Config ───────────────────────────────────────────────────────────────
class _TabConfig {
  const _TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

// ─── Bottom Navigation ────────────────────────────────────────────────────────
class _StudentBottomNav extends StatelessWidget {
  const _StudentBottomNav({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  final int currentIndex;
  final List<_TabConfig> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int i = 0; i < tabs.length; i++)
                _NavItem(
                  tab: tabs[i],
                  isActive: currentIndex == i,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final _TabConfig tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primary.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isActive ? tab.activeIcon : tab.icon,
                size: 22,
                color: isActive ? AppTheme.primary : AppTheme.mutedText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.primary : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
