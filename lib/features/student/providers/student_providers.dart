import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../data/student_repository.dart';
import '../models/student_assignment_model.dart';
import '../models/student_progress_model.dart';
import '../models/student_result_model.dart';

// ── Assignments stream ────────────────────────────────────────────────────────
final studentAssignmentsProvider =
    StreamProvider.autoDispose<List<StudentAssignment>>((ref) {
      final user = ref.watch(authStateNotifierProvider).user;
      if (user == null || !user.isStudent) return const Stream.empty();
      final schoolId = user.schoolId;
      final section =
          user.classSections.isNotEmpty ? user.classSections.first : '';
      if (schoolId.isEmpty || section.isEmpty) return const Stream.empty();
      return ref
          .read(studentRepositoryProvider)
          .assignmentsStream(schoolId: schoolId, classSection: section);
    });

// ── Results stream ────────────────────────────────────────────────────────────
final studentResultsProvider =
    StreamProvider.autoDispose<List<StudentResult>>((ref) {
      final user = ref.watch(authStateNotifierProvider).user;
      if (user == null || !user.isStudent) return const Stream.empty();
      final schoolId = user.schoolId;
      final section =
          user.classSections.isNotEmpty ? user.classSections.first : '';
      if (schoolId.isEmpty || section.isEmpty) return const Stream.empty();
      return ref
          .read(studentRepositoryProvider)
          .resultsStream(
            studentUid: user.id,
            schoolId: schoolId,
            classSection: section,
          );
    });

// ── Progress (async future) ───────────────────────────────────────────────────
final studentProgressProvider =
    FutureProvider.autoDispose<StudentProgress>((ref) async {
      final user = ref.watch(authStateNotifierProvider).user;
      if (user == null || !user.isStudent) return StudentProgress.empty;
      final schoolId = user.schoolId;
      final section =
          user.classSections.isNotEmpty ? user.classSections.first : '';
      if (schoolId.isEmpty || section.isEmpty) return StudentProgress.empty;
      return ref
          .read(studentRepositoryProvider)
          .getProgress(
            schoolId: schoolId,
            classSection: section,
            studentName: user.name,
          );
    });

// ── Due-soon assignments (next 3 days, pending only) ─────────────────────────
final dueSoonAssignmentsProvider =
    Provider.autoDispose<AsyncValue<List<StudentAssignment>>>((ref) {
      return ref.watch(studentAssignmentsProvider).whenData((all) {
        final now = DateTime.now();
        final cutoff = now.add(const Duration(days: 3));
        return all
            .where(
              (a) =>
                  a.status == AssignmentStatus.pending &&
                  a.dueDate.isAfter(now) &&
                  a.dueDate.isBefore(cutoff),
            )
            .toList()
          ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      });
    });

// ── Recent results (latest 3) ─────────────────────────────────────────────────
final recentResultsProvider =
    Provider.autoDispose<AsyncValue<List<StudentResult>>>((ref) {
      return ref.watch(studentResultsProvider).whenData(
        (all) => all.take(3).toList(),
      );
    });

// ── Current student user helper ───────────────────────────────────────────────
final currentStudentProvider = Provider.autoDispose<UserModel?>((ref) {
  final user = ref.watch(authStateNotifierProvider).user;
  return (user != null && user.isStudent) ? user : null;
});
