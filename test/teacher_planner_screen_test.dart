import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/data/repositories/attendance_repository.dart';
import 'package:project/data/repositories/auth_repository.dart';
import 'package:project/data/repositories/teacher_assignment_repository.dart';
import 'package:project/data/repositories/teacher_planner_repository.dart';
import 'package:project/data/sources/firebase/firebase_auth_source.dart';
import 'package:project/features/teacher/planner/lecture_planner_screen.dart';
import 'package:project/features/teacher/planner/planner_home_screen.dart';
import 'package:project/features/teacher/dashboard/teacher_dashboard_provider.dart';
import 'package:project/models/user_model.dart';
import 'package:project/providers/auth_provider.dart';

void main() {
  testWidgets('teacher saves a dated lecture with learning objectives', (
    tester,
  ) async {
    final plannerRepository = _FakeTeacherPlannerRepository();
    plannerRepository.failNextLectureRead = true;
    final container = ProviderContainer(
      overrides: [
        authStateNotifierProvider.overrideWith((ref) => _teacherNotifier()),
        teacherPlannerRepositoryProvider.overrideWithValue(plannerRepository),
        teacherAssignmentRepositoryProvider.overrideWithValue(
          _FakeTeacherAssignmentRepository(DateTime.now()),
        ),
        attendanceRepositoryProvider.overrideWithValue(
          _FakeAttendanceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await expectLater(
      container.read(teacherDashboardSummaryProvider('teacher-1').future),
      throwsStateError,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: LecturePlannerScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('CHAPTER / UNIT'),
      160,
      scrollable: scrollable,
    );
    await tester.enterText(find.byType(TextFormField).first, 'Unit 1: Algebra');
    await tester.scrollUntilVisible(
      find.text('LESSON TOPIC'),
      160,
      scrollable: scrollable,
    );
    await tester.enterText(
      find.byType(TextFormField).last,
      'Quadratic equations',
    );
    await tester.scrollUntilVisible(
      find.text('Student Learning Objectives'),
      160,
      scrollable: scrollable,
    );
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.hintText == 'Describe a learning objective',
      ),
      'Solve a quadratic equation',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save'),
      180,
      scrollable: scrollable,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(plannerRepository.lectures, hasLength(1));
    final lecture = plannerRepository.lectures.values.single;
    expect(lecture.subject, 'Mathematics');
    expect(lecture.classSection, 'Grade 9-A');
    expect(lecture.chapter, 'Unit 1: Algebra');
    expect(lecture.topic, 'Quadratic equations');
    expect(lecture.objectives, ['Solve a quadratic equation']);
    expect(lecture.dateKey, plannerDateKey(DateTime.now()));
    expect(find.text('Quadratic equations'), findsWidgets);
    final refreshedDashboard = await container.read(
      teacherDashboardSummaryProvider('teacher-1').future,
    );
    expect(
      refreshedDashboard.todaysLectures.single.topic,
      'Quadratic equations',
    );

    await tester.scrollUntilVisible(
      find.textContaining('Lectures on'),
      180,
      scrollable: scrollable,
    );
    final savedLectureCard = find.byKey(ValueKey('lecture-${lecture.id}'));
    await tester.ensureVisible(savedLectureCard);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: savedLectureCard, matching: find.text('Done')),
    );
    await tester.pumpAndSettle();
    expect(
      plannerRepository.lectures.values.single.status,
      PlannerLectureStatus.done,
    );
  });

  testWidgets('calendar shows activity and saves a day plan', (tester) async {
    final plannerRepository = _FakeTeacherPlannerRepository();
    final today = DateUtils.dateOnly(DateTime.now());
    plannerRepository.periods.add(
      PlannerPeriod(
        id: 'period-1',
        dayOfWeek: today.weekday,
        subject: 'Mathematics',
        classSection: 'Grade 9-A',
        startMinutes: 480,
        endMinutes: 525,
      ),
    );
    plannerRepository.days[plannerDateKey(today)] = PlannerDay(
      dateKey: plannerDateKey(today),
      periodStatuses: const {'period-1': PlannerPeriodStatus.done},
      tasks: const [],
    );
    plannerRepository.lectures['lecture-calendar'] = PlannerLecture(
      id: 'lecture-calendar',
      dateKey: plannerDateKey(today),
      classSection: 'Grade 9-A',
      startMinutes: 540,
      endMinutes: 585,
      subject: 'Mathematics',
      chapter: 'Unit 1',
      topic: 'Pythagorean theorem',
      objectives: const ['Apply the theorem'],
    );
    final assignmentRepository = _FakeTeacherAssignmentRepository(today);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateNotifierProvider.overrideWith((ref) => _teacherNotifier()),
          teacherPlannerRepositoryProvider.overrideWithValue(plannerRepository),
          teacherAssignmentRepositoryProvider.overrideWithValue(
            assignmentRepository,
          ),
        ],
        child: const MaterialApp(home: PlannerHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('1/1 periods done'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1/1 periods done'), findsOneWidget);
    expect(find.text('1 assignments'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Pythagorean theorem'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('Pythagorean theorem'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Fractions'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Fractions'), findsOneWidget);

    await tester.tap(find.text('Add plan').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Prepare worksheets');
    await tester.tap(find.text('Add plan').last);
    await tester.pumpAndSettle();

    expect(
      plannerRepository.days[plannerDateKey(today)]!.tasks,
      contains('Prepare worksheets'),
    );
    expect(find.text('Prepare worksheets'), findsOneWidget);
  });
}

AuthStateNotifier _teacherNotifier() =>
    AuthStateNotifier(AuthRepository(FirebaseAuthSource()))
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
          subjects: const ['Mathematics', 'Science'],
        ),
      );

class _FakeTeacherPlannerRepository implements TeacherPlannerRepository {
  final List<PlannerPeriod> periods = [];
  final Map<String, PlannerDay> days = {};
  final Map<String, PlannerLecture> lectures = {};
  int _nextPeriodId = 1;
  int _nextLectureId = 1;
  bool failNextLectureRead = false;

  @override
  Future<List<PlannerLecture>> getLectures(
    String teacherId,
    String dateKey,
  ) async => _lecturesForDate(dateKey);

  List<PlannerLecture> _lecturesForDate(String dateKey) {
    if (failNextLectureRead) {
      failNextLectureRead = false;
      throw StateError('Simulated cached schedule read failure');
    }
    return lectures.values
        .where((lecture) => lecture.dateKey == dateKey)
        .toList()
      ..sort(
        (first, second) => first.startMinutes.compareTo(second.startMinutes),
      );
  }

  @override
  Future<List<PlannerLecture>> getLecturesBetween(
    String teacherId,
    String startDateKey,
    String endDateKey,
  ) async => lectures.values
      .where(
        (lecture) =>
            lecture.dateKey.compareTo(startDateKey) >= 0 &&
            lecture.dateKey.compareTo(endDateKey) <= 0,
      )
      .toList();

  @override
  Future<String> saveLecture(String teacherId, PlannerLecture lecture) async {
    final id = lecture.id.isEmpty ? 'lecture-${_nextLectureId++}' : lecture.id;
    lectures[id] = PlannerLecture(
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
    return id;
  }

  @override
  Future<void> deleteLecture(String teacherId, String lectureId) async {
    lectures.remove(lectureId);
  }

  @override
  Future<void> setLectureStatus({
    required String teacherId,
    required String lectureId,
    required PlannerLectureStatus status,
  }) async {
    final lecture = lectures[lectureId]!;
    lectures[lectureId] = PlannerLecture(
      id: lecture.id,
      dateKey: lecture.dateKey,
      classSection: lecture.classSection,
      startMinutes: lecture.startMinutes,
      endMinutes: lecture.endMinutes,
      subject: lecture.subject,
      chapter: lecture.chapter,
      topic: lecture.topic,
      objectives: lecture.objectives,
      status: status,
    );
  }

  @override
  Future<List<PlannerPeriod>> getPeriods(String teacherId) async =>
      List.of(periods);

  @override
  Future<void> savePeriod(String teacherId, PlannerPeriod period) async {
    final id = period.id.isEmpty ? 'period-${_nextPeriodId++}' : period.id;
    periods.removeWhere((existing) => existing.id == id);
    periods.add(
      PlannerPeriod(
        id: id,
        dayOfWeek: period.dayOfWeek,
        subject: period.subject,
        classSection: period.classSection,
        startMinutes: period.startMinutes,
        endMinutes: period.endMinutes,
      ),
    );
  }

  @override
  Future<void> deletePeriod(String teacherId, String periodId) async {
    periods.removeWhere((period) => period.id == periodId);
  }

  @override
  Future<PlannerDay> getDay(String teacherId, String dateKey) async =>
      days[dateKey] ??
      PlannerDay(dateKey: dateKey, periodStatuses: const {}, tasks: const []);

  @override
  Future<List<PlannerDay>> getDaysBetween(
    String teacherId,
    String startDateKey,
    String endDateKey,
  ) async => days.values
      .where(
        (day) =>
            day.dateKey.compareTo(startDateKey) >= 0 &&
            day.dateKey.compareTo(endDateKey) <= 0,
      )
      .toList();

  @override
  Future<void> setPeriodStatus({
    required String teacherId,
    required String dateKey,
    required String periodId,
    required PlannerPeriodStatus status,
  }) async {
    final day = await getDay(teacherId, dateKey);
    days[dateKey] = PlannerDay(
      dateKey: dateKey,
      periodStatuses: {...day.periodStatuses, periodId: status},
      tasks: day.tasks,
    );
  }

  @override
  Future<void> addTask({
    required String teacherId,
    required String dateKey,
    required String task,
  }) async {
    final day = await getDay(teacherId, dateKey);
    days[dateKey] = PlannerDay(
      dateKey: dateKey,
      periodStatuses: day.periodStatuses,
      tasks: [...day.tasks, task],
    );
  }
}

class _FakeTeacherAssignmentRepository implements TeacherAssignmentRepository {
  _FakeTeacherAssignmentRepository(DateTime assignmentDate)
    : _assignments = [
        TeacherAssignment(
          id: 'assignment-1',
          date: assignmentDate,
          subject: 'Mathematics',
          topic: 'Fractions',
        ),
      ];

  final List<TeacherAssignment> _assignments;

  @override
  Future<List<TeacherAssignment>> getAssignments({
    required String schoolId,
    required String teacherId,
  }) async => List.of(_assignments);

  @override
  Future<void> createAssignment({
    required String schoolId,
    required String teacherId,
    required DateTime date,
    required String subject,
    required String topic,
  }) async {}
}

class _FakeAttendanceRepository implements AttendanceRepository {
  @override
  Future<List<UserModel>> getStudentsForSchool(String schoolId) async => [];

  @override
  Future<List<UserModel>> getTeacherManagedStudents({
    required String teacherId,
    required String classSection,
  }) async => [];

  @override
  Future<Map<String, AttendanceStatus>> getDailyAttendance({
    required String schoolId,
    required String classSection,
    required String dateKey,
  }) async => {};

  @override
  Future<void> saveDailyAttendance({
    required String schoolId,
    required String classSection,
    required String dateKey,
    required String teacherId,
    required Map<String, AttendanceStatus> statuses,
  }) async {}
}
