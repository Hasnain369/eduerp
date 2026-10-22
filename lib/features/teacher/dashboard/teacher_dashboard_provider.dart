import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/attendance_repository.dart';
import '../../../data/repositories/teacher_assignment_repository.dart';
import '../../../data/repositories/teacher_planner_repository.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

class TeacherDashboardSummary {
  const TeacherDashboardSummary({
    required this.studentCount,
    required this.assignmentCount,
    required this.todaysPeriods,
    required this.todaysLectures,
  });

  final int studentCount;
  final int? assignmentCount;
  final List<PlannerPeriod> todaysPeriods;
  final List<PlannerLecture> todaysLectures;
}

final teacherDashboardSummaryProvider =
    FutureProvider.family<TeacherDashboardSummary, String>((
      ref,
      teacherId,
    ) async {
      final user = ref.watch(
        authStateNotifierProvider.select((state) => state.user),
      );
      if (user == null || user.id != teacherId || !user.isTeacher) {
        return const TeacherDashboardSummary(
          studentCount: 0,
          assignmentCount: null,
          todaysPeriods: [],
          todaysLectures: [],
        );
      }

      final attendanceRepository = ref.read(attendanceRepositoryProvider);
      final students = <String, UserModel>{};
      if (user.isApproved && user.schoolId.isNotEmpty) {
        for (final student in await attendanceRepository.getStudentsForSchool(
          user.schoolId,
        )) {
          if (user.classSections.any(
            (section) => isStudentAssignedToClass(student, section),
          )) {
            students[student.id] = student;
          }
        }
      }
      for (final section in user.classSections) {
        for (final student
            in await attendanceRepository.getTeacherManagedStudents(
              teacherId: user.id,
              classSection: section,
            )) {
          students[student.id] = student;
        }
      }

      final assignmentCount = user.isApproved && user.schoolId.isNotEmpty
          ? (await ref
                    .read(teacherAssignmentRepositoryProvider)
                    .getAssignments(
                      schoolId: user.schoolId,
                      teacherId: user.id,
                    ))
                .length
          : null;
      final periods = await ref
          .read(teacherPlannerRepositoryProvider)
          .getPeriods(user.id);
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day);
      final lectures = await ref
          .read(teacherPlannerRepositoryProvider)
          .getLectures(user.id, plannerDateKey(todayDate));
      lectures.sort((first, second) {
        final firstDone = first.status == PlannerLectureStatus.done;
        final secondDone = second.status == PlannerLectureStatus.done;
        if (firstDone != secondDone) return firstDone ? 1 : -1;
        return first.startMinutes.compareTo(second.startMinutes);
      });

      return TeacherDashboardSummary(
        studentCount: students.length,
        assignmentCount: assignmentCount,
        todaysPeriods: periods
            .where((period) => period.dayOfWeek == todayDate.weekday)
            .toList(),
        todaysLectures: lectures,
      );
    });
