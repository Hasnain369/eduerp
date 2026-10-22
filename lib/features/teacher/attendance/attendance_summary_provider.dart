import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/attendance_repository.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

final teacherAttendancePercentageProvider = FutureProvider.family<int, String>((
  ref,
  teacherId,
) async {
  final user = ref.watch(
    authStateNotifierProvider.select((state) => state.user),
  );
  if (user == null || user.id != teacherId || !user.canAccessTeacherFeatures) {
    return 0;
  }

  final repository = ref.read(attendanceRepositoryProvider);
  final schoolStudents = await repository.getStudentsForSchool(user.schoolId);
  final sections = user.classSections
      .map((section) => section.trim())
      .where((section) => section.isNotEmpty)
      .toSet();
  var studentCount = 0;
  var presentCount = 0;

  for (final classSection in sections) {
    final students = <String, UserModel>{
      for (final student in schoolStudents)
        if (isStudentAssignedToClass(student, classSection))
          student.id: student,
      for (final student in await repository.getTeacherManagedStudents(
        teacherId: user.id,
        classSection: classSection,
      ))
        student.id: student,
    };
    final statuses = await repository.getDailyAttendance(
      schoolId: user.schoolId,
      classSection: classSection,
      dateKey: attendanceDateKey(),
    );

    studentCount += students.length;
    presentCount += students.values
        .where((student) => statuses[student.id] == AttendanceStatus.present)
        .length;
  }

  if (studentCount == 0) return 0;
  return (presentCount * 100 / studentCount).round();
});
