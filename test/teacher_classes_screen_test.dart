import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/data/repositories/auth_repository.dart';
import 'package:project/data/repositories/teacher_class_repository.dart';
import 'package:project/data/sources/firebase/firebase_auth_source.dart';
import 'package:project/features/teacher/classes/teacher_classes_screen.dart';
import 'package:project/models/user_model.dart';
import 'package:project/providers/auth_provider.dart';

void main() {
  testWidgets('teacher sees assigned classes, renames one, and adds students', (
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
          classSections: const ['Grade 9-A'],
        ),
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateNotifierProvider.overrideWith((ref) => authNotifier),
          teacherClassRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: TeacherClassesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Grade 9'), findsOneWidget);
    expect(find.text('Section A'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit class name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Blue');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.classes.single.name, 'Grade 9 - Blue');
    expect(find.text('Section Blue'), findsOneWidget);

    await tester.tap(find.text('Grade 9'));
    await tester.pumpAndSettle();
    expect(find.text('No students yet'), findsOneWidget);

    await tester.tap(find.text('Add student'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Amina Rahman');
    await tester.enterText(fields.at(1), 'Imran Rahman');
    await tester.enterText(fields.at(2), 'R-12');
    await tester.enterText(fields.at(3), '555-0102');
    await tester.tap(find.text('Add student').last);
    await tester.pumpAndSettle();

    expect(find.text('Amina Rahman'), findsOneWidget);
    expect(find.textContaining('Roll R-12 · 555-0102'), findsOneWidget);
    expect(find.textContaining('Father: Imran Rahman'), findsOneWidget);

    await tester.tap(find.byTooltip('Student actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove student'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove').last);
    await tester.pumpAndSettle();
    expect(find.text('No students yet'), findsOneWidget);
  });
}

class _FakeTeacherClassRepository
    implements TeacherClassRepository, ManagedTeacherClassRepository {
  final List<TeacherClass> classes = [];
  final Map<String, List<ClassStudent>> students = {};

  @override
  Future<List<TeacherClass>> getClasses({
    required String teacherId,
    required List<String> assignedSections,
  }) async {
    for (final section in assignedSections) {
      if (!classes.any(
        (teacherClass) => teacherClass.profileSection == section,
      )) {
        classes.add(
          TeacherClass.fromFirestore('class-${classes.length + 1}', {
            'profileSection': section,
            'name': 'Ramondino Vs Arnold',
          }),
        );
      }
    }
    return List.of(classes);
  }

  @override
  Future<void> renameClass({
    required String teacherId,
    required String classId,
    required String name,
  }) async {
    final index = classes.indexWhere(
      (teacherClass) => teacherClass.id == classId,
    );
    final teacherClass = classes[index];
    classes[index] = TeacherClass(
      id: teacherClass.id,
      profileSection: teacherClass.profileSection,
      name: name,
    );
  }

  @override
  Future<List<ClassStudent>> getStudents({
    required String teacherId,
    required String classId,
  }) async => List.of(students[classId] ?? const []);

  @override
  Future<void> addStudent({
    required String teacherId,
    required String classId,
    required String fullName,
    required String rollNumber,
    required String contactNumber,
  }) async {
    await addDetailedStudent(
      teacherId: teacherId,
      classId: classId,
      student: ClassStudent(
        id: '',
        fullName: fullName,
        rollNumber: rollNumber,
        contactNumber: contactNumber,
      ),
    );
  }

  @override
  Future<void> addDetailedStudent({
    required String teacherId,
    required String classId,
    required ClassStudent student,
  }) async {
    students.putIfAbsent(classId, () => []);
    students[classId]!.add(
      ClassStudent(
        id: 'student-${students[classId]!.length + 1}',
        fullName: student.fullName,
        fatherName: student.fatherName,
        rollNumber: student.rollNumber,
        contactNumber: student.contactNumber,
        email: student.email,
        gender: student.gender,
        dateOfBirth: student.dateOfBirth,
        address: student.address,
      ),
    );
  }

  @override
  Future<void> removeStudent({
    required String teacherId,
    required String classId,
    required String studentId,
  }) async {
    students[classId]?.removeWhere((student) => student.id == studentId);
  }

  @override
  Future<Map<String, String>> getClassAttendance({
    required String teacherId,
    required String classId,
    required String dateKey,
  }) async => const {};

  @override
  Future<void> saveClassAttendance({
    required String teacherId,
    required String classId,
    required String dateKey,
    required Map<String, String> statuses,
  }) async {}
}
