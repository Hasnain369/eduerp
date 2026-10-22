import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/teacher_planner_repository.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../dashboard/teacher_dashboard_provider.dart';
import '../teacher_portal_routes.dart';
import '../teacher_section_screen.dart';
import 'planner_calendar_screen.dart';

const _plannerBlue = Color(0xFF3448B0);
const _plannerInk = Color(0xFF20212B);
const _plannerMuted = Color(0xFF747688);

class LecturePlannerScreen extends ConsumerStatefulWidget {
  const LecturePlannerScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  ConsumerState<LecturePlannerScreen> createState() =>
      _LecturePlannerScreenState();
}

class _LecturePlannerScreenState extends ConsumerState<LecturePlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chapterController = TextEditingController();
  final _topicController = TextEditingController();
  final List<TextEditingController> _objectiveControllers = [];
  UserModel? _teacher;
  List<PlannerLecture> _lectures = const [];
  List<PlannerLecture> _weekLectures = const [];
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());
  String? _selectedClass;
  String? _selectedSubject;
  PlannerLecture? _editing;
  PlannerLectureStatus _status = PlannerLectureStatus.planned;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 9, minute: 45);
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDate ?? DateTime.now());
    _teacher = ref.read(authStateNotifierProvider).user;
    _selectedClass = _teacher?.classSections.firstOrNull;
    _selectedSubject = _teacher?.subjects.firstOrNull;
    _objectiveControllers.add(TextEditingController());
    _loadLectures();
  }

  @override
  void dispose() {
    _chapterController.dispose();
    _topicController.dispose();
    for (final controller in _objectiveControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLectures() async {
    final teacher = _teacher;
    if (teacher == null || !teacher.canAccessTeacherFeatures) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Your teacher profile must be approved before planning.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final monday = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - DateTime.monday),
      );
      final lectures = await ref
          .read(teacherPlannerRepositoryProvider)
          .getLecturesBetween(
            teacher.id,
            plannerDateKey(monday),
            plannerDateKey(monday.add(const Duration(days: 6))),
          );
      if (!mounted) return;
      setState(() {
        _weekLectures = lectures;
        _lectures = lectures
            .where(
              (lecture) => lecture.dateKey == plannerDateKey(_selectedDate),
            )
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _changeDate(DateTime date) async {
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _resetForm();
    });
    await _loadLectures();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) await _changeDate(date);
  }

  Future<void> _openCalendar() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlannerCalendarScreen(initialDate: _selectedDate),
      ),
    );
    if (!mounted) return;
    final selected = ref.read(lecturePlannerSelectedDateProvider);
    if (selected != null) {
      ref.read(lecturePlannerSelectedDateProvider.notifier).state = null;
      await _changeDate(selected);
    } else {
      await _loadLectures();
    }
  }

  Future<void> _shiftWeek(int amount) async {
    await _changeDate(_selectedDate.add(Duration(days: amount * 7)));
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _addObjective() {
    setState(() => _objectiveControllers.add(TextEditingController()));
  }

  void _removeObjective(int index) {
    final removed = _objectiveControllers.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  void _editLecture(PlannerLecture lecture) {
    setState(() {
      _editing = lecture;
      _selectedClass = lecture.classSection;
      _selectedSubject = lecture.subject;
      _chapterController.text = lecture.chapter;
      _topicController.text = lecture.topic;
      _status = lecture.status;
      _start = _timeOfDay(lecture.startMinutes);
      _end = _timeOfDay(lecture.endMinutes);
      for (final controller in _objectiveControllers) {
        controller.dispose();
      }
      _objectiveControllers
        ..clear()
        ..addAll(
          lecture.objectives.map(
            (objective) => TextEditingController(text: objective),
          ),
        );
      if (_objectiveControllers.isEmpty) {
        _objectiveControllers.add(TextEditingController());
      }
    });
  }

  void _resetForm() {
    _editing = null;
    _selectedClass = _teacher?.classSections.firstOrNull;
    _selectedSubject = _teacher?.subjects.firstOrNull;
    _chapterController.clear();
    _topicController.clear();
    _status = PlannerLectureStatus.planned;
    _start = const TimeOfDay(hour: 9, minute: 0);
    _end = const TimeOfDay(hour: 9, minute: 45);
    for (final controller in _objectiveControllers) {
      controller.dispose();
    }
    _objectiveControllers
      ..clear()
      ..add(TextEditingController());
  }

  Future<void> _saveLecture({required bool addNext}) async {
    if (!_formKey.currentState!.validate()) return;
    final teacher = _teacher;
    final classSection = _selectedClass;
    final subject = _selectedSubject;
    if (teacher == null || classSection == null || subject == null) {
      _showError('Add a class and subject to your teacher profile first.');
      return;
    }
    final startMinutes = _start.hour * 60 + _start.minute;
    final endMinutes = _end.hour * 60 + _end.minute;
    if (startMinutes >= endMinutes) {
      _showError('End time must be after start time.');
      return;
    }
    final lecture = PlannerLecture(
      id: _editing?.id ?? '',
      dateKey: plannerDateKey(_selectedDate),
      classSection: classSection,
      startMinutes: startMinutes,
      endMinutes: endMinutes,
      subject: subject,
      chapter: _chapterController.text,
      topic: _topicController.text,
      objectives: _objectiveControllers
          .map((controller) => controller.text.trim())
          .where((objective) => objective.isNotEmpty)
          .toList(),
      status: _status,
    );
    setState(() => _saving = true);
    try {
      final id = await ref
          .read(teacherPlannerRepositoryProvider)
          .saveLecture(teacher.id, lecture);
      if (!mounted) return;
      ref.invalidate(teacherDashboardSummaryProvider(teacher.id));
      if (addNext) {
        setState(_resetForm);
      } else {
        setState(() {
          _editing = PlannerLecture(
            id: id,
            dateKey: lecture.dateKey,
            classSection: lecture.classSection,
            startMinutes: lecture.startMinutes,
            endMinutes: lecture.endMinutes,
            subject: lecture.subject,
            chapter: lecture.chapter,
            topic: lecture.topic,
            objectives: lecture.objectives,
            status: lecture.status,
          );
        });
      }
      await _loadLectures();
      if (mounted) {
        _showMessage(
          addNext ? 'Saved. Add the next lecture.' : 'Lecture saved.',
        );
      }
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteLecture(PlannerLecture lecture) async {
    final teacher = _teacher;
    if (teacher == null) return;
    try {
      await ref
          .read(teacherPlannerRepositoryProvider)
          .deleteLecture(teacher.id, lecture.id);
      if (!mounted) return;
      ref.invalidate(teacherDashboardSummaryProvider(teacher.id));
      if (_editing?.id == lecture.id) setState(_resetForm);
      await _loadLectures();
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _setStatus(
    PlannerLecture lecture,
    PlannerLectureStatus status,
  ) async {
    final teacher = _teacher;
    if (teacher == null) return;
    final original = _lectures;
    setState(() {
      _lectures = _lectures
          .map(
            (item) => item.id == lecture.id
                ? PlannerLecture(
                    id: item.id,
                    dateKey: item.dateKey,
                    classSection: item.classSection,
                    startMinutes: item.startMinutes,
                    endMinutes: item.endMinutes,
                    subject: item.subject,
                    chapter: item.chapter,
                    topic: item.topic,
                    objectives: item.objectives,
                    status: status,
                  )
                : item,
          )
          .toList();
    });
    try {
      await ref
          .read(teacherPlannerRepositoryProvider)
          .setLectureStatus(
            teacherId: teacher.id,
            lectureId: lecture.id,
            status: status,
          );
      if (!mounted) return;
      ref.invalidate(teacherDashboardSummaryProvider(teacher.id));
    } catch (error) {
      if (!mounted) return;
      setState(() => _lectures = original);
      _showError(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _showError(String message) => _showMessage(message);

  @override
  Widget build(BuildContext context) {
    return TeacherPortalScaffold(
      activeRoute: TeacherPortalRoutes.timetable,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth > 620 ? 22.0 : 14.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 22),
            children: [
              _buildHeading(context),
              const SizedBox(height: 10),
              _buildWeekPicker(context),
              const SizedBox(height: 12),
              if (_error != null)
                _MessageCard(text: _error!, onRetry: _loadLectures)
              else ...[
                _buildLessonSummary(context),
                const SizedBox(height: 12),
                _buildCurriculumCard(context),
                const SizedBox(height: 12),
                _buildObjectivesCard(context),
                const SizedBox(height: 12),
                _buildFormActions(),
                const SizedBox(height: 22),
                _buildLectureList(context),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeading(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lecture Planner',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _plannerInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _formatFullDate(_selectedDate),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: _plannerMuted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Open calendar',
          onPressed: _openCalendar,
          icon: const Icon(Icons.calendar_month_outlined),
        ),
        IconButton(
          tooltip: 'Choose date',
          onPressed: _pickDate,
          icon: const Icon(Icons.event_outlined),
        ),
      ],
    );
  }

  Widget _buildWeekPicker(BuildContext context) {
    final monday = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - DateTime.monday),
    );
    final weekNumber = ((_selectedDate.day - 1) / 7).floor() + 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Week $weekNumber • ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Previous week',
                onPressed: () => _shiftWeek(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Next week',
                onPressed: () => _shiftWeek(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          Row(
            children: [
              for (var index = 0; index < 7; index++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _DateChip(
                      date: monday.add(Duration(days: index)),
                      selected: DateUtils.isSameDay(
                        monday.add(Duration(days: index)),
                        _selectedDate,
                      ),
                      hasLectures: _weekLectures.any(
                        (lecture) =>
                            lecture.dateKey ==
                            plannerDateKey(monday.add(Duration(days: index))),
                      ),
                      onTap: () =>
                          _changeDate(monday.add(Duration(days: index))),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLessonSummary(BuildContext context) {
    final teacher = _teacher;
    final noClass = teacher?.classSections.isEmpty ?? true;
    final noSubject = teacher?.subjects.isEmpty ?? true;
    return _PlannerCard(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, color: _plannerBlue, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: noClass
                    ? TextFormField(
                        initialValue: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Class / section',
                        ),
                        onChanged: (value) => _selectedClass = value,
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedClass,
                        decoration: const InputDecoration(
                          labelText: 'Class / section',
                        ),
                        items: teacher!.classSections
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _selectedClass = value),
                      ),
              ),
            ],
          ),
          const Divider(height: 22),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: _plannerMuted),
              const SizedBox(width: 8),
              Expanded(
                child: _TimeButton(
                  label: 'Start',
                  time: _start,
                  onTap: () => _pickTime(isStart: true),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('to'),
              ),
              Expanded(
                child: _TimeButton(
                  label: 'End',
                  time: _end,
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Lesson Status',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(height: 7),
          SegmentedButton<PlannerLectureStatus>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: PlannerLectureStatus.planned,
                label: Text('Planned'),
              ),
              ButtonSegment(
                value: PlannerLectureStatus.inProgress,
                label: Text('In Progress'),
              ),
              ButtonSegment(
                value: PlannerLectureStatus.done,
                label: Text('Done'),
              ),
            ],
            selected: {_status},
            onSelectionChanged: (value) =>
                setState(() => _status = value.first),
          ),
          if (noClass || noSubject)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Add your classes and subjects in Profile Setup to use the selectors.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: _plannerMuted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurriculumCard(BuildContext context) {
    final teacher = _teacher;
    return _PlannerCard(
      title: 'Curriculum & Topic',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SUBJECT', style: _fieldLabelStyle(context)),
            const SizedBox(height: 5),
            if (teacher?.subjects.isNotEmpty == true)
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                ),
                items: teacher!.subjects
                    .map(
                      (subject) => DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedSubject = value),
              )
            else
              TextFormField(
                initialValue: _selectedSubject,
                decoration: const InputDecoration(
                  hintText: 'e.g. Mathematics',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _selectedSubject = value,
              ),
            const SizedBox(height: 12),
            Text('CHAPTER / UNIT', style: _fieldLabelStyle(context)),
            const SizedBox(height: 5),
            TextFormField(
              controller: _chapterController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Chapter or unit',
                border: OutlineInputBorder(),
              ),
              validator: _requiredValidator,
            ),
            const SizedBox(height: 12),
            Text('LESSON TOPIC', style: _fieldLabelStyle(context)),
            const SizedBox(height: 5),
            TextFormField(
              controller: _topicController,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Enter lesson topic',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              validator: _requiredValidator,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_topicController.text.length}/100',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectivesCard(BuildContext context) {
    return _PlannerCard(
      title: 'Student Learning Objectives',
      trailing: const _SmallBadge('SLOs'),
      child: Column(
        children: [
          for (var index = 0; index < _objectiveControllers.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE3E3EC)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(top: 7),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _plannerBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _objectiveControllers[index],
                        minLines: 1,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Describe a learning objective',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove objective',
                      visualDensity: VisualDensity.compact,
                      onPressed: _objectiveControllers.length == 1
                          ? null
                          : () => _removeObjective(index),
                      icon: const Icon(Icons.delete_outline_rounded, size: 19),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addObjective,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              label: const Text('Add Objective'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFACB4E4)),
                foregroundColor: _plannerBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => _saveLecture(addNext: true),
            child: const Text('Add Next'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _saving ? null : () => _saveLecture(addNext: false),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_editing == null ? 'Save' : 'Update'),
          ),
        ),
      ],
    );
  }

  Widget _buildLectureList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Lectures on ${_shortDate(_selectedDate)}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Refresh lectures',
              onPressed: _loading ? null : _loadLectures,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        if (_loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_lectures.isEmpty)
          const _MessageCard(text: 'No lectures planned for this date yet.')
        else
          for (final lecture in _lectures)
            _LectureTile(
              lecture: lecture,
              onEdit: () => _editLecture(lecture),
              onDelete: () => _deleteLecture(lecture),
              onStatusChanged: (status) => _setStatus(lecture, status),
            ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.hasLectures,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool hasLectures;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _plannerBlue : const Color(0xFFF4F4F8);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: const Color(0xFF202F92)) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _weekdayShort(date.weekday),
              style: TextStyle(
                color: selected ? Colors.white : _plannerMuted,
                fontSize: 10,
              ),
            ),
            Text(
              '${date.day}',
              style: TextStyle(
                color: selected ? Colors.white : _plannerInk,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasLectures)
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFFFD164) : _plannerBlue,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

class _PlannerCard extends StatelessWidget {
  const _PlannerCard({this.title, this.trailing, required this.child});

  final String? title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _plannerBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title!,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _plannerInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            time.format(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  const _SmallBadge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _plannerBlue,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LectureTile extends StatelessWidget {
  const _LectureTile({
    required this.lecture,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  final PlannerLecture lecture;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<PlannerLectureStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('lecture-${lecture.id}'),
      margin: const EdgeInsets.only(bottom: 9),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 11, 7, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: lecture.status == PlannerLectureStatus.done
                        ? const Color(0xFF2C8A59)
                        : _plannerBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lecture.subject} • ${lecture.classSection}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_formatMinutes(lecture.startMinutes)}–${_formatMinutes(lecture.endMinutes)}  ·  ${lecture.chapter}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') onEdit();
                    if (action == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit lecture')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete lecture'),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 8),
              child: Text(lecture.topic),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<PlannerLectureStatus>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: PlannerLectureStatus.planned,
                    label: Text('Planned'),
                  ),
                  ButtonSegment(
                    value: PlannerLectureStatus.inProgress,
                    label: Text('In Progress'),
                  ),
                  ButtonSegment(
                    value: PlannerLectureStatus.done,
                    label: Text('Done'),
                  ),
                ],
                selected: {lecture.status},
                onSelectionChanged: (value) => onStatusChanged(value.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(text, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

String? _requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;

TextStyle? _fieldLabelStyle(BuildContext context) => Theme.of(context)
    .textTheme
    .labelSmall
    ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5);

TimeOfDay _timeOfDay(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

String _formatMinutes(int minutes) {
  final hour = minutes ~/ 60;
  final minute = (minutes % 60).toString().padLeft(2, '0');
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:$minute ${hour >= 12 ? 'PM' : 'AM'}';
}

String _formatFullDate(DateTime date) =>
    '${_weekdayLong(date.weekday)}, ${_monthName(date.month)} ${date.day}';

String _shortDate(DateTime date) => '${date.month}/${date.day}/${date.year}';

String _weekdayShort(int weekday) =>
    const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][weekday - 1];

String _weekdayLong(int weekday) => const [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
][weekday - 1];

String _monthName(int month) => const [
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
][month - 1];

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: const Color(0xFFE9E9F0)),
  boxShadow: const [
    BoxShadow(color: Color(0x080D1450), blurRadius: 10, offset: Offset(0, 3)),
  ],
);
