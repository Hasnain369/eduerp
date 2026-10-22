import 'package:flutter_test/flutter_test.dart';
import 'package:project/models/user_model.dart';

void main() {
  test('UserModel should parse a Firestore profile into a role-aware user', () {
    final user = UserModel.fromFirestore('uid-123', {
      'name': 'Hasnain',
      'email': 'hasnain@example.com',
      'role': 'student',
    });

    expect(user.id, 'uid-123');
    expect(user.name, 'Hasnain');
    expect(user.email, 'hasnain@example.com');
    expect(user.role, 'student');
    expect(user.isStudent, isTrue);
    expect(user.isTeacher, isFalse);
  });

  test('Teacher profiles should carry approval and setup status', () {
    final user = UserModel.fromFirestore('teacher-1', {
      'name': 'Ms. Rahman',
      'email': 'rahman@school.edu',
      'role': 'teacher',
      'approvalStatus': 'pending',
      'profileCompleted': false,
      'schoolId': 'school-001',
    });

    expect(user.isTeacher, isTrue);
    expect(user.approvalStatus, 'pending');
    expect(user.isApproved, isFalse);
    expect(user.profileCompleted, isFalse);
    expect(user.schoolId, 'school-001');
  });

  test('Approved teachers use a single centralized access state', () {
    final approvedTeacher = UserModel.fromFirestore('teacher-2', {
      'name': 'Mr. Ahmed',
      'email': 'ahmed@school.edu',
      'role': 'teacher',
      'approvalStatus': 'approved',
      'profileCompleted': true,
      'schoolId': 'school-001',
      'subjects': ['Mathematics'],
      'classSections': ['Grade 9-A'],
    });

    expect(approvedTeacher.isApproved, isTrue);
    expect(approvedTeacher.canAccessTeacherFeatures, isTrue);
    expect(
      approvedTeacher.teacherAccessState,
      TeacherAccessState.approvedReady,
    );
    expect(approvedTeacher.hasAssignedClasses, isTrue);
    expect(approvedTeacher.hasAssignedSubjects, isTrue);
  });

  test(
    'Approved teachers without classes show the correct empty-state state',
    () {
      final teacher = UserModel.fromFirestore('teacher-3', {
        'name': 'Ms. Ali',
        'email': 'ali@school.edu',
        'role': 'teacher',
        'approvalStatus': 'approved',
        'profileCompleted': true,
        'schoolId': 'school-001',
        'subjects': ['Physics'],
        'classSections': <String>[],
      });

      expect(teacher.teacherAccessState, TeacherAccessState.approvedNoClasses);
      expect(teacher.canAccessTeacherFeatures, isFalse);
      expect(teacher.hasAssignedClasses, isFalse);
    },
  );
}
