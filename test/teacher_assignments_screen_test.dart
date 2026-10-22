import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/data/repositories/auth_repository.dart';
import 'package:project/data/repositories/teacher_assignment_repository.dart';
import 'package:project/data/sources/firebase/firebase_auth_source.dart';
import 'package:project/features/teacher/assignments/teacher_assignments_screen.dart';
import 'package:project/models/user_model.dart';
import 'package:project/providers/auth_provider.dart';

void main() {
  testWidgets('teacher filters, views, and adds assignments', (tester) async {
    final now = DateUtils.dateOnly(DateTime.now());
    final repository = _FakeTeacherAssignmentRepository([
      TeacherAssignment(
        id: 'today',
        date: now,
        subject: 'Mathematics',
        topic: 'Fractions',
      ),
      TeacherAssignment(
        id: 'previous',
        date: now.subtract(const Duration(days: 1)),
        subject: 'Science',
        topic: 'Plants',
      ),
    ]);
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
          subjects: const ['Mathematics', 'Science'],
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateNotifierProvider.overrideWith((ref) => authNotifier),
          teacherAssignmentRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: TeacherAssignmentsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fractions'), findsOneWidget);
    expect(find.text('Plants'), findsOneWidget);

    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();
    expect(find.text('Fractions'), findsOneWidget);
    expect(find.text('Plants'), findsNothing);

    await tester.tap(find.text('Fractions'));
    await tester.pumpAndSettle();
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Topic'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add assignment'));
    await tester.pumpAndSettle();
    expect(find.text('Date'), findsOneWidget);
    expect(find.text('Subject'), findsOneWidget);
    expect(find.text('Topic'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).last, 'Geometry');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();

    expect(repository.createdSubject, 'Mathematics');
    expect(repository.createdTopic, 'Geometry');
    expect(repository.createdDate, now);
  });
}

class _FakeTeacherAssignmentRepository implements TeacherAssignmentRepository {
  _FakeTeacherAssignmentRepository(this.assignments);

  final List<TeacherAssignment> assignments;
  DateTime? createdDate;
  String? createdSubject;
  String? createdTopic;

  @override
  Future<List<TeacherAssignment>> getAssignments({
    required String schoolId,
    required String teacherId,
  }) async => List.of(assignments);

  @override
  Future<void> createAssignment({
    required String schoolId,
    required String teacherId,
    required DateTime date,
    required String subject,
    required String topic,
  }) async {
    createdDate = date;
    createdSubject = subject;
    createdTopic = topic;
    assignments.add(
      TeacherAssignment(
        id: 'created',
        date: date,
        subject: subject,
        topic: topic,
      ),
    );
  }
}
