import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/dashboard_components.dart';
import '../../core/widgets/dashboard_scaffold.dart';
import '../../core/widgets/stat_card.dart';
import '../../data/repositories/admin_repository.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _teachers = const <UserModel>[];
  String _searchTerm = '';
  String _statusFilter = 'all';

  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _schoolControllers = {};
  final Map<String, TextEditingController> _subjectControllers = {};
  final Map<String, TextEditingController> _classControllers = {};

  List<UserModel> get _filteredTeachers {
    final query = _searchTerm.trim().toLowerCase();
    final teachers = _teachers.where((teacher) {
      final matchesStatus = switch (_statusFilter) {
        'pending' => !teacher.isApproved && !teacher.isRejected,
        'approved' => teacher.isApproved,
        'rejected' => teacher.isRejected,
        _ => true,
      };

      if (!matchesStatus) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final haystack = [
        teacher.name,
        teacher.email,
        teacher.schoolId,
        teacher.teacherId,
        teacher.designation,
        teacher.subjects.join(' '),
        teacher.classSections.join(' '),
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();

    teachers.sort((a, b) {
      final approvalRank = a.isApproved ? 1 : 0;
      final approvalRankB = b.isApproved ? 1 : 0;
      final compareApproval = approvalRankB.compareTo(approvalRank);
      if (compareApproval != 0) {
        return compareApproval;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return teachers;
  }

  @override
  void initState() {
    super.initState();
    _loadTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _schoolControllers.values) {
      controller.dispose();
    }
    for (final controller in _subjectControllers.values) {
      controller.dispose();
    }
    for (final controller in _classControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teachers = await ref
          .read(adminRepositoryProvider)
          .getTeachersForApproval();
      setState(() {
        _teachers = teachers;
        _isLoading = false;
      });

      for (final teacher in teachers) {
        _schoolControllers.putIfAbsent(
          teacher.id,
          () => TextEditingController(text: teacher.schoolId),
        );
        _subjectControllers.putIfAbsent(
          teacher.id,
          () => TextEditingController(text: teacher.subjects.join(', ')),
        );
        _classControllers.putIfAbsent(
          teacher.id,
          () => TextEditingController(text: teacher.classSections.join(', ')),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Future<void> _approveTeacher(UserModel teacher) async {
    final schoolController = _schoolControllers[teacher.id];
    final subjectsController = _subjectControllers[teacher.id];
    final classesController = _classControllers[teacher.id];

    final schoolId = schoolController?.text ?? teacher.schoolId;
    final subjects = (subjectsController?.text ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    final classes = (classesController?.text ?? '')
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    try {
      await ref
          .read(adminRepositoryProvider)
          .approveTeacher(
            uid: teacher.id,
            schoolId: schoolId,
            subjects: subjects,
            classSections: classes,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teacher ${teacher.name} has been approved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadTeachers();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectTeacher(UserModel teacher) async {
    try {
      await ref.read(adminRepositoryProvider).rejectTeacher(uid: teacher.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Teacher ${teacher.name} was rejected.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _loadTeachers();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTeachers = _filteredTeachers;
    final admin = ref.watch(authStateNotifierProvider).user;
    final pendingCount = _teachers
        .where((teacher) => !teacher.isApproved && !teacher.isRejected)
        .length;
    final classCount = _teachers
        .expand((teacher) => teacher.classSections)
        .map((section) => section.trim().toLowerCase())
        .where((section) => section.isNotEmpty)
        .toSet()
        .length;

    return DashboardScaffold(
      title: 'Administration',
      role: 'Administrator',
      activeRoute: AppRouter.adminDashboard,
      userName: admin?.name ?? 'Administrator',
      userDetail: admin?.email ?? 'School administration',
      destinations: const [
        DashboardDestination(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          route: AppRouter.adminDashboard,
        ),
      ],
      onLogout: () async {
        await ref.read(authStateNotifierProvider.notifier).logout();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
        }
      },
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? EmptyStateWidget(
              icon: Icons.cloud_off_outlined,
              title: 'Could not load teacher applications',
              message: _errorMessage!,
              action: FilledButton.icon(
                onPressed: _loadTeachers,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth < 480 ? 2 : 4;
                final tileWidth =
                    (constraints.maxWidth - 40 - (columns - 1) * 12) / columns;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    WelcomeBanner(
                      name: admin?.name ?? 'Administrator',
                      roleLabel: 'School management',
                      message: 'Review applications and manage teacher access.',
                      detail: admin?.schoolId.isNotEmpty == true
                          ? admin!.schoolId
                          : admin?.email,
                      photoUrl: admin?.photoUrl,
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount: columns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: tileWidth < 190
                          ? tileWidth / 165
                          : 1.45,
                      children: [
                        const StatCard(
                          label: 'Students',
                          value: '—',
                          subtitle: 'Student directory unavailable',
                          icon: Icons.groups_outlined,
                          color: Color(0xFF557AA5),
                        ),
                        StatCard(
                          label: 'Teachers',
                          value: '${_teachers.length}',
                          subtitle: 'Teacher accounts',
                          icon: Icons.co_present_outlined,
                          color: AppTheme.primary,
                        ),
                        StatCard(
                          label: 'Classes',
                          value: '$classCount',
                          subtitle: 'Unique assigned sections',
                          icon: Icons.class_outlined,
                          color: AppTheme.teal,
                        ),
                        StatCard(
                          label: 'Pending approvals',
                          value: '$pendingCount',
                          subtitle: 'Applications to review',
                          icon: Icons.pending_actions_outlined,
                          color: AppTheme.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Teacher applications',
                      subtitle:
                          '${filteredTeachers.length} accounts match this view',
                    ),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchTerm = value),
                      decoration: const InputDecoration(
                        labelText: 'Search teachers or schools',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<String>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: 'all', label: Text('All')),
                          ButtonSegment(
                            value: 'pending',
                            label: Text('Pending'),
                          ),
                          ButtonSegment(
                            value: 'approved',
                            label: Text('Approved'),
                          ),
                          ButtonSegment(
                            value: 'rejected',
                            label: Text('Rejected'),
                          ),
                        ],
                        selected: {_statusFilter},
                        onSelectionChanged: (selection) =>
                            setState(() => _statusFilter = selection.first),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (filteredTeachers.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.person_search_outlined,
                        title: _searchTerm.isEmpty
                            ? 'No teacher accounts in this view'
                            : 'No matching teachers',
                        message: _searchTerm.isEmpty
                            ? 'Teacher applications will appear here.'
                            : 'Try another name, email, school, or status filter.',
                      )
                    else
                      for (final teacher in filteredTeachers)
                        _TeacherApplicationCard(
                          teacher: teacher,
                          schoolController: _schoolControllers[teacher.id]!,
                          subjectController: _subjectControllers[teacher.id]!,
                          classController: _classControllers[teacher.id]!,
                          onApprove: () => _approveTeacher(teacher),
                          onReject: () => _rejectTeacher(teacher),
                        ),
                  ],
                );
              },
            ),
    );
  }
}

class _TeacherApplicationCard extends StatelessWidget {
  const _TeacherApplicationCard({
    required this.teacher,
    required this.schoolController,
    required this.subjectController,
    required this.classController,
    required this.onApprove,
    required this.onReject,
  });

  final UserModel teacher;
  final TextEditingController schoolController;
  final TextEditingController subjectController;
  final TextEditingController classController;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final statusColor = teacher.isApproved
        ? AppTheme.success
        : teacher.isRejected
        ? AppTheme.error
        : AppTheme.warning;
    final status = teacher.isApproved
        ? 'Approved'
        : teacher.isRejected
        ? 'Rejected'
        : 'Pending';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primarySoft,
          foregroundColor: AppTheme.primary,
          child: Text(
            teacher.name.isEmpty ? '?' : teacher.name[0].toUpperCase(),
          ),
        ),
        title: Text(teacher.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          teacher.email,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(status, style: TextStyle(color: statusColor)),
        ),
        children: [
          _TeacherDetail(label: 'Teacher ID', value: teacher.teacherId),
          _TeacherDetail(label: 'Designation', value: teacher.designation),
          _TeacherDetail(label: 'Current school', value: teacher.schoolId),
          _TeacherDetail(label: 'Subjects', value: teacher.subjects.join(', ')),
          _TeacherDetail(
            label: 'Classes',
            value: teacher.classSections.join(', '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: schoolController,
            decoration: const InputDecoration(labelText: 'School ID'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: subjectController,
            decoration: const InputDecoration(
              labelText: 'Subjects (comma separated)',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: classController,
            decoration: const InputDecoration(
              labelText: 'Classes / sections (comma separated)',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeacherDetail extends StatelessWidget {
  const _TeacherDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(child: Text(value.isEmpty ? 'Not provided' : value)),
        ],
      ),
    );
  }
}
