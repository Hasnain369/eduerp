import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/teacher_class_repository.dart';
import '../attendance/attendance_summary_provider.dart';
import '../dashboard/teacher_dashboard_provider.dart';
import '../../../providers/auth_provider.dart';
import '../teacher_portal_routes.dart';
import '../teacher_section_screen.dart';

class TeacherClassesScreen extends ConsumerStatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  ConsumerState<TeacherClassesScreen> createState() =>
      _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends ConsumerState<TeacherClassesScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<TeacherClass> _classes = const [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    final user = ref.read(authStateNotifierProvider).user;
    if (user == null || !user.isTeacher) {
      setState(() {
        _classes = const [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final classes = await ref
          .read(teacherClassRepositoryProvider)
          .getClasses(teacherId: user.id, assignedSections: user.classSections);
      if (!mounted) return;
      setState(() {
        _classes = classes;
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

  Future<void> _renameClass(TeacherClass teacherClass) async {
    final user = ref.read(authStateNotifierProvider).user;
    if (user == null) return;
    final gradeDetails = AttendanceClassDetails.fromAssignment(
      teacherClass.profileSection,
    );
    final currentSection = AttendanceClassDetails.fromAssignment(
      teacherClass.name,
    ).section;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _EditClassNameDialog(
        initialName: currentSection == 'Not specified' ? '' : currentSection,
      ),
    );
    if (name == null || name.isEmpty) return;

    try {
      await ref
          .read(teacherClassRepositoryProvider)
          .renameClass(
            teacherId: user.id,
            classId: teacherClass.id,
            name: '${gradeDetails.className} - $name',
          );
      await _loadClasses();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _openClass(TeacherClass teacherClass) async {
    final user = ref.read(authStateNotifierProvider).user;
    if (user == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            _ClassRosterScreen(teacherId: user.id, teacherClass: teacherClass),
      ),
    );
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
      activeRoute: TeacherPortalRoutes.classes,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'My classes',
                    style: TextStyle(
                      color: Color(0xFF20212B),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh classes',
                  onPressed: _isLoading ? null : _loadClasses,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
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
      return _ClassesMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load classes',
        message: _errorMessage!,
        action: FilledButton.icon(
          onPressed: _loadClasses,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    if (_classes.isEmpty) {
      return const _ClassesMessage(
        icon: Icons.class_outlined,
        title: 'No classes assigned',
        message: 'Classes added to your teacher profile will appear here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClasses,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: _classes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final teacherClass = _classes[index];
          final details = AttendanceClassDetails.fromAssignment(
            teacherClass.name,
          );
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openClass(teacherClass),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.class_rounded,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            details.className,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Section ${details.section}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit class name',
                      onPressed: () => _renameClass(teacherClass),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EditClassNameDialog extends StatefulWidget {
  const _EditClassNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_EditClassNameDialog> createState() => _EditClassNameDialogState();
}

class _EditClassNameDialogState extends State<_EditClassNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit section name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Section name'),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ClassRosterScreen extends ConsumerStatefulWidget {
  const _ClassRosterScreen({
    required this.teacherId,
    required this.teacherClass,
  });

  final String teacherId;
  final TeacherClass teacherClass;

  @override
  ConsumerState<_ClassRosterScreen> createState() => _ClassRosterScreenState();
}

class _ClassRosterScreenState extends ConsumerState<_ClassRosterScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ClassStudent> _students = const [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final students = await ref
          .read(teacherClassRepositoryProvider)
          .getStudents(
            teacherId: widget.teacherId,
            classId: widget.teacherClass.id,
          );
      if (!mounted) return;
      setState(() {
        _students = students;
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

  Future<void> _addStudent() async {
    final details = await showDialog<ClassStudent>(
      context: context,
      builder: (_) => const _AddStudentDialog(),
    );
    if (details == null) return;

    try {
      final repository = ref.read(teacherClassRepositoryProvider);
      if (repository is ManagedTeacherClassRepository) {
        final managedRepository = repository as ManagedTeacherClassRepository;
        await managedRepository.addDetailedStudent(
          teacherId: widget.teacherId,
          classId: widget.teacherClass.id,
          student: details,
        );
      } else {
        await repository.addStudent(
          teacherId: widget.teacherId,
          classId: widget.teacherClass.id,
          fullName: details.fullName,
          rollNumber: details.rollNumber,
          contactNumber: details.contactNumber,
        );
      }
      ref.invalidate(teacherAttendancePercentageProvider(widget.teacherId));
      ref.invalidate(teacherDashboardSummaryProvider(widget.teacherId));
      await _loadStudents();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _removeStudent(ClassStudent student) async {
    final repository = ref.read(teacherClassRepositoryProvider);
    if (repository is! ManagedTeacherClassRepository) return;
    final managedRepository = repository as ManagedTeacherClassRepository;
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove student?'),
        content: Text('${student.fullName} will be removed from this class.'),
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
    if (shouldRemove != true) return;
    try {
      await managedRepository.removeStudent(
        teacherId: widget.teacherId,
        classId: widget.teacherClass.id,
        studentId: student.id,
      );
      await _loadStudents();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student removed from class.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final details = AttendanceClassDetails.fromAssignment(
      widget.teacherClass.name,
    );
    return TeacherPortalScaffold(
      activeRoute: TeacherPortalRoutes.classes,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Back to classes',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Text(
                    '${details.className} · Section ${details.section}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildRoster()),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addStudent,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add student'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoster() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return _ClassesMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Could not load students',
        message: _errorMessage!,
        action: FilledButton.icon(
          onPressed: _loadStudents,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      );
    }
    if (_students.isEmpty) {
      return const _ClassesMessage(
        icon: Icons.people_outline_rounded,
        title: 'No students yet',
        message: 'Add students to build this class roster.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStudents,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        itemCount: _students.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final student = _students[index];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              minVerticalPadding: 14,
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFE9ECFF),
                child: Text(student.fullName[0].toUpperCase()),
              ),
              title: Text(
                student.fullName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Roll ${student.rollNumber} · ${student.contactNumber}'
                '${student.fatherName.isEmpty ? '' : '\nFather: ${student.fatherName}'}',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              isThreeLine: student.fatherName.isNotEmpty,
              trailing: PopupMenuButton<String>(
                tooltip: 'Student actions',
                onSelected: (value) {
                  if (value == 'remove') _removeStudent(student);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'remove', child: Text('Remove student')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AddStudentDialog extends StatefulWidget {
  const _AddStudentDialog();

  @override
  State<_AddStudentDialog> createState() => _AddStudentDialogState();
}

class _AddStudentDialogState extends State<_AddStudentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fatherController = TextEditingController();
  final _rollController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _addressController = TextEditingController();
  String _gender = '';

  @override
  void dispose() {
    _nameController.dispose();
    _fatherController.dispose();
    _rollController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _dateOfBirthController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _requiredField(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add student'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: _requiredField,
              ),
              TextFormField(
                controller: _fatherController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: "Father's name"),
                validator: _requiredField,
              ),
              TextFormField(
                controller: _rollController,
                decoration: const InputDecoration(labelText: 'Roll number'),
                validator: _requiredField,
              ),
              TextFormField(
                controller: _contactController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact number'),
                validator: _requiredField,
              ),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                ),
              ),
              DropdownButtonFormField<String>(
                value: _gender.isEmpty ? null : _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender (optional)',
                ),
                items: const [
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) => _gender = value ?? '',
              ),
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of birth (optional)',
                  hintText: 'DD/MM/YYYY',
                ),
              ),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address (optional)',
                ),
              ),
            ],
          ),
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
              Navigator.pop(
                context,
                ClassStudent(
                  id: '',
                  fullName: _nameController.text.trim(),
                  fatherName: _fatherController.text.trim(),
                  rollNumber: _rollController.text.trim(),
                  contactNumber: _contactController.text.trim(),
                  email: _emailController.text.trim(),
                  gender: _gender,
                  dateOfBirth: _dateOfBirthController.text.trim(),
                  address: _addressController.text.trim(),
                ),
              );
            }
          },
          child: const Text('Add student'),
        ),
      ],
    );
  }
}

class _ClassesMessage extends StatelessWidget {
  const _ClassesMessage({
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
