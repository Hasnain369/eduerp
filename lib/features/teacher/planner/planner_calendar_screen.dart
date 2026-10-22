import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/teacher_assignment_repository.dart';
import '../../../data/repositories/teacher_planner_repository.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../teacher_portal_routes.dart';
import '../teacher_section_screen.dart';

class PlannerCalendarScreen extends ConsumerStatefulWidget {
  const PlannerCalendarScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<PlannerCalendarScreen> createState() =>
      _PlannerCalendarScreenState();
}

class _PlannerCalendarScreenState extends ConsumerState<PlannerCalendarScreen> {
  bool _isLoading = true;
  bool _needsApproval = false;
  String? _errorMessage;
  UserModel? _teacher;
  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  List<PlannerPeriod> _periods = const [];
  List<PlannerLecture> _lectures = const [];
  Map<String, PlannerDay> _days = const {};
  List<TeacherAssignment> _assignments = const [];

  PlannerDay get _selectedDay =>
      _days[plannerDateKey(_selectedDate)] ??
      PlannerDay(
        dateKey: plannerDateKey(_selectedDate),
        periodStatuses: const {},
        tasks: const [],
      );

  List<PlannerPeriod> get _selectedPeriods => _periods
      .where((period) => period.dayOfWeek == _selectedDate.weekday)
      .toList();

  List<TeacherAssignment> get _selectedAssignments => _assignments
      .where(
        (assignment) => DateUtils.isSameDay(assignment.date, _selectedDate),
      )
      .toList();

  List<PlannerLecture> get _selectedLectures => _lectures
      .where((lecture) => lecture.dateKey == plannerDateKey(_selectedDate))
      .toList();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    final teacher = ref.read(authStateNotifierProvider).user;
    if (teacher == null || !teacher.canAccessTeacherFeatures) {
      setState(() {
        _teacher = teacher;
        _needsApproval = true;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _teacher = teacher;
      _needsApproval = false;
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final start = DateTime(_visibleMonth.year, _visibleMonth.month);
      final end = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
      final plannerRepository = ref.read(teacherPlannerRepositoryProvider);
      final assignmentRepository = ref.read(
        teacherAssignmentRepositoryProvider,
      );
      final result = await Future.wait([
        plannerRepository.getPeriods(teacher.id),
        plannerRepository.getDaysBetween(
          teacher.id,
          plannerDateKey(start),
          plannerDateKey(end),
        ),
        assignmentRepository.getAssignments(
          schoolId: teacher.schoolId,
          teacherId: teacher.id,
        ),
        plannerRepository.getLecturesBetween(
          teacher.id,
          plannerDateKey(start),
          plannerDateKey(end),
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _periods = result[0] as List<PlannerPeriod>;
        _days = {
          for (final day in result[1] as List<PlannerDay>) day.dateKey: day,
        };
        _assignments = result[2] as List<TeacherAssignment>;
        _lectures = result[3] as List<PlannerLecture>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _changeMonth(int offset) async {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + offset,
      );
      final lastDay = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + 1,
        0,
      ).day;
      _selectedDate = DateTime(
        _visibleMonth.year,
        _visibleMonth.month,
        _selectedDate.day.clamp(1, lastDay),
      );
    });
    await _loadCalendar();
  }

  Future<void> _addPlan() async {
    final teacher = _teacher;
    if (teacher == null) return;
    final task = await showDialog<String>(
      context: context,
      builder: (_) => const _AddPlanDialog(),
    );
    if (task == null || !mounted) return;
    try {
      await ref
          .read(teacherPlannerRepositoryProvider)
          .addTask(
            teacherId: teacher.id,
            dateKey: plannerDateKey(_selectedDate),
            task: task,
          );
      await _loadCalendar();
    } catch (error) {
      _showError(error);
    }
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  void _planSelectedDate() {
    ref.read(lecturePlannerSelectedDateProvider.notifier).state =
        _selectedDate;
    Navigator.of(context).pop();
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TeacherPortalScaffold(
      activeRoute: TeacherPortalRoutes.timetable,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return _CalendarMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load calendar',
        message: _errorMessage!,
        action: FilledButton.icon(
          onPressed: _loadCalendar,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    if (_needsApproval) {
      return const _CalendarMessage(
        icon: Icons.lock_outline_rounded,
        title: 'Planner is not available yet',
        message: 'Your teacher profile must be approved before using Planner.',
      );
    }

    final selectedDay = _selectedDay;
    final doneCount = selectedDay.periodStatuses.values
        .where((status) => status == PlannerPeriodStatus.done)
        .length;
    final skippedCount = selectedDay.periodStatuses.values
        .where((status) => status == PlannerPeriodStatus.skipped)
        .length;
    final offCount = selectedDay.periodStatuses.values
        .where((status) => status == PlannerPeriodStatus.off)
        .length;
    final assignments = _selectedAssignments;
    final lectures = _selectedLectures;

    return RefreshIndicator(
      onRefresh: _loadCalendar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
        children: [
          _buildMonthHeader(context),
          const SizedBox(height: 14),
          _buildHeatmap(context),
          const SizedBox(height: 10),
          _buildLegend(context),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(_selectedDate),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Add a plan for this day',
                onPressed: _addPlan,
                icon: const Icon(Icons.add_task_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActivityPill(
                icon: Icons.check_circle_outline_rounded,
                label: '$doneCount/${_selectedPeriods.length} periods done',
                color: const Color(0xFF26734D),
              ),
              _ActivityPill(
                icon: Icons.skip_next_rounded,
                label: '$skippedCount skipped',
                color: const Color(0xFFB45A36),
              ),
              _ActivityPill(
                icon: Icons.event_busy_outlined,
                label: '$offCount off',
                color: const Color(0xFF6C7480),
              ),
              _ActivityPill(
                icon: Icons.assignment_outlined,
                label: '${assignments.length} assignments',
                color: const Color(0xFF4169A1),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ActivitySection(
            title: 'Lectures',
            emptyText: 'No lectures planned for this day.',
            children: [
              for (final lecture in lectures)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    lecture.status == PlannerLectureStatus.done
                        ? Icons.check_circle_outline_rounded
                        : Icons.menu_book_outlined,
                  ),
                  title: Text('${lecture.subject} · ${lecture.classSection}'),
                  subtitle: Text(
                    '${lecture.topic} · ${_calendarTime(lecture.startMinutes)}–${_calendarTime(lecture.endMinutes)} · ${lecture.status.name}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _planSelectedDate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Plan lecture for this day'),
          ),
          const SizedBox(height: 14),
          _ActivitySection(
            title: 'Assignments',
            emptyText: 'No assignments for this day.',
            children: [
              for (final assignment in assignments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.assignment_outlined),
                  title: Text(assignment.topic),
                  subtitle: Text(assignment.subject),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _ActivitySection(
            title: 'Plans',
            emptyText: 'No plans for this day.',
            children: [
              for (final task in selectedDay.tasks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.checklist_rounded),
                  title: Text(task),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addPlan,
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Add plan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            _monthLabel(_visibleMonth),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          tooltip: 'Previous month',
          onPressed: _isLoading ? null : () => _changeMonth(-1),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        IconButton(
          tooltip: 'Next month',
          onPressed: _isLoading ? null : () => _changeMonth(1),
          icon: const Icon(Icons.chevron_right_rounded),
        ),
        IconButton(
          tooltip: 'Refresh calendar',
          onPressed: _isLoading ? null : _loadCalendar,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final leadingCells =
        DateTime(_visibleMonth.year, _visibleMonth.month).weekday - 1;
    final cellCount = ((leadingCells + daysInMonth + 6) ~/ 7) * 7;
    final weekdays = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        Row(
          children: [
            for (final weekday in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    weekday,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 5,
            mainAxisSpacing: 5,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final dayNumber = index - leadingCells + 1;
            if (dayNumber < 1 || dayNumber > daysInMonth) {
              return const SizedBox.shrink();
            }
            final date = DateTime(
              _visibleMonth.year,
              _visibleMonth.month,
              dayNumber,
            );
            final day = _days[plannerDateKey(date)];
            final assignmentsForDate = _assignments
                .where(
                  (assignment) => DateUtils.isSameDay(assignment.date, date),
                )
                .length;
            final lecturesForDate = _lectures
                .where((lecture) => lecture.dateKey == plannerDateKey(date))
                .length;
            final level = _activityLevel(
              day,
              assignmentsForDate + lecturesForDate,
            );
            final selected = DateUtils.isSameDay(date, _selectedDate);
            return Tooltip(
              message:
                  '${_formatDate(date)} · ${day?.periodStatuses.values.where((status) => status == PlannerPeriodStatus.done).length ?? 0} done · ${(day?.tasks.length ?? 0) + assignmentsForDate + lecturesForDate} plans/assignments',
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _selectDate(date),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _heatColor(context, level),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.transparent,
                      width: selected ? 2 : 0,
                    ),
                  ),
                  child: Text(
                    '$dayNumber',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 6),
        for (var level = 0; level <= 4; level++) ...[
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: _heatColor(context, level),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 3),
        ],
        const SizedBox(width: 3),
        Text('More', style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  int _activityLevel(PlannerDay? day, int assignmentCount) {
    final markedPeriods = day?.periodStatuses.length ?? 0;
    final plannedTasks = day?.tasks.length ?? 0;
    final activity = markedPeriods + plannedTasks + assignmentCount;
    if (activity == 0) return 0;
    if (activity == 1) return 1;
    if (activity <= 3) return 2;
    if (activity <= 5) return 3;
    return 4;
  }

  Color _heatColor(BuildContext context, int level) {
    const colors = [
      Color(0xFFE9ECEB),
      Color(0xFFC6E8D4),
      Color(0xFF8DCCAA),
      Color(0xFF4CA878),
      Color(0xFF176B61),
    ];
    return colors[level.clamp(0, 4)];
  }
}

class _AddPlanDialog extends StatefulWidget {
  const _AddPlanDialog();

  @override
  State<_AddPlanDialog> createState() => _AddPlanDialogState();
}

class _AddPlanDialogState extends State<_AddPlanDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add plan'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'What do you need to do?',
          ),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Enter a plan' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _controller.text.trim());
            }
          },
          child: const Text('Add plan'),
        ),
      ],
    );
  }
}

class _ActivityPill extends StatelessWidget {
  const _ActivityPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        if (children.isEmpty)
          Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
        else
          ...children,
      ],
    );
  }
}

class _CalendarMessage extends StatelessWidget {
  const _CalendarMessage({
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
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

String _monthLabel(DateTime month) =>
    '${_monthNames[month.month - 1]} ${month.year}';

String _formatDate(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.day}, ${date.year}';

String _calendarTime(int minutes) {
  final hour = minutes ~/ 60;
  final minute = (minutes % 60).toString().padLeft(2, '0');
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:$minute ${hour >= 12 ? 'PM' : 'AM'}';
}

const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
