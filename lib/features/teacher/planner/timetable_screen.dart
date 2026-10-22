import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/teacher_planner_repository.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

class TimetableScreen extends ConsumerStatefulWidget {
  const TimetableScreen({super.key});

  @override
  ConsumerState<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends ConsumerState<TimetableScreen> {
  bool _isLoading = true;
  bool _needsApproval = false;
  String? _errorMessage;
  UserModel? _teacher;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  List<PlannerPeriod> _periods = const [];
  Map<String, PlannerPeriodStatus> _statuses = const {};

  List<PlannerPeriod> get _selectedDayPeriods => _periods
      .where((period) => period.dayOfWeek == _selectedDate.weekday)
      .toList();

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    final teacher = ref.read(authStateNotifierProvider).user;
    if (teacher == null || !teacher.canAccessTeacherFeatures) {
      setState(() {
        _teacher = teacher;
        _periods = const [];
        _statuses = const {};
        _needsApproval = true;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _teacher = teacher;
      _isLoading = true;
      _needsApproval = false;
      _errorMessage = null;
    });
    try {
      final repository = ref.read(teacherPlannerRepositoryProvider);
      final dateKey = plannerDateKey(_selectedDate);
      final results = await Future.wait([
        repository.getPeriods(teacher.id),
        repository.getDay(teacher.id, dateKey),
      ]);
      if (!mounted) return;
      setState(() {
        _periods = results[0] as List<PlannerPeriod>;
        _statuses = (results[1] as PlannerDay).periodStatuses;
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

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    setState(() => _selectedDate = DateUtils.dateOnly(date));
    await _loadTimetable();
  }

  Future<void> _editPeriod([PlannerPeriod? period]) async {
    final teacher = _teacher;
    if (teacher == null) return;
    final draft = await showDialog<PlannerPeriod>(
      context: context,
      builder: (_) => _PlannerPeriodDialog(
        subjects: teacher.subjects,
        classSections: teacher.classSections,
        initialDay: _selectedDate.weekday,
        period: period,
      ),
    );
    if (draft == null) return;

    try {
      await ref
          .read(teacherPlannerRepositoryProvider)
          .savePeriod(teacher.id, draft);
      await _loadTimetable();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _deletePeriod(PlannerPeriod period) async {
    final teacher = _teacher;
    if (teacher == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove period?'),
        content: const Text(
          'This removes the period from your weekly timetable.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(teacherPlannerRepositoryProvider)
          .deletePeriod(teacher.id, period.id);
      await _loadTimetable();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _setStatus(
    PlannerPeriod period,
    PlannerPeriodStatus status,
  ) async {
    final teacher = _teacher;
    if (teacher == null) return;
    setState(() => _statuses = {..._statuses, period.id: status});
    try {
      await ref
          .read(teacherPlannerRepositoryProvider)
          .setPeriodStatus(
            teacherId: teacher.id,
            dateKey: plannerDateKey(_selectedDate),
            periodId: period.id,
            status: status,
          );
    } catch (error) {
      if (!mounted) return;
      await _loadTimetable();
      _showError(error);
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timetable'),
        actions: [
          IconButton(
            tooltip: 'Refresh timetable',
            onPressed: _isLoading ? null : _loadTimetable,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: _teacher == null || _needsApproval
          ? null
          : FloatingActionButton.extended(
              onPressed: _editPeriod,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add period'),
            ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return _PlannerMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load timetable',
        message: _errorMessage!,
        action: FilledButton.icon(
          onPressed: _loadTimetable,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    if (_needsApproval) {
      return const _PlannerMessage(
        icon: Icons.lock_outline_rounded,
        title: 'Timetable is not available yet',
        message:
            'Your teacher profile must be approved and assigned to classes and subjects first.',
      );
    }
    final periods = _selectedDayPeriods;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _formatFullDate(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: const Text('Choose date'),
              ),
            ],
          ),
        ),
        Expanded(
          child: periods.isEmpty
              ? _PlannerMessage(
                  icon: Icons.view_week_outlined,
                  title: 'No periods for ${_dayName(_selectedDate.weekday)}',
                  message: _teacher!.subjects.isEmpty
                      ? 'Add subjects to your profile before creating periods.'
                      : 'Add a period to your weekly timetable.',
                  action: _teacher!.subjects.isEmpty
                      ? null
                      : FilledButton.icon(
                          onPressed: _editPeriod,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add period'),
                        ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: periods.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final period = periods[index];
                    return _PeriodTile(
                      period: period,
                      status: _statuses[period.id] ?? PlannerPeriodStatus.off,
                      onStatusChanged: (status) => _setStatus(period, status),
                      onEdit: () => _editPeriod(period),
                      onDelete: () => _deletePeriod(period),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _PeriodTile extends StatelessWidget {
  const _PeriodTile({
    required this.period,
    required this.status,
    required this.onStatusChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final PlannerPeriod period;
  final PlannerPeriodStatus status;
  final ValueChanged<PlannerPeriodStatus> onStatusChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        period.subject,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${period.classSection} · ${_timeRange(context, period)}',
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Period options',
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit period')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Remove period'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SegmentedButton<PlannerPeriodStatus>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: PlannerPeriodStatus.done,
                  label: Text('Done'),
                ),
                ButtonSegment(
                  value: PlannerPeriodStatus.skipped,
                  label: Text('Skipped'),
                ),
                ButtonSegment(
                  value: PlannerPeriodStatus.off,
                  label: Text('Off'),
                ),
              ],
              selected: {status},
              onSelectionChanged: (selection) =>
                  onStatusChanged(selection.first),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlannerPeriodDialog extends StatefulWidget {
  const _PlannerPeriodDialog({
    required this.subjects,
    required this.classSections,
    required this.initialDay,
    this.period,
  });

  final List<String> subjects;
  final List<String> classSections;
  final int initialDay;
  final PlannerPeriod? period;

  @override
  State<_PlannerPeriodDialog> createState() => _PlannerPeriodDialogState();
}

class _PlannerPeriodDialogState extends State<_PlannerPeriodDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<String> _subjects;
  late final List<String> _classes;
  late String? _subject;
  late String? _classSection;
  late int _day;
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    _subjects = widget.subjects
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    _classes = widget.classSections
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    _subject = widget.period?.subject ?? _subjects.firstOrNull;
    _classSection = widget.period?.classSection ?? _classes.firstOrNull;
    _day = widget.period?.dayOfWeek ?? widget.initialDay;
    _start = _timeOfDay(widget.period?.startMinutes ?? 480);
    _end = _timeOfDay(widget.period?.endMinutes ?? 525);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (time == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = time;
      } else {
        _end = time;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate() ||
        _subject == null ||
        _classSection == null) {
      return;
    }
    final startMinutes = _start.hour * 60 + _start.minute;
    final endMinutes = _end.hour * 60 + _end.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
    Navigator.pop(
      context,
      PlannerPeriod(
        id: widget.period?.id ?? '',
        dayOfWeek: _day,
        subject: _subject!,
        classSection: _classSection!,
        startMinutes: startMinutes,
        endMinutes: endMinutes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.period == null ? 'Add period' : 'Edit period'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: _day,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: [
                    for (var day = 1; day <= 7; day++)
                      DropdownMenuItem(value: day, child: Text(_dayName(day))),
                  ],
                  onChanged: (value) => setState(() => _day = value ?? _day),
                ),
                const SizedBox(height: 12),
                if (_subjects.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Add subjects to your profile first.'),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _subject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: [
                      for (final subject in _subjects)
                        DropdownMenuItem(value: subject, child: Text(subject)),
                    ],
                    onChanged: (value) => setState(() => _subject = value),
                    validator: (value) =>
                        value == null ? 'Select a subject' : null,
                  ),
                const SizedBox(height: 12),
                if (_classes.isEmpty)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Add classes to your profile first.'),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _classSection,
                    decoration: const InputDecoration(labelText: 'Class'),
                    items: [
                      for (final classSection in _classes)
                        DropdownMenuItem(
                          value: classSection,
                          child: Text(classSection),
                        ),
                    ],
                    onChanged: (value) => setState(() => _classSection = value),
                    validator: (value) =>
                        value == null ? 'Select a class' : null,
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickTime(isStart: true),
                        icon: const Icon(Icons.schedule_rounded),
                        label: Text('Start ${_formatTime(context, _start)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: false),
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text('End ${_formatTime(context, _end)}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _subjects.isEmpty || _classes.isEmpty ? null : _submit,
          child: Text(widget.period == null ? 'Add period' : 'Save'),
        ),
      ],
    );
  }
}

class _PlannerMessage extends StatelessWidget {
  const _PlannerMessage({
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

String _dayName(int day) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][day - 1];

String _formatFullDate(DateTime date) =>
    '${_dayName(date.weekday)}, ${date.day}/${date.month}/${date.year}';

TimeOfDay _timeOfDay(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

String _formatTime(BuildContext context, TimeOfDay time) =>
    MaterialLocalizations.of(context).formatTimeOfDay(time);

String _timeRange(BuildContext context, PlannerPeriod period) =>
    '${_formatTime(context, _timeOfDay(period.startMinutes))} – ${_formatTime(context, _timeOfDay(period.endMinutes))}';
