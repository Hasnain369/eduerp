import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/teacher_class_repository.dart';
import '../../../providers/auth_provider.dart';
import '../teacher_portal_routes.dart';
import '../teacher_section_screen.dart';
import 'attendance_roster_screen.dart';

const _attendanceBlue = Color(0xFF3448B0);
const _attendanceInk = Color(0xFF20212B);
const _attendanceMuted = Color(0xFF747688);

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<_ClassAttendanceSummary> _classes = const [];

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final teacher = ref.read(authStateNotifierProvider).user;
    if (teacher == null || !teacher.canAccessTeacherFeatures) {
      setState(() {
        _classes = const [];
        _isLoading = false;
        _errorMessage =
            'Your teacher profile must be approved before you can manage attendance.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(teacherClassRepositoryProvider);
      final classes = await repository.getClasses(
        teacherId: teacher.id,
        assignedSections: teacher.classSections,
      );
      final dateKey = _dateKey();
      final managedRepository = repository is ManagedTeacherClassRepository
          ? repository as ManagedTeacherClassRepository
          : null;
      final summaries = await Future.wait(
        classes.map((teacherClass) async {
          final students = await repository.getStudents(
            teacherId: teacher.id,
            classId: teacherClass.id,
          );
          final savedStatuses = managedRepository == null
              ? const <String, String>{}
              : await managedRepository.getClassAttendance(
                  teacherId: teacher.id,
                  classId: teacherClass.id,
                  dateKey: dateKey,
                );
          final studentIds = students.map((student) => student.id).toSet();
          final statuses = {
            for (final entry in savedStatuses.entries)
              if (studentIds.contains(entry.key)) entry.key: entry.value,
          };
          return _ClassAttendanceSummary(
            teacherClass: teacherClass,
            studentCount: students.length,
            statuses: statuses,
          );
        }),
      );

      if (!mounted) return;
      setState(() {
        _classes = summaries;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = attendanceErrorMessage(error);
      });
    }
  }

  Future<void> _openClass(_ClassAttendanceSummary summary) async {
    final teacher = ref.read(authStateNotifierProvider).user;
    if (teacher == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AttendanceRosterScreen(
          teacherClass: summary.teacherClass,
          teacherId: teacher.id,
        ),
      ),
    );
    if (mounted) await _loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return TeacherPortalScaffold(
      activeRoute: TeacherPortalRoutes.attendance,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 17, 16, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Attendance',
                    style: TextStyle(
                      color: _attendanceInk,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _formatDate(DateTime.now()),
                  style: const TextStyle(
                    color: _attendanceMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh attendance',
                  onPressed: _isLoading ? null : _loadAttendance,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 15),
            child: Text(
              'Choose one of your classes to take attendance.',
              style: TextStyle(color: _attendanceMuted, fontSize: 15),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return _AttendanceMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load attendance',
        message: _errorMessage!,
        action: FilledButton.icon(
          onPressed: _loadAttendance,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    if (_classes.isEmpty) {
      return const _AttendanceMessage(
        icon: Icons.class_outlined,
        title: 'No classes assigned',
        message: 'Add classes to your teacher profile to take attendance.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAttendance,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 570 ? 2 : 1;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: columns == 2 ? 1.22 : 1.65,
            ),
            itemCount: _classes.length,
            itemBuilder: (context, index) {
              final summary = _classes[index];
              return _ClassAttendanceCard(
                summary: summary,
                onTap: () => _openClass(summary),
              );
            },
          );
        },
      ),
    );
  }
}

class _ClassAttendanceSummary {
  const _ClassAttendanceSummary({
    required this.teacherClass,
    required this.studentCount,
    required this.statuses,
  });

  final TeacherClass teacherClass;
  final int studentCount;
  final Map<String, String> statuses;
}

class _ClassAttendanceCard extends StatelessWidget {
  const _ClassAttendanceCard({required this.summary, required this.onTap});

  final _ClassAttendanceSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final details = AttendanceClassDetails.fromAssignment(
      summary.teacherClass.name,
    );
    final counts = {
      'present': summary.statuses.values
          .where((value) => value == 'present')
          .length,
      'absent': summary.statuses.values
          .where((value) => value == 'absent')
          .length,
      'late': summary.statuses.values      .where((value) => value == 'late')
      .length,
      'leave': summary.statuses.values
      .where((value) => value == 'leave').length,
    };
    final marked = counts.values.fold<int>(0, (sum, count) => sum + count);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shadowColor: const Color(0x140D1450),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: Color(0xFFECECF3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9ECFF),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: _attendanceBlue,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details.className,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _attendanceInk,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          details.section == 'Not specified'
                              ? 'Class roster'
                              : 'Section ${details.section}',
                          style: const TextStyle(
                            color: _attendanceMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: _attendanceMuted,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.people_alt_outlined,
                    size: 17,
                    color: _attendanceMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${summary.studentCount} students',
                    style: const TextStyle(
                      color: _attendanceInk,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$marked/${summary.studentCount} marked',
                    style: const TextStyle(
                      color: _attendanceMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatusPill(
                    label: 'Present',
                    count: counts['present']!,
                    color: const Color(0xFF26734D),
                  ),
                  const SizedBox(width: 6),
                  _StatusPill(
                    label: 'Absent',
                    count: counts['absent']!,
                    color: const Color(0xFFB13B3B),
                  ),
                  const SizedBox(width: 6),
                  _StatusPill(
                    label: 'Late',
                    count: counts['late']!,
                    color: const Color(0xFF976600),
                  ),
                  const SizedBox(width: 6),
                  _StatusPill(
                    label: 'Leave',
                    count: counts['leave']!,
                    color: const Color(0xFF5962A8),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $count',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _AttendanceMessage extends StatelessWidget {
  const _AttendanceMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: _attendanceBlue),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}

String _dateKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
