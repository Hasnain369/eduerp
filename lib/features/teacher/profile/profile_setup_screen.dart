import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/widgets/dashboard_components.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../teacher_portal_routes.dart';
import '../teacher_section_screen.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _schoolIdController = TextEditingController();
  final _designationController = TextEditingController();
  final _teacherIdController = TextEditingController();
  final _subjectsController = TextEditingController();
  final _classesController = TextEditingController();
  final _photoUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateNotifierProvider).user;
    if (user != null) {
      _nameController.text = user.name;
      _schoolIdController.text = user.schoolId;
      _designationController.text = user.designation;
      _teacherIdController.text = user.teacherId;
      _subjectsController.text = user.subjects.join(', ');
      _classesController.text = user.classSections.join(', ');
      _photoUrlController.text = user.photoUrl ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolIdController.dispose();
    _designationController.dispose();
    _teacherIdController.dispose();
    _subjectsController.dispose();
    _classesController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = await ref
        .read(authStateNotifierProvider.notifier)
        .saveTeacherProfile(
          fullName: _nameController.text,
          schoolId: _schoolIdController.text,
          designation: _designationController.text,
          teacherId: _teacherIdController.text,
          subjects: _subjectsController.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
          classSections: _classesController.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(),
          photoUrl: _photoUrlController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(authStateNotifierProvider).errorMessage ??
                'Profile could not be saved.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Teacher profile saved. Your approval status remains pending.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.teacherDashboard, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);

    return TeacherPortalScaffold(
      activeRoute: TeacherPortalRoutes.profile,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Teacher profile',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Complete your details for administrator review. Saving your profile does not approve your account.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Personal information'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Full name is required'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: 'School information'),
            TextFormField(
              controller: _schoolIdController,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'School or institution is required'
                  : null,
              decoration: const InputDecoration(
                labelText: 'School / institution',
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: 'Teaching information'),
            TextFormField(
              controller: _designationController,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Designation is required'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Designation',
                prefixIcon: Icon(Icons.work_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _teacherIdController,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Teacher ID is required'
                  : null,
              decoration: const InputDecoration(
                labelText: 'Teacher ID',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _subjectsController,
              decoration: const InputDecoration(
                labelText: 'Subjects (comma separated)',
                prefixIcon: Icon(Icons.menu_book_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _classesController,
              decoration: const InputDecoration(
                labelText: 'Requested classes / sections (comma separated)',
                prefixIcon: Icon(Icons.class_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _photoUrlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Profile photo URL (optional)',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            if (authState.user?.teacherAccessState ==
                TeacherAccessState.pendingApproval) ...[
              const SizedBox(height: 16),
              const _ProfileStatusNotice(
                message:
                    'Your account is pending review. This status remains until a school administrator approves your teacher access.',
              ),
            ],
            if (authState.user?.teacherAccessState ==
                TeacherAccessState.approvedNoClasses) ...[
              const SizedBox(height: 16),
              const _ProfileStatusNotice(
                message:
                    'Your account is approved, but an administrator has not assigned classes yet.',
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: authState.isLoading ? null : _submit,
              icon: authState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                authState.isLoading ? 'Saving profile…' : 'Save profile',
              ),
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                authState.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStatusNotice extends StatelessWidget {
  const _ProfileStatusNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
