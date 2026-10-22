import 'package:flutter/material.dart';

import '../routes/app_router.dart';

class SchoolDrawer extends StatelessWidget {
  const SchoolDrawer({
    super.key,
    required this.role,
    required this.activeRoute,
    required this.onLogout,
  });

  final String role;
  final String activeRoute;
  final VoidCallback onLogout;

  static const List<_DrawerItem> _studentItems = [
    _DrawerItem('Profile', 'profile'),
    _DrawerItem('Dashboard', 'dashboard'),
    _DrawerItem('My Attendance', 'attendance'),
    _DrawerItem('Assignments', 'assignments'),
    _DrawerItem('Results', 'results'),
    _DrawerItem('Class Schedule', 'schedule'),
    _DrawerItem('Notices', 'notices'),
    _DrawerItem('Settings', 'settings'),
    _DrawerItem('Logout', 'logout'),
  ];

  static const List<_DrawerItem> _teacherItems = [
    _DrawerItem('Profile Setup', 'setup-profile'),
    _DrawerItem('Classes', 'classes'),
    _DrawerItem('Attendance', 'attendance'),
    _DrawerItem('Assignments', 'assignments'),
    _DrawerItem('Planner', 'planner'),
    _DrawerItem('Logout', 'logout'),
  ];

  static const List<_DrawerItem> _adminItems = [
    _DrawerItem('Dashboard', 'dashboard'),
    _DrawerItem('Teacher Approvals', 'approvals'),
    _DrawerItem('Schools', 'schools'),
    _DrawerItem('Reports', 'reports'),
    _DrawerItem('Settings', 'settings'),
    _DrawerItem('Logout', 'logout'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = switch (role) {
      'teacher' => _teacherItems,
      'admin' => _adminItems,
      _ => _studentItems,
    };
    final roleMark = switch (role) {
      'teacher' => 'T',
      'admin' => 'A',
      _ => 'S',
    };

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.08),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      roleMark,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          switch (role) {
                            'teacher' => 'Teacher Portal',
                            'admin' => 'Admin Portal',
                            _ => 'Student Portal',
                          },
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          switch (role) {
                            'teacher' => 'School management',
                            'admin' => 'Approval and access control',
                            _ => 'Learning dashboard',
                          },
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isActive = activeRoute == item.route;
                  final isLogout = item.route == 'logout';

                  return ListTile(
                    leading: Icon(
                      isLogout
                          ? Icons.logout_rounded
                          : Icons.chevron_right_rounded,
                      color: isLogout ? Colors.red.shade600 : null,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isLogout ? Colors.red.shade700 : null,
                      ),
                    ),
                    selected: isActive,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();

                      if (isLogout) {
                        onLogout();
                        return;
                      }

                      if (role == 'teacher') {
                        final route = _teacherRouteFor(item.route);
                        if (route == null) {
                          return;
                        }
                        Navigator.of(
                          context,
                        ).pushNamed(route, arguments: item.title);
                        return;
                      }

                      if (role == 'admin') {
                        final route = _adminRouteFor(item.route);
                        if (route == null) {
                          return;
                        }
                        Navigator.of(
                          context,
                        ).pushNamed(route, arguments: item.title);
                        return;
                      }

                      Navigator.of(
                        context,
                      ).pushNamed(AppRouter.studentDashboard);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _teacherRouteFor(String route) {
    switch (route) {
      case 'setup-profile':
        return AppRouter.teacherProfileSetup;
      case 'classes':
        return AppRouter.teacherClasses;
      case 'attendance':
        return AppRouter.teacherAttendance;
      case 'assignments':
        return AppRouter.teacherAssignments;
      case 'planner':
        return AppRouter.teacherPlanner;
      default:
        return null;
    }
  }

  static String? _adminRouteFor(String route) {
    switch (route) {
      case 'dashboard':
        return AppRouter.adminDashboard;
      case 'approvals':
        return AppRouter.adminDashboard;
      case 'schools':
      case 'reports':
      case 'settings':
        return AppRouter.adminDashboard;
      default:
        return null;
    }
  }
}

class _DrawerItem {
  const _DrawerItem(this.title, this.route);

  final String title;
  final String route;
}
