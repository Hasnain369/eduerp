import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/teacher_class_repository.dart';
import '../teacher_portal_routes.dart';
import '../teacher_section_screen.dart';

const _rosterBlue = Color(0xFF3448B0);
const _rosterInk = Color(0xFF20212B);
const _rosterMuted = Color(0xFF747688);

class AttendanceRosterScreen extends ConsumerStatefulWidget {
  const AttendanceRosterScreen({
    super.key,
    required this.teacherClass,
    required this.teacherId,
  });

  final TeacherClass teacherClass;
  final String teacherId;

  @override
  ConsumerState<AttendanceRosterScreen> createState() =>
      _AttendanceRosterScreenState();
}

class _AttendanceRosterScreenState
    extends ConsumerState<AttendanceRosterScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _filter = 'All';
  String _search = '';
  late final String _dateKey = _todayKey();
  List<ClassStudent> _students = const [];
  Map<String, String> _statuses = {};
  Map<String, String> _savedStatuses = {};

  bool get _hasChanges {
    if (_statuses.length != _savedStatuses.length) return true;
    return _statuses.entries.any(
      (entry) => _savedStatuses[entry.key] != entry.value,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRoster();
  }

  Future<void> _loadRoster() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(teacherClassRepositoryProvider);
      final students = await repository.getStudents(
        teacherId: widget.teacherId,
        classId: widget.teacherClass.id,
      );
      if (repository is! ManagedTeacherClassRepository) {
        throw StateError(
          'Class attendance is not supported by this repository.',
        );
      }
      final managedRepository = repository as ManagedTeacherClassRepository;
      final statuses = await managedRepository.getClassAttendance(
        teacherId: widget.teacherId,
        classId: widget.teacherClass.id,
        dateKey: _dateKey,
      );
      if (!mounted) return;
      setState(() {
        _students = students;
        _statuses = Map.of(statuses);
        _savedStatuses = Map.of(statuses);
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

  Future<void> _saveAttendance() async {
    if (!_hasChanges || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final repository = ref.read(teacherClassRepositoryProvider);
      if (repository is! ManagedTeacherClassRepository) {
        throw StateError(
          'Class attendance is not supported by this repository.',
        );
      }
      final managedRepository = repository as ManagedTeacherClassRepository;
      final studentIds = _students.map((student) => student.id).toSet();
      final statuses = {
        for (final entry in _statuses.entries)
          if (studentIds.contains(entry.key)) entry.key: entry.value,
      };
      await managedRepository.saveClassAttendance(
        classId: widget.teacherClass.id,
        dateKey: _dateKey,
        teacherId: widget.teacherId,
        statuses: statuses,
      );
      if (!mounted) return;
      setState(() {
        _statuses = statuses;
        _savedStatuses = Map.of(statuses);
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Attendance saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attendanceErrorMessage(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _setStatus(String studentId, String status) {
    setState(() {
      if (_statuses[studentId] == status) {
        _statuses.remove(studentId);
      } else {
        _statuses[studentId] = status;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final details = AttendanceClassDetails.fromAssignment(
      widget.teacherClass.name,
    );
    return TeacherPortalScaffold(
      activeRoute: TeacherPortalRoutes.attendance,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 16, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to attendance',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.className,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _rosterInk,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        details.section == 'Not specified'
                            ? 'Attendance'
                            : 'Section ${details.section} · Attendance',
                        style: const TextStyle(
                          color: _rosterMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh roster',
                  onPressed: _isLoading ? null : _loadRoster,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          if (!_isLoading && _errorMessage == null && _students.isNotEmpty)
            _buildSummary(),
          if (!_isLoading && _errorMessage == null && _students.isNotEmpty)
            _buildSearchAndFilters(),
          Expanded(child: _buildBody()),
          if (!_isLoading && _errorMessage == null && _students.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: !_hasChanges || _isSaving ? null : _saveAttendance,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Saving...' : 'Save attendance'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final present = _count('present');
    final absent = _count('absent');
    final late = _count('late');
    final leave = _count('leave');
    final attendanceRate = _students.isEmpty
        ? 0
        : (present * 100 / _students.length).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 9, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.groups_2_outlined, color: _rosterBlue, size: 21),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Class Strength',
                  style: TextStyle(
                    color: _rosterInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxWidth: 190),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E4FF),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  '${_students.length} Students • $attendanceRate% Rate',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _rosterBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryCount(
                label: 'Present',
                urduLabel: 'حاضر',
                count: present,
                color: const Color(0xFF16875F),
                icon: Icons.check_circle_outline_rounded,
              ),
              _SummaryCount(
                label: 'Absent',
                urduLabel: 'غیر حاضر',
                count: absent,
                color: const Color(0xFFC94141),
                icon: Icons.cancel_outlined,
              ),
              _SummaryCount(
                label: 'Late',
                urduLabel: 'تاخیر',
                count: late,
                color: const Color(0xFF986400),
                icon: Icons.access_time_rounded,
              ),
              _SummaryCount(
                label: 'Leave',
                urduLabel: 'رخصت',
                count: leave,
                color: const Color(0xFF3157A3),
                icon: Icons.event_busy_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final filters = [
      ('All', _students.length),
      ('Absent', _count('absent')),
      ('Late', _count('late')),
      (
        'Unmarked',
        _students.length -
            _students
                .where((student) => _statuses.containsKey(student.id))
                .length,
      ),
      ('Present', _count('present')),
      ('Leave', _count('leave')),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _search = value.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by student name or roll number',
                    prefixIcon: const Icon(Icons.search_rounded),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F8),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(color: Color(0xFFE5E5ED)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: const BorderSide(color: Color(0xFFE5E5ED)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),
              IconButton(
                tooltip: 'Clear search and filters',
                onPressed: () => setState(() {
                  _search = '';
                  _filter = 'All';
                }),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F8),
                  side: const BorderSide(color: Color(0xFFE5E5ED)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final (filter, count) in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: ChoiceChip(
                      label: Text(
                        '$filter ($count)',
                        style: TextStyle(
                          color: _filter == filter ? Colors.white : _rosterInk,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selectedColor: _rosterBlue,
                      backgroundColor: const Color(0xFFF7F7FA),
                      side: BorderSide(
                        color: _filter == filter
                            ? _rosterBlue
                            : const Color(0xFFE4E4EC),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return _RosterMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load the class roster',
        message: _errorMessage!,
        action: FilledButton.icon(
          onPressed: _loadRoster,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    if (_students.isEmpty) {
      return const _RosterMessage(
        icon: Icons.people_outline_rounded,
        title: 'No students in this class',
        message: 'Add students in Classes before taking attendance.',
      );
    }
    final visibleStudents = _students.where((student) {
      final matchesSearch =
          _search.isEmpty ||
          student.fullName.toLowerCase().contains(_search) ||
          student.rollNumber.toLowerCase().contains(_search);
      final matchesFilter =
          _filter == 'All' || _statuses[student.id] == _filter.toLowerCase();
      return matchesSearch && matchesFilter;
    }).toList();
    if (visibleStudents.isEmpty) {
      return const _RosterMessage(
        icon: Icons.search_off_rounded,
        title: 'No matching students',
        message: 'Try changing the search or attendance filter.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRoster,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        itemCount: visibleStudents.length,
        separatorBuilder: (_, _) => const SizedBox(height: 9),
        itemBuilder: (context, index) {
          final student = visibleStudents[index];
          return _AttendanceStudentCard(
            student: student,
            status: _statuses[student.id],
            onStatusChanged: (status) => _setStatus(student.id, status),
          );
        },
      ),
    );
  }

  int _count(String status) =>
      _students.where((student) => _statuses[student.id] == status).length;
}

class _AttendanceStudentCard extends StatelessWidget {
  const _AttendanceStudentCard({
    required this.student,
    required this.status,
    required this.onStatusChanged,
  });

  final ClassStudent student;
  final String? status;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final nameParts = student.fullName.trim().split(RegExp(r'\s+'));
    final initials = nameParts.isEmpty || nameParts.first.isEmpty
        ? '?'
        : nameParts.length == 1
        ? nameParts.first.substring(0, 1).toUpperCase()
        : '${nameParts.first.substring(0, 1)}${nameParts.last.substring(0, 1)}'
              .toUpperCase();
    final statusColor = switch (status) {
      'present' => const Color(0xFF11966B),
      'absent' => const Color(0xFFC94141),
      'late' => const Color(0xFF986400),
      'leave' => const Color(0xFF3157A3),
      _ => const Color(0xFFE1E1EA),
    };
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFECECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x070D1450),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 23,
                            backgroundColor: status == 'present'
                                ? const Color(0xFFDDF8EB)
                                : const Color(0xFFE9ECFF),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: _rosterBlue,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (status == 'present')
                            Positioned(
                              right: -2,
                              bottom: -1,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF11966B),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F0F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Roll #${student.rollNumber}',
                                style: const TextStyle(
                                  color: _rosterMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              student.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _rosterInk,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              student.fatherName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _rosterMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _AttendanceBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F7),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        for (final item in const [
                          ('Present', 'present', Color(0xFF11966B)),
                          ('Absent', 'absent', Color(0xFFB13B3B)),
                          ('Late', 'late', Color(0xFF976600)),
                          ('Leave', 'leave', Color(0xFF5962A8)),
                        ])
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: _StatusButton(
                                label: item.$1,
                                value: item.$2,
                                color: item.$3,
                                selected: status == item.$2,
                                onTap: () => onStatusChanged(item.$2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? Colors.white : const Color(0xFF575968),
        backgroundColor: selected ? color : Colors.transparent,
        side: BorderSide(color: selected ? color : Colors.transparent),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _AttendanceBadge extends StatelessWidget {
  const _AttendanceBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'present' => ('Present', const Color(0xFF26734D)),
      'absent' => ('Absent', const Color(0xFFB13B3B)),
      'late' => ('Late', const Color(0xFF976600)),
      'leave' => ('Leave', const Color(0xFF5962A8)),
      _ => ('Pending', _rosterMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryCount extends StatelessWidget {
  const _SummaryCount({
    required this.label,
    required this.urduLabel,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final String urduLabel;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              color: color,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _rosterInk,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            urduLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _rosterMuted,
              fontSize: 9,
              height: 1.1,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RosterMessage extends StatelessWidget {
  const _RosterMessage({
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
          Icon(icon, size: 44, color: _rosterBlue),
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

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
