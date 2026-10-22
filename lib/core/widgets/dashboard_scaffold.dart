import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DashboardDestination {
  const DashboardDestination({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class DashboardScaffold extends StatelessWidget {
  const DashboardScaffold({
    super.key,
    required this.title,
    required this.role,
    required this.activeRoute,
    required this.userName,
    required this.userDetail,
    required this.destinations,
    required this.onLogout,
    required this.body,
    this.actions = const [],
  });

  final String title;
  final String role;
  final String activeRoute;
  final String userName;
  final String userDetail;
  final List<DashboardDestination> destinations;
  final VoidCallback onLogout;
  final Widget body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1000;
    if (!isDesktop) {
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          actions: actions,
          leading: Builder(
            builder: (context) => IconButton(
              tooltip: 'Open navigation',
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: _DashboardNavigation(
          role: role,
          activeRoute: activeRoute,
          userName: userName,
          userDetail: userDetail,
          destinations: destinations,
          onLogout: onLogout,
          inDrawer: true,
        ),
        body: SafeArea(child: body),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _CollapsibleDashboardSidebar(
            role: role,
            activeRoute: activeRoute,
            userName: userName,
            userDetail: userDetail,
            destinations: destinations,
            onLogout: onLogout,
          ),
          Expanded(
            child: Column(
              children: [
                AppBar(title: Text(title), actions: actions),
                Expanded(child: SafeArea(child: body)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsibleDashboardSidebar extends StatefulWidget {
  const _CollapsibleDashboardSidebar({
    required this.role,
    required this.activeRoute,
    required this.userName,
    required this.userDetail,
    required this.destinations,
    required this.onLogout,
  });

  final String role;
  final String activeRoute;
  final String userName;
  final String userDetail;
  final List<DashboardDestination> destinations;
  final VoidCallback onLogout;

  @override
  State<_CollapsibleDashboardSidebar> createState() =>
      _CollapsibleDashboardSidebarState();
}

class _CollapsibleDashboardSidebarState
    extends State<_CollapsibleDashboardSidebar> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final width = _collapsed ? 78.0 : 252.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.border)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(_collapsed ? 12 : 18, 18, 10, 18),
              child: Row(
                children: [
                  const _SchoolMark(size: 40),
                  if (!_collapsed) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'SchoolHub',
                        maxLines: 1,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                  ],
                  IconButton(
                    tooltip: _collapsed ? 'Expand sidebar' : 'Collapse sidebar',
                    onPressed: () => setState(() => _collapsed = !_collapsed),
                    icon: Icon(
                      _collapsed
                          ? Icons.chevron_right_rounded
                          : Icons.chevron_left_rounded,
                    ),
                  ),
                ],
              ),
            ),
            if (!_collapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.role.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _DestinationList(
                destinations: widget.destinations,
                activeRoute: widget.activeRoute,
                collapsed: _collapsed,
              ),
            ),
            _ProfileFooter(
              name: widget.userName,
              detail: widget.userDetail,
              collapsed: _collapsed,
              onLogout: widget.onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardNavigation extends StatelessWidget {
  const _DashboardNavigation({
    required this.role,
    required this.activeRoute,
    required this.userName,
    required this.userDetail,
    required this.destinations,
    required this.onLogout,
    required this.inDrawer,
  });

  final String role;
  final String activeRoute;
  final String userName;
  final String userDetail;
  final List<DashboardDestination> destinations;
  final VoidCallback onLogout;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const _SchoolMark(size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SchoolHub',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppTheme.accent,
                          ),
                        ),
                        Text(
                          role,
                          style: const TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _DestinationList(
                destinations: destinations,
                activeRoute: activeRoute,
                inDrawer: inDrawer,
              ),
            ),
            _ProfileFooter(
              name: userName,
              detail: userDetail,
              onLogout: onLogout,
              inDrawer: inDrawer,
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationList extends StatelessWidget {
  const _DestinationList({
    required this.destinations,
    required this.activeRoute,
    this.collapsed = false,
    this.inDrawer = false,
  });

  final List<DashboardDestination> destinations;
  final String activeRoute;
  final bool collapsed;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? 8 : 12,
        vertical: 8,
      ),
      children: [
        for (final destination in destinations)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Tooltip(
              message: collapsed ? destination.label : '',
              child: ListTile(
                minLeadingWidth: 22,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: collapsed ? 18 : 12,
                  vertical: 1,
                ),
                leading: Icon(
                  destination.icon,
                  size: 20,
                  color: activeRoute == destination.route
                      ? AppTheme.primary
                      : AppTheme.mutedText,
                ),
                title: collapsed
                    ? null
                    : Text(
                        destination.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                selected: activeRoute == destination.route,
                selectedColor: AppTheme.primary,
                selectedTileColor: AppTheme.primarySoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  if (inDrawer) Navigator.of(context).pop();
                  if (activeRoute != destination.route) {
                    Navigator.of(context).pushNamed(destination.route);
                  }
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileFooter extends StatelessWidget {
  const _ProfileFooter({
    required this.name,
    required this.detail,
    required this.onLogout,
    this.collapsed = false,
    this.inDrawer = false,
  });

  final String name;
  final String detail;
  final VoidCallback onLogout;
  final bool collapsed;
  final bool inDrawer;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      padding: EdgeInsets.fromLTRB(collapsed ? 9 : 14, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: AppTheme.accentMint,
            foregroundColor: AppTheme.teal,
            child: Text(
              initial,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
          IconButton(
            tooltip: 'Log out',
            onPressed: () {
              if (inDrawer) Navigator.of(context).pop();
              onLogout();
            },
            icon: const Icon(Icons.logout_rounded, size: 19),
            color: AppTheme.mutedText,
          ),
        ],
      ),
    );
  }
}

class _SchoolMark extends StatelessWidget {
  const _SchoolMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.school_rounded,
        color: AppTheme.primary,
        size: 22,
      ),
    );
  }
}
