import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/data/repositories/auth_repository.dart';
import 'package:project/data/repositories/teacher_class_repository.dart';
import 'package:project/data/repositories/teacher_assignment_repository.dart';
import 'package:project/data/repositories/teacher_planner_repository.dart';
import 'package:project/data/sources/firebase/firebase_auth_source.dart';
import 'package:project/features/teacher/attendance/attendance_screen.dart';
import 'package:project/features/teacher/dashboard/teacher_dashboard.dart';
import 'package:project/models/user_model.dart';
import 'package:project/providers/auth_provider.dart';

void main() {
  testWidgets('teacher can mark and save attendance for an assigned class', (
    tester,
  ) async {
    final repository = _FakeTeacherClassRepository();
    final authNotifier = AuthStateNotifier(AuthRepository(FirebaseAuthSource()))
      ..setAuthenticatedUser(
        UserModel(
          id: 'teacher-1',
          name: 'Ms. Rahman',
          email: 'teacher@example.com',
          role: 'teacher',
          approvalStatus: 'pending',
          profileCompleted: true,
          classSections: const ['Grade 9-A', 'Grade 10-B'],
          subjects: const ['Mathematics'],
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateNotifierProvider.overrideWith((ref) => authNotifier),
          teacherClassRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: AttendanceScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grade 9'), findsOneWidget);
    expect(find.text('Grade 10'), findsOneWidget);
    expect(find.text('3 students'), findsOneWidget);

    await tester.tap(find.text('Grade 9'));
    await tester.pumpAndSettle();

    expect(find.text('Amina Rahman'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bilal Ahmed'),
      180,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Bilal Ahmed'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nadia Qureshi'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Nadia Qureshi'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Amina');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Present'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save attendance'));
    await tester.pumpAndSettle();

    expect(repository.savedStatuses.values, contains('present'));
  });

  testWidgets('dashboard shows the teacher profile and daily schedule', (
    tester,
  ) async {
    final plannerRepository = _FakeTeacherPlannerRepository();
    final authNotifier = AuthStateNotifier(AuthRepository(FirebaseAuthSource()))
      ..setAuthenticatedUser(
        UserModel(
          id: 'teacher-1',
          name: 'Ms. Rahman',
          email: 'teacher@example.com',
          role: 'teacher',
          approvalStatus: 'approved',
          schoolId: 'school-001',
          profileCompleted: true,
          classSections: const ['Grade 9-A'],
          subjects: const ['Mathematics'],
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateNotifierProvider.overrideWith((ref) => authNotifier),
          teacherAssignmentRepositoryProvider.overrideWithValue(
            _FakeTeacherAssignmentRepository(),
          ),
          teacherPlannerRepositoryProvider.overrideWithValue(plannerRepository),
        ],
        child: const MaterialApp(home: TeacherDashboard()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ms. Rahman'), findsWidgets);
    expect(find.text("Today's Schedule"), findsOneWidget);
    await tester.ensureVisible(find.text('Mark Attendance'));
    expect(find.text('Mark Attendance'), findsOneWidget);
    expect(find.text('Mark Done'), findsOneWidget);
    await tester.tap(find.text('Mark Attendance'));
    await tester.pumpAndSettle();
    expect(plannerRepository.statuses['lecture-1'], PlannerLectureStatus.done);
    expect(find.text('Mark Attendance'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Needs Grading'), findsNothing);
    expect(find.text('Class Snapshot'), findsNothing);
  });
}

class _FakeTeacherAssignmentRepository implements TeacherAssignmentRepository {
  @override
  Future<List<TeacherAssignment>> getAssignments({
    required String schoolId,
    required String teacherId,
  }) async => [
    for (var index = 0; index < 4; index++)
      TeacherAssignment(
        id: 'assignment-$index',
        date: DateTime.now(),
        subject: 'Mathematics',
        topic: 'Topic $index',
      ),
  ];

  @override
  Future<void> createAssignment({
    required String schoolId,
    required String teacherId,
    required DateTime date,
    required String subject,
    required String topic,
  }) async {}
}

class _FakeTeacherPlannerRepository implements TeacherPlannerRepository {
  final lectures = [
    const PlannerLecture(
      id: 'lecture-1',
      dateKey: '',
      classSection: 'Grade 9-A',
      startMinutes: 540,
      endMinutes: 585,
      subject: 'Mathematics',
      chapter: 'Chapter 1',
      topic: 'Linear Equations',
      objectives: [],
    ),
    const PlannerLecture(
      id: 'lecture-2',
      dateKey: '',
      classSection: 'Grade 10-B',
      startMinutes: 600,
      endMinutes: 645,
      subject: 'Mathematics',
      chapter: 'Chapter 2',
      topic: 'Quadratic Equations',
      objectives: [],
    ),
  ];
  final statuses = <String, PlannerLectureStatus>{};

  @override
  Future<List<PlannerLecture>> getLectures(
    String teacherId,
    String dateKey,
  ) async => [
    for (final lecture in lectures)
      PlannerLecture(
        id: lecture.id,
        dateKey: dateKey,
        classSection: lecture.classSection,
        startMinutes: lecture.startMinutes,
        endMinutes: lecture.endMinutes,
        subject: lecture.subject,
        chapter: lecture.chapter,
        topic: lecture.topic,
        objectives: lecture.objectives,
        status: statuses[lecture.id] ?? lecture.status,
      ),
  ];

  @override
  Future<List<PlannerLecture>> getLecturesBetween(
    String teacherId,
    String startDateKey,
    String endDateKey,
  ) async => const [];

  @override
  Future<String> saveLecture(String teacherId, PlannerLecture lecture) async =>
      lecture.id;

  @override
  Future<void> deleteLecture(String teacherId, String lectureId) async {
    lectures.removeWhere((lecture) => lecture.id == lectureId);
  }

  @override
  Future<void> setLectureStatus({
    required String teacherId,
    required String lectureId,
    required PlannerLectureStatus status,
  }) async {
    statuses[lectureId] = status;
  }

  @override
  Future<List<PlannerPeriod>> getPeriods(String teacherId) async => const [];

  @override
  Future<void> savePeriod(String teacherId, PlannerPeriod period) async {}

  @override
  Future<void> deletePeriod(String teacherId, String periodId) async {}

  @override
  Future<PlannerDay> getDay(String teacherId, String dateKey) async =>
      PlannerDay(dateKey: dateKey, periodStatuses: const {}, tasks: const []);

  @override
  Future<List<PlannerDay>> getDaysBetween(
    String teacherId,
    String startDateKey,
    String endDateKey,
  ) async => const [];

  @override
  Future<void> setPeriodStatus({
    required String teacherId,
    required String dateKey,
    required String periodId,
    required PlannerPeriodStatus status,
  }) async {}

  @override
  Future<void> addTask({
    required String teacherId,
    required String dateKey,
    required String task,
  }) async {}
}

class _FakeTeacherClassRepository
    implements TeacherClassRepository, ManagedTeacherClassRepository {
  final classes = [
    TeacherClass.fromFirestore('class-9', {
      'profileSection': 'Grade 9-A',
      'name': 'Grade 9-A',
    }),
    TeacherClass.fromFirestore('class-10', {
      'profileSection': 'Grade 10-B',
      'name': 'Grade 10-B',
    }),
  ];
  final Map<String, List<ClassStudent>> students = {
    'class-9': const [
      ClassStudent(
        id: 'student-1',
        fullName: 'Amina Rahman',
        rollNumber: '1',
        contactNumber: '555-0101',
      ),
      ClassStudent(
        id: 'student-2',
        fullName: 'Bilal Ahmed',
        rollNumber: '2',
        contactNumber: '555-0102',
      ),
      ClassStudent(
        id: 'managed-student-1',
        fullName: 'Nadia Qureshi',
        rollNumber: '3',
        contactNumber: '555-0103',
      ),
    ],
    'class-10': const [
      ClassStudent(
        id: 'student-3',
        fullName: 'Sara Khan',
        rollNumber: '1',
        contactNumber: '555-0104',
      ),
    ],
  };
  final Map<String, String> savedStatuses = {};

  @override
  Future<List<TeacherClass>> getClasses({
    required String teacherId,
    required List<String> assignedSections,
  }) async => classes
      .where(
        (teacherClass) =>
            assignedSections.contains(teacherClass.profileSection),
      )
      .toList();

  @override
  Future<void> renameClass({
    required String teacherId,
    required String classId,
    required String name,
  }) async {}

  @override
  Future<List<ClassStudent>> getStudents({
    required String teacherId,
    required String classId,
  }) async => students[classId] ?? const [];

  @override
  Future<void> addStudent({
    required String teacherId,
    required String classId,
    required String fullName,
    required String rollNumber,
    required String contactNumber,
  }) async {}

  @override
  Future<void> addDetailedStudent({
    required String teacherId,
    required String classId,
    required ClassStudent student,
  }) async {}

  @override
  Future<void> removeStudent({
    required String teacherId,
    required String classId,
    required String studentId,
  }) async {}

  @override
  Future<Map<String, String>> getClassAttendance({
    required String teacherId,
    required String classId,
    required String dateKey,
  }) async => savedStatuses;

  @override
  Future<void> saveClassAttendance({
    required String teacherId,
    required String classId,
    required String dateKey,
    required Map<String, String> statuses,
  }) async {
    savedStatuses
      ..clear()
      ..addAll(statuses);
  }
}
