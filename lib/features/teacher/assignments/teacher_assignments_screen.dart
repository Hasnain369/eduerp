import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/teacher_assignment_repository.dart';
import '../dashboard/teacher_dashboard_provider.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

enum _AssignmentFilter { all, today, previous }

class TeacherAssignmentsScreen extends ConsumerStatefulWidget {
  const TeacherAssignmentsScreen({super.key});

  @override
  ConsumerState<TeacherAssignmentsScreen> createState() =>
      _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState
    extends ConsumerState<TeacherAssignmentsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _needsApproval = false;
  String? _errorMessage;
  UserModel? _teacher;
  List<TeacherAssignment> _assignments = const [];
  _AssignmentFilter _filter = _AssignmentFilter.all;

  List<TeacherAssignment> get _filteredAssignments {
    final today = DateUtils.dateOnly(DateTime.now());
    return _assignments.where((assignment) {
      final date = DateUtils.dateOnly(assignment.date);
      return switch (_filter) {
        _AssignmentFilter.all => true,
        _AssignmentFilter.today => DateUtils.isSameDay(date, today),
        _AssignmentFilter.previous => date.isBefore(today),
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    final teacher = ref.read(authStateNotifierProvider).user;
    if (teacher == null || !teacher.canAccessTeacherFeatures) {
      setState(() {
        _teacher = teacher;
        _assignments = const [];
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
      final assignments = await ref
          .read(teacherAssignmentRepositoryProvider)
          .getAssignments(schoolId: teacher.schoolId, teacherId: teacher.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _assignments = assignments;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _addAssignment() async {
    final teacher = _teacher;
    if (teacher == null || _isSaving) {
      return;
    }
    final draft = await showDialog<_AssignmentDraft>(
      context: context,
      builder: (_) => _AddAssignmentDialog(subjects: teacher.subjects),
    );
    if (draft == null || !mounted) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(teacherAssignmentRepositoryProvider)
          .createAssignment(
            schoolId: teacher.schoolId,
            teacherId: teacher.id,
            date: draft.date,
            subject: draft.subject,
            topic: draft.topic,
          );
      ref.invalidate(teacherDashboardSummaryProvider(teacher.id));
      await _loadAssignments();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Assignment added.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showDetails(TeacherAssignment assignment) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.topic,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _AssignmentDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: _formatDate(assignment.date),
            ),
            const SizedBox(height: 16),
            _AssignmentDetailRow(
              icon: Icons.menu_book_outlined,
              label: 'Subject',
              value: assignment.subject,
            ),
            const SizedBox(height: 16),
            _AssignmentDetailRow(
              icon: Icons.topic_outlined,
              label: 'Topic',
              value: assignment.topic,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignments = _filteredAssignments;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assignments'),
        actions: [
          IconButton(
            tooltip: 'Refresh assignments',
            onPressed: _isLoading ? null : _loadAssignments,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody(assignments)),
      floatingActionButton: _needsApproval
          ? null
          : FloatingActionButton.extended(
              onPressed: _isSaving ? null : _addAssignment,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_rounded),
              label: Text(_isSaving ? 'Adding...' : 'Add assignment'),
            ),
    );
  }

  Widget _buildBody(List<TeacherAssignment> assignments) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _AssignmentMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load assignments',
        message: _errorMessage!,
        action: FilledButton.icon(
          onPressed: _loadAssignments,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    if (_needsApproval) {
      return const _AssignmentMessage(
        icon: Icons.lock_outline_rounded,
        title: 'Assignments are not available yet',
        message:
            'Your teacher profile must be approved and assigned to a school, classes, and subjects first.',
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<_AssignmentFilter>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _AssignmentFilter.all, label: Text('All')),
                ButtonSegment(
                  value: _AssignmentFilter.today,
                  label: Text('Today'),
                ),
                ButtonSegment(
                  value: _AssignmentFilter.previous,
                  label: Text('Previous'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
        ),
        Expanded(
          child: assignments.isEmpty
              ? _AssignmentMessage(
                  icon: Icons.assignment_outlined,
                  title: 'No assignments here',
                  message: _filter == _AssignmentFilter.today
                      ? 'Assignments scheduled for today will appear here.'
                      : _filter == _AssignmentFilter.previous
                      ? 'Earlier assignments will appear here.'
                      : 'Add an assignment to get started.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: assignments.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final assignment = assignments[index];
                    return _AssignmentBar(
                      assignment: assignment,
                      onTap: () => _showDetails(assignment),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AssignmentDraft {
  const _AssignmentDraft({
    required this.date,
    required this.subject,
    required this.topic,
  });

  final DateTime date;
  final String subject;
  final String topic;
}

class _AddAssignmentDialog extends StatefulWidget {
  const _AddAssignmentDialog({required this.subjects});

  final List<String> subjects;

  @override
  State<_AddAssignmentDialog> createState() => _AddAssignmentDialogState();
}

class _AddAssignmentDialogState extends State<_AddAssignmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _subjectController = TextEditingController();
  late DateTime _selectedDate;
  late TextEditingController _dateController;
  String? _selectedSubject;

  List<String> get _subjects => widget.subjects
      .map((subject) => subject.trim())
      .where((subject) => subject.isNotEmpty)
      .toSet()
      .toList();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _dateController = TextEditingController(text: _formatDate(_selectedDate));
    if (_subjects.isNotEmpty) {
      _selectedSubject = _subjects.first;
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _topicController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDate = DateUtils.dateOnly(date);
      _dateController.text = _formatDate(_selectedDate);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      _AssignmentDraft(
        date: _selectedDate,
        subject: _subjects.isEmpty
            ? _subjectController.text.trim()
            : _selectedSubject!,
        topic: _topicController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add assignment'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                if (_subjects.isEmpty)
                  TextFormField(
                    controller: _subjectController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a subject'
                        : null,
                  )
                else
                  DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: [
                      for (final subject in _subjects)
                        DropdownMenuItem(value: subject, child: Text(subject)),
                    ],
                    onChanged: (value) => setState(() {
                      _selectedSubject = value;
                    }),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Select a subject'
                        : null,
                  ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _topicController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Topic'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a topic'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Add')),
      ],
    );
  }
}

class _AssignmentBar extends StatelessWidget {
  const _AssignmentBar({required this.assignment, required this.onTap});

  final TeacherAssignment assignment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDEBFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_outlined),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.topic,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${assignment.subject} · ${_formatDate(assignment.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentDetailRow extends StatelessWidget {
  const _AssignmentDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        SizedBox(
          width: 68,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _AssignmentMessage extends StatelessWidget {
  const _AssignmentMessage({
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
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
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
