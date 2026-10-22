import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../providers/auth_provider.dart';
import 'teacher_portal_routes.dart';

const _portalBlue = Color(0xFF3448B0);
const _portalCanvas = Color(0xFFF8F8FC);
const _portalInk = Color(0xFF20212B);
const _portalMuted = Color(0xFF747688);

class TeacherSectionScreen extends StatelessWidget {
  const TeacherSectionScreen({
    super.key,
    required this.title,
    required this.activeRoute,
  });

  final String title;
  final String activeRoute;

  @override
  Widget build(BuildContext context) {
    return TeacherPortalScaffold(
      activeRoute: activeRoute,
      body: activeRoute == TeacherPortalRoutes.menu
          ? _TeacherMenuPage(
              activeRoute: activeRoute,
              onSelect: (route) =>
                  Navigator.of(context).pushReplacementNamed(route),
            )
          : Semantics(label: title, child: const SizedBox.expand()),
    );
  }
}

class TeacherPortalScaffold extends ConsumerWidget {
  const TeacherPortalScaffold({
    super.key,
    required this.activeRoute,
    required this.body,
  });

  final String activeRoute;
  final Widget body;

  static const _tabs = [
    _PortalTab('Home', Icons.home_outlined, TeacherPortalRoutes.home),
    _PortalTab(
      'Timetable',
      Icons.calendar_month_outlined,
      TeacherPortalRoutes.timetable,
    ),
    _PortalTab(
      'Attendance',
      Icons.fact_check_outlined,
      TeacherPortalRoutes.attendance,
    ),
  ];

  void _goTo(BuildContext context, String route) {
    if (route == activeRoute) return;
    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateNotifierProvider).user;
    final isUrdu = ref.watch(appLocaleProvider).languageCode == 'ur';
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 720;
    final bottomTabs = [
      _tabs[0],
      _tabs[1],
      _tabs[2],
      _PortalTab(
        isUrdu ? 'مینو' : 'Menu',
        Icons.menu_rounded,
        TeacherPortalRoutes.menu,
      ),
    ];

    return Scaffold(
      backgroundColor: _portalCanvas,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isWide ? 64 : 54),
        child: _TeacherTopBar(
          isUrdu: isUrdu,
          schoolName: user?.schoolId.isNotEmpty == true
              ? user!.schoolId
              : 'Govt Model HSS Lahore',
          onNotifications: () =>
              _goTo(context, TeacherPortalRoutes.notifications),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: body,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 62,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE9E9F0))),
          ),
          child: Row(
            children: [
              for (final tab in bottomTabs)
                Expanded(
                  child: _BottomTabButton(
                    tab: tab,
                    selected: tab.route == activeRoute,
                    isUrdu: isUrdu,
                    onTap: () => _goTo(context, tab.route),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortalTab {
  const _PortalTab(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

class _TeacherTopBar extends ConsumerWidget {
  const _TeacherTopBar({
    required this.isUrdu,
    required this.schoolName,
    required this.onNotifications,
  });

  final bool isUrdu;
  final String schoolName;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: _portalInk,
      elevation: 0,
      titleSpacing: 14,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: _portalBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school_outlined,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrdu ? 'پنجاب تعلیم پورٹل' : 'Punjab Taleem Portal',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: _portalBlue,
                  ),
                ),
                Text(
                  schoolName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.25,
                    color: _portalMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F0F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              _LanguageButton(
                label: 'EN',
                selected: !isUrdu,
                onTap: () => ref.read(appLocaleProvider.notifier).state =
                    const Locale('en'),
              ),
              _LanguageButton(
                label: 'اردو',
                selected: isUrdu,
                onTap: () => ref.read(appLocaleProvider.notifier).state =
                    const Locale('ur'),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: isUrdu ? 'اطلاعات' : 'Notifications',
          onPressed: onNotifications,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, size: 23),
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD92332),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
      ],
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? _portalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            height: 1.2,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _portalMuted,
          ),
        ),
      ),
    );
  }
}

class _BottomTabButton extends StatelessWidget {
  const _BottomTabButton({
    required this.tab,
    required this.selected,
    required this.isUrdu,
    required this.onTap,
  });

  final _PortalTab tab;
  final bool selected;
  final bool isUrdu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = switch (tab.label) {
      'Home' => isUrdu ? 'ہوم' : 'Home',
      'Timetable' => isUrdu ? 'ٹائم ٹیبل' : 'Timetable',
      'Attendance' => isUrdu ? 'حاضری' : 'Attendance',
      _ => tab.label,
    };
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE1E3FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              tab.icon,
              size: 19,
              color: selected ? _portalBlue : _portalInk,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _portalBlue : _portalInk,
              fontSize: 11,
              height: 1.2,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherMenuPage extends ConsumerWidget {
  const _TeacherMenuPage({required this.activeRoute, required this.onSelect});

  final String activeRoute;
  final ValueChanged<String> onSelect;

  static const _items = [
    _MenuItem(
      'Profile Setup',
      Icons.person_outline_rounded,
      TeacherPortalRoutes.profile,
    ),
    _MenuItem('Classes', Icons.class_outlined, TeacherPortalRoutes.classes),
    _MenuItem(
      'Plan Lecture',
      Icons.menu_book_outlined,
      TeacherPortalRoutes.planLecture,
    ),
    _MenuItem(
      'Create Quiz',
      Icons.quiz_outlined,
      TeacherPortalRoutes.createQuiz,
    ),
    _MenuItem(
      'Assignments',
      Icons.assignment_outlined,
      TeacherPortalRoutes.assignments,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateNotifierProvider).user;
    final isUrdu = ref.watch(appLocaleProvider).languageCode == 'ur';
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 22, 10, 14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE7E9FF),
                  foregroundColor: _portalBlue,
                  backgroundImage: user?.photoUrl?.isNotEmpty == true
                      ? NetworkImage(user!.photoUrl!)
                      : null,
                  child: user?.photoUrl?.isNotEmpty == true
                      ? null
                      : const Icon(Icons.person_outline),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? (isUrdu ? 'استاد' : 'Teacher'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _portalInk,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        user?.designation.isNotEmpty == true
                            ? user!.designation
                            : (isUrdu ? 'استاد پورٹل' : 'Teacher portal'),
                        style: const TextStyle(
                          color: _portalMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: isUrdu ? 'لاگ آؤٹ' : 'Log out',
                  onPressed: () async {
                    await ref.read(authStateNotifierProvider.notifier).logout();
                    if (!context.mounted) return;
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/login', (route) => false);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  color: _portalMuted,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
              children: [
                for (final item in _items)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(item.icon, color: _portalBlue),
                    title: Text(item.label),
                    trailing: const Icon(Icons.chevron_right_rounded, size: 19),
                    selected: activeRoute == item.route,
                    onTap: () => onSelect(item.route),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}
