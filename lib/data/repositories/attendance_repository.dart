import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';

enum AttendanceStatus { present, absent, late, leave }

String attendanceErrorMessage(Object error) {
  if (error is FirebaseException && error.code == 'permission-denied') {
    return 'Attendance access was denied. Publish the updated Firestore rules and confirm you are signed in as the teacher who owns this class.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}

abstract interface class AttendanceRepository {
  Future<List<UserModel>> getStudentsForSchool(String schoolId);

  Future<List<UserModel>> getTeacherManagedStudents({
    required String teacherId,
    required String classSection,
  });

  Future<Map<String, AttendanceStatus>> getDailyAttendance({
    required String schoolId,
    required String classSection,
    required String dateKey,
  });

  Future<void> saveDailyAttendance({
    required String schoolId,
    required String classSection,
    required String dateKey,
    required String teacherId,
    required Map<String, AttendanceStatus> statuses,
  });
}

class FirestoreAttendanceRepository implements AttendanceRepository {
  FirestoreAttendanceRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<UserModel>> getStudentsForSchool(String schoolId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('schoolId', isEqualTo: schoolId)
        .get();

    final students = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
        .toList();
    students.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
    return students;
  }

  @override
  Future<List<UserModel>> getTeacherManagedStudents({
    required String teacherId,
    required String classSection,
  }) async {
    final classes = _firestore
        .collection('users')
        .doc(teacherId)
        .collection('teacherClasses');
    final classSnapshot = await classes
        .where('profileSection', isEqualTo: classSection.trim())
        .limit(1)
        .get();
    if (classSnapshot.docs.isEmpty) {
      return const <UserModel>[];
    }

    final studentSnapshot = await classSnapshot.docs.single.reference
        .collection('students')
        .get();
    final students = studentSnapshot.docs.map((document) {
      final data = document.data();
      return UserModel(
        id: document.id,
        name: (data['fullName'] as String? ?? '').trim(),
        email: '',
        role: 'student',
        schoolId: '',
        classSections: [classSection.trim()],
      );
    }).toList();
    students.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );
    return students;
  }

  @override
  Future<Map<String, AttendanceStatus>> getDailyAttendance({
    required String schoolId,
    required String classSection,
    required String dateKey,
  }) async {
    final snapshot = await _attendanceDocument(
      schoolId,
      classSection,
      dateKey,
    ).get();
    final rawStatuses = snapshot.data()?['statuses'];
    if (rawStatuses is! Map<String, dynamic>) {
      return <String, AttendanceStatus>{};
    }

    final statuses = <String, AttendanceStatus>{};
    for (final entry in rawStatuses.entries) {
      final status = _parseStatus(entry.value);
      if (status != null) {
        statuses[entry.key] = status;
      }
    }
    return statuses;
  }

  @override
  Future<void> saveDailyAttendance({
    required String schoolId,
    required String classSection,
    required String dateKey,
    required String teacherId,
    required Map<String, AttendanceStatus> statuses,
  }) async {
    final document = _attendanceDocument(schoolId, classSection, dateKey);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      final existing = snapshot.data()?['statuses'];
      final mergedStatuses = <String, String>{};
      if (existing is Map<String, dynamic>) {
        for (final entry in existing.entries) {
          if (entry.value is String) {
            mergedStatuses[entry.key] = entry.value as String;
          }
        }
      }
      mergedStatuses.addAll(
        statuses.map((studentId, status) => MapEntry(studentId, status.name)),
      );

      transaction.set(document, {
        'schoolId': schoolId,
        'classSection': classSection,
        'dateKey': dateKey,
        'teacherId': teacherId,
        'statuses': mergedStatuses,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  DocumentReference<Map<String, dynamic>> _attendanceDocument(
    String schoolId,
    String classSection,
    String dateKey,
  ) {
    final documentId =
        'attendance_${dateKey}_${Uri.encodeComponent(classSection)}';
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('attendance')
        .doc(documentId);
  }

  AttendanceStatus? _parseStatus(dynamic value) {
    for (final status in AttendanceStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return null;
  }
}

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return FirestoreAttendanceRepository(FirebaseFirestore.instance);
});

bool isStudentAssignedToClass(UserModel student, String classSection) {
  final normalizedClass = classSection.trim().toLowerCase();
  return student.classSections.any(
    (assignedClass) => assignedClass.trim().toLowerCase() == normalizedClass,
  );
}

String attendanceDateKey([DateTime? date]) {
  final value = date ?? DateTime.now();
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

class AttendanceClassDetails {
  const AttendanceClassDetails({
    required this.className,
    required this.section,
  });

  final String className;
  final String section;

  factory AttendanceClassDetails.fromAssignment(String assignment) {
    final match = RegExp(
      r'^(.*?)(?:\s*[-/]\s*|\s+section\s+)([A-Za-z0-9]+)$',
      caseSensitive: false,
    ).firstMatch(assignment.trim());
    if (match == null) {
      return AttendanceClassDetails(
        className: assignment.trim(),
        section: 'Not specified',
      );
    }
    return AttendanceClassDetails(
      className: match.group(1)!.trim(),
      section: match.group(2)!.trim(),
    );
  }
}
