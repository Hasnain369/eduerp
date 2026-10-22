import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../models/student_assignment_model.dart';
import '../providers/student_providers.dart';

class StudentTasksScreen extends ConsumerWidget {
  const StudentTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(studentAssignmentsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: assignmentsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorBody(message: e.toString()),
          data: (assignments) {
            if (assignments.isEmpty) {
              return _EmptyTasks();
            }
            final pending = assignments
                .where((a) => a.status == AssignmentStatus.pending)
                .toList()
              ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
            final submitted = assignments
                .where((a) =>
                    a.status == AssignmentStatus.submitted ||
                    a.status == AssignmentStatus.graded)
                .toList();
            final overdue = assignments
                .where((a) => a.isOverdue)
                .toList();

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                if (overdue.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionLabel(
                      label: 'Overdue',
                      count: overdue.length,
                      color: AppTheme.error,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _AssignmentTile(
                        assignment: overdue[i],
                        isOverdue: true,
                      ),
                      childCount: overdue.length,
                    ),
                  ),
                ],
                if (pending.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionLabel(
                      label: 'Pending',
                      count: pending.length,
                      color: AppTheme.warning,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _AssignmentTile(assignment: pending[i]),
                      childCount: pending.length,
                    ),
                  ),
                ],
                if (submitted.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: _SectionLabel(
                      label: 'Submitted / Graded',
                      count: submitted.length,
                      color: AppTheme.success,
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _AssignmentTile(assignment: submitted[i]),
                      childCount: submitted.length,
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentTile extends StatelessWidget {
  const _AssignmentTile({required this.assignment, this.isOverdue = false});

  final StudentAssignment assignment;
  final bool isOverdue;

  Color get _subjectColor {
    final colors = [
      AppTheme.accentBlue,
      AppTheme.accentMint,
      AppTheme.accentYellow,
      AppTheme.accentPink,
    ];
    return colors[assignment.subject.hashCode.abs() % colors.length];
  }

  IconData get _typeIcon {
    final t = assignment.type.toLowerCase();
    if (t.contains('quiz')) return Icons.quiz_outlined;
    if (t.contains('homework')) return Icons.home_work_outlined;
    if (t.contains('project')) return Icons.folder_outlined;
    return Icons.assignment_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final dueLabel = isOverdue ? 'Overdue' : assignment.dueDateLabel;
    final dueLabelColor = isOverdue ? AppTheme.error : _urgencyColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOverdue
              ? AppTheme.error.withValues(alpha: 0.3)
              : AppTheme.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _subjectColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_typeIcon, size: 20, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          assignment.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: dueLabelColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: dueLabelColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          dueLabel,
                          style: TextStyle(
                            color: dueLabelColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${assignment.type} • ${assignment.teacherName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: AppTheme.mutedText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, hh:mm a')
                            .format(assignment.dueDate),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedText,
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      _StatusChip(status: assignment.status),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color get _urgencyColor {
    final hours = assignment.timeUntilDue.inHours;
    if (hours < 3) return AppTheme.error;
    if (hours < 24) return AppTheme.warning;
    return AppTheme.success;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final AssignmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AssignmentStatus.submitted => ('Submitted', AppTheme.success),
      AssignmentStatus.graded => ('Graded', AppTheme.teal),
      AssignmentStatus.late => ('Late', AppTheme.error),
      AssignmentStatus.pending => ('Pending', AppTheme.mutedText),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No assignments yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Your teacher-assigned tasks will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppTheme.error),
            const SizedBox(height: 12),
            Text(
              'Failed to load assignments',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
