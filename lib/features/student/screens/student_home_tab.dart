import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../models/student_assignment_model.dart';
import '../models/student_progress_model.dart';
import '../models/student_result_model.dart';
import '../providers/student_providers.dart';

class StudentHomeTab extends ConsumerWidget {
  const StudentHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentStudentProvider);
    final dueSoon = ref.watch(dueSoonAssignmentsProvider);
    final recentResults = ref.watch(recentResultsProvider);
    final progressAsync = ref.watch(studentProgressProvider);
    final allAssignmentsAsync = ref.watch(studentAssignmentsProvider);

    if (user == null) return const SizedBox.shrink();

    final classInfo =
        user.classSections.isNotEmpty ? user.classSections.first : '';
    final rollNo = user.id.isNotEmpty ? user.id : '';

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // ── Profile Card ─────────────────────────────────────────────────────
        _ProfileCard(
          name: user.name,
          classInfo: classInfo,
          rollNo: rollNo,
          photoUrl: user.photoUrl,
        ),

        const SizedBox(height: 20),

        // ── Due Soon ─────────────────────────────────────────────────────────
        _SectionHeader(
          title: 'Due soon',
          urdu: 'جلد ادا کریں',
          trailing: allAssignmentsAsync.when(
            data: (all) {
              final count = all
                  .where((a) => a.status == AssignmentStatus.pending)
                  .length;
              return count > 0
                  ? Text(
                      'View All ($count)',
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        dueSoon.when(
          loading: () => const _LoadingRow(),
          error: (_, __) =>
              const _EmptyNotice(message: 'Could not load assignments.'),
          data: (items) {
            if (items.isEmpty) {
              return const _EmptyNotice(
                message: 'No assignments due soon. Great work! 🎉',
              );
            }
            return Column(
              children:
                  items.take(3).map((a) => _DueSoonCard(assignment: a)).toList(),
            );
          },
        ),

        const SizedBox(height: 20),

        // ── My Progress ──────────────────────────────────────────────────────
        _SectionHeader(
          title: 'My progress',
          urdu: 'میری پیشرفت',
          trailing: Text(
            'Term 1 (${DateTime.now().year})',
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        progressAsync.when(
          loading: () => const _LoadingRow(),
          error: (_, __) =>
              const _EmptyNotice(message: 'Could not load progress.'),
          data: (progress) => _ProgressCard(progress: progress),
        ),

        const SizedBox(height: 20),

        // ── Recent Results ───────────────────────────────────────────────────
        _SectionHeader(
          title: 'Recent results',
          urdu: 'حالیہ نتائج',
          trailing: const Text(
            'View All',
            style: TextStyle(
              color: AppTheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        recentResults.when(
          loading: () => const _LoadingRow(),
          error: (_, __) =>
              const _EmptyNotice(message: 'Could not load results.'),
          data: (items) {
            if (items.isEmpty) {
              return const _EmptyNotice(message: 'No results published yet.');
            }
            return Column(
              children: items.map((r) => _RecentResultCard(result: r)).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Card — matches reference exactly
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.classInfo,
    required this.rollNo,
    this.photoUrl,
  });

  final String name;
  final String classInfo;
  final String rollNo;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 16, 14, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCDD8E8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Left content ──────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      'Assalam o Alaikum,',
                      style: TextStyle(
                        color: AppTheme.accent.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                // Student Name (large bold)
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                // Urdu motivational subtitle
                const Text(
                  'اپنی پڑھائی جاری رکھیں • Keep up your great progress!',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                // Class badge
                if (classInfo.isNotEmpty) ...[
                  _InfoBadge(
                    icon: Icons.school_outlined,
                    label: 'Class $classInfo',
                  ),
                  const SizedBox(height: 7),
                ],
                // Roll No badge
                if (rollNo.isNotEmpty)
                  _InfoBadge(
                    icon: Icons.badge_outlined,
                    label: 'Roll No: $rollNo',
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // ── Profile Avatar ────────────────────────────────────────────────
          CircleAvatar(
            radius: 38,
            backgroundColor: AppTheme.primary,
            foregroundImage:
                photoUrl != null && photoUrl!.isNotEmpty
                    ? NetworkImage(photoUrl!)
                    : null,
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.primary),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header — matches reference style (title + urdu + trailing)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.urdu,
    this.trailing,
  });

  final String title;
  final String? urdu;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.accent,
            ),
          ),
          if (urdu != null) ...[
            const SizedBox(width: 6),
            Text(
              urdu!,
              style: const TextStyle(
                color: AppTheme.mutedText,
                fontSize: 11,
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Due Soon Card — matches reference cards exactly (icon + title + badge + action button)
// ─────────────────────────────────────────────────────────────────────────────
class _DueSoonCard extends StatelessWidget {
  const _DueSoonCard({required this.assignment});

  final StudentAssignment assignment;

  // Subject-based icon background color
  Color get _iconBg {
    final s = assignment.subject.toLowerCase();
    if (s.contains('physics') || s.contains('chem')) {
      return const Color(0xFFFFEDD5);
    }
    if (s.contains('math')) return const Color(0xFFEFF6FF);
    if (s.contains('urdu') || s.contains('english') || s.contains('grammar')) {
      return const Color(0xFFF0FFFE);
    }
    if (s.contains('bio')) return const Color(0xFFDCFCE7);
    return const Color(0xFFFEF9C3);
  }

  Color get _iconColor {
    final s = assignment.subject.toLowerCase();
    if (s.contains('physics') || s.contains('chem')) {
      return const Color(0xFFF97316);
    }
    if (s.contains('math')) return const Color(0xFF2563EB);
    if (s.contains('urdu') || s.contains('english') || s.contains('grammar')) {
      return const Color(0xFF0D9488);
    }
    if (s.contains('bio')) return const Color(0xFF16A34A);
    return const Color(0xFFD97706);
  }

  IconData get _typeIcon {
    final t = assignment.type.toLowerCase();
    if (t.contains('quiz')) return Icons.quiz_outlined;
    if (t.contains('homework')) return Icons.home_work_outlined;
    if (t.contains('project')) return Icons.folder_outlined;
    return Icons.insert_drive_file_outlined;
  }

  // Badge color
  Color get _badgeTextColor {
    final h = assignment.timeUntilDue.inHours;
    if (h < 24) return const Color(0xFFEA580C); // orange-700
    return const Color(0xFF475569); // slate-600
  }

  Color get _badgeBgColor {
    final h = assignment.timeUntilDue.inHours;
    if (h < 24) return const Color(0xFFFFF3E0);
    return const Color(0xFFF1F5F9);
  }

  // Action button
  String get _actionLabel {
    final t = assignment.type.toLowerCase();
    if (t.contains('quiz')) return 'Start Practice';
    if (t.contains('homework')) return 'Upload Doc';
    return 'Submit Now';
  }

  Color get _actionColor {
    final t = assignment.type.toLowerCase();
    if (t.contains('quiz')) return const Color(0xFF0D9488);
    if (t.contains('homework')) return AppTheme.primary;
    return const Color(0xFFF97316);
  }

  bool get _actionFilled {
    // Homework gets outlined, others get filled
    return !assignment.type.toLowerCase().contains('homework');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subject icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_typeIcon, size: 22, color: _iconColor),
          ),
          const SizedBox(width: 12),
          // Content column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Due badge (same row)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        assignment.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.accent,
                          height: 1.3,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Due badge pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _badgeBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        assignment.dueDateLabel,
                        style: TextStyle(
                          color: _badgeTextColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Type + teacher
                Text(
                  '${assignment.type} • ${assignment.teacherName}',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 9),
                // Time + action button
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppTheme.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        DateFormat(
                          'EEE, MMM d • hh:mm a',
                        ).format(assignment.dueDate),
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action button
                    _actionFilled
                        ? _FilledActionButton(
                            label: _actionLabel,
                            color: _actionColor,
                          )
                        : _OutlinedActionButton(
                            label: _actionLabel,
                            color: _actionColor,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilledActionButton extends StatelessWidget {
  const _FilledActionButton({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress Card — matches reference layout (circular ring LEFT, metrics RIGHT)
// ─────────────────────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final StudentProgress progress;

  Color _attendanceLabelColor(String label) {
    switch (label.toLowerCase()) {
      case 'excellent':
        return const Color(0xFF16A34A);
      case 'good':
        return const Color(0xFF0284C7);
      case 'average':
        return const Color(0xFFD97706);
      default:
        return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendancePct = progress.attendancePercent;
    final onTimePct = progress.onTimePercent;
    final attendLabel = progress.attendanceLabel;
    final attendColor = _attendanceLabelColor(attendLabel);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Circular ring ─────────────────────────────────────────────────
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: CircularProgressIndicator(
                    value: attendancePct / 100,
                    strokeWidth: 7,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF0D9488),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${attendancePct.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.accent,
                      ),
                    ),
                    Text(
                      'Grade ${progress.gradeLabel}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.mutedText,
                      ),
                    ),
                    const Text(
                      'Average',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ── Right metrics ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attendance row
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text(
                        'Attendance',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                    // "Excellent" badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: attendColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        attendLabel,
                        style: TextStyle(
                          color: attendColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${attendancePct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    '${progress.presentDays} of ${progress.totalDays} days',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 11,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Homework On-Time row
                Row(
                  children: [
                    const Icon(
                      Icons.check_box_outlined,
                      size: 15,
                      color: Color(0xFF0D9488),
                    ),
                    const SizedBox(width: 5),
                    const Expanded(
                      child: Text(
                        'Homework On-Time',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
                    Text(
                      '${onTimePct.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    '${progress.submittedOnTime} of ${progress.totalAssignments}'
                    ' tasks submitted timely',
                    style: const TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 11,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Result Card — matches reference (icon + title + graded date + marks/grade)
// ─────────────────────────────────────────────────────────────────────────────
class _RecentResultCard extends StatelessWidget {
  const _RecentResultCard({required this.result});

  final StudentResult result;

  IconData get _icon {
    final s = result.subject.toLowerCase();
    if (s.contains('math')) return Icons.calculate_outlined;
    if (s.contains('physics')) return Icons.science_outlined;
    if (s.contains('english') || s.contains('grammar')) {
      return Icons.translate_rounded;
    }
    if (s.contains('bio')) return Icons.biotech_outlined;
    if (s.contains('urdu')) return Icons.menu_book_outlined;
    if (s.contains('chem')) return Icons.science_outlined;
    return Icons.book_outlined;
  }

  Color get _iconBg {
    final s = result.subject.toLowerCase();
    if (s.contains('math')) return const Color(0xFFEFF6FF);
    if (s.contains('physics')) return const Color(0xFFFFF7ED);
    if (s.contains('english') || s.contains('grammar')) {
      return const Color(0xFFF5F3FF);
    }
    if (s.contains('bio')) return const Color(0xFFF0FDF4);
    return AppTheme.primarySoft;
  }

  Color get _iconColor {
    final s = result.subject.toLowerCase();
    if (s.contains('math')) return const Color(0xFF2563EB);
    if (s.contains('physics')) return const Color(0xFFF97316);
    if (s.contains('english') || s.contains('grammar')) {
      return const Color(0xFF7C3AED);
    }
    if (s.contains('bio')) return const Color(0xFF16A34A);
    return AppTheme.primary;
  }

  Color get _gradeColor {
    final pct = result.percentage;
    if (pct >= 80) return const Color(0xFF16A34A); // green A
    if (pct >= 60) return const Color(0xFFD97706); // amber B
    return AppTheme.error; // red F
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Row(
        children: [
          // Subject icon box
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 22, color: _iconColor),
          ),
          const SizedBox(width: 12),
          // Title + date/type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.accent,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Graded ${_relativeDate(result.gradedAt)} • ${result.type}',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Marks + grade badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${result.marksObtained.toStringAsFixed(0)}/'
                '${result.totalMarks.toStringAsFixed(0)}',
                style: TextStyle(
                  color: _gradeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _gradeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Grade ${result.grade} (${result.percentage.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    color: _gradeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────
class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EDF4)),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
