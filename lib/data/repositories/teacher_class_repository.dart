import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeacherClass {
  const TeacherClass({
    required this.id,
    required this.profileSection,
    required this.name,
  });

  final String id;
  final String profileSection;
  final String name;

  factory TeacherClass.fromFirestore(String id, Map<String, dynamic> data) {
    final profileSection = (data['profileSection'] as String? ?? '').trim();
    final className = _firstNonEmpty([
      data['className'],
      data['gradeName'],
      data['grade'],
    ]);
    final sectionName = _firstNonEmpty([data['sectionName'], data['section']]);
    final storedName = (data['name'] as String? ?? '').trim();
    final hasSectionInName = RegExp(
      r'(?:\s*[-/]\s*|\s+section\s+)[A-Za-z0-9]+$',
      caseSensitive: false,
    ).hasMatch(storedName);
    final name = hasSectionInName
        ? storedName
        : className != null
        ? sectionName == null
              ? className
              : '$className - $sectionName'
        : profileSection;
    return TeacherClass(id: id, profileSection: profileSection, name: name);
  }

  static String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}

class ClassStudent {
  const ClassStudent({
    required this.id,
    required this.fullName,
    required this.rollNumber,
    required this.contactNumber,
    this.fatherName = '',
    this.email = '',
    this.gender = '',
    this.dateOfBirth = '',
    this.address = '',
  });

  final String id;
  final String fullName;
  final String rollNumber;
  final String contactNumber;
  final String fatherName;
  final String email;
  final String gender;
  final String dateOfBirth;
  final String address;

  factory ClassStudent.fromFirestore(String id, Map<String, dynamic> data) {
    return ClassStudent(
      id: id,
      fullName: (data['fullName'] as String? ?? '').trim(),
      rollNumber: (data['rollNumber'] as String? ?? '').trim(),
      contactNumber: (data['contactNumber'] as String? ?? '').trim(),
      fatherName: (data['fatherName'] as String? ?? '').trim(),
      email: (data['email'] as String? ?? '').trim(),
      gender: (data['gender'] as String? ?? '').trim(),
      dateOfBirth: (data['dateOfBirth'] as String? ?? '').trim(),
      address: (data['address'] as String? ?? '').trim(),
    );
  }
}

abstract interface class TeacherClassRepository {
  Future<List<TeacherClass>> getClasses({
    required String teacherId,
    required List<String> assignedSections,
  });

  Future<void> renameClass({
    required String teacherId,
    required String classId,
    required String name,
  });

  Future<List<ClassStudent>> getStudents({
    required String teacherId,
    required String classId,
  });

  Future<void> addStudent({
    required String teacherId,
    required String classId,
    required String fullName,
    required String rollNumber,
    required String contactNumber,
  });
}

abstract interface class ManagedTeacherClassRepository {
  Future<void> addDetailedStudent({
    required String teacherId,
    required String classId,
    required ClassStudent student,
  });

  Future<void> removeStudent({
    required String teacherId,
    required String classId,
    required String studentId,
  });

  Future<Map<String, String>> getClassAttendance({
    required String teacherId,
    required String classId,
    required String dateKey,
  });

  Future<void> saveClassAttendance({
    required String teacherId,
    required String classId,
    required String dateKey,
    required Map<String, String> statuses,
  });
}

class FirestoreTeacherClassRepository
    implements TeacherClassRepository, ManagedTeacherClassRepository {
  FirestoreTeacherClassRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _classes(String teacherId) =>
      _firestore
          .collection('users')
          .doc(teacherId)
          .collection('teacherClasses');

  @override
  Future<List<TeacherClass>> getClasses({
    required String teacherId,
    required List<String> assignedSections,
  }) async {
    final sections = assignedSections
        .map((section) => section.trim())
        .where((section) => section.isNotEmpty)
        .toSet()
        .toList();
    final collection = _classes(teacherId);
    final snapshot = await collection.get();
    final classesBySection = {
      for (final doc in snapshot.docs)
        (doc.data()['profileSection'] as String? ?? '').trim():
            TeacherClass.fromFirestore(doc.id, doc.data()),
    };

    for (final section in sections) {
      if (!classesBySection.containsKey(section)) {
        final document = await collection.add({
          'profileSection': section,
          'name': section,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        classesBySection[section] = TeacherClass(
          id: document.id,
          profileSection: section,
          name: section,
        );
      }
    }

    return [for (final section in sections) classesBySection[section]!];
  }

  @override
  Future<void> renameClass({
    required String teacherId,
    required String classId,
    required String name,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw const FormatException('Class name is required.');
    }
    await _classes(teacherId).doc(classId).update({
      'name': trimmedName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<ClassStudent>> getStudents({
    required String teacherId,
    required String classId,
  }) async {
    final snapshot = await _classes(
      teacherId,
    ).doc(classId).collection('students').get();
    final students = snapshot.docs
        .map((doc) => ClassStudent.fromFirestore(doc.id, doc.data()))
        .toList();
    students.sort((first, second) {
      final byRoll = first.rollNumber.toLowerCase().compareTo(
        second.rollNumber.toLowerCase(),
      );
      return byRoll != 0
          ? byRoll
          : first.fullName.toLowerCase().compareTo(
              second.fullName.toLowerCase(),
            );
    });
    return students;
  }

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
    final trimmedName = student.fullName.trim();
    final trimmedRoll = student.rollNumber.trim();
    final trimmedContact = student.contactNumber.trim();
    if (trimmedName.isEmpty ||
        trimmedRoll.isEmpty ||
        trimmedContact.isEmpty ||
        student.fatherName.trim().isEmpty) {
      throw const FormatException('Complete all student details.');
    }

    final students = _classes(teacherId).doc(classId).collection('students');
    final duplicate = await students
        .where('rollNumber', isEqualTo: trimmedRoll)
        .limit(1)
        .get();
    if (duplicate.docs.isNotEmpty) {
      throw const FormatException(
        'A student with this roll number is already in the class.',
      );
    }

    await students.add({
      'fullName': trimmedName,
      'rollNumber': trimmedRoll,
      'contactNumber': trimmedContact,
      'fatherName': student.fatherName.trim(),
      'email': student.email.trim(),
      'gender': student.gender.trim(),
      'dateOfBirth': student.dateOfBirth.trim(),
      'address': student.address.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeStudent({
    required String teacherId,
    required String classId,
    required String studentId,
  }) async {
    await _classes(
      teacherId,
    ).doc(classId).collection('students').doc(studentId).delete();
  }

  CollectionReference<Map<String, dynamic>> _attendance(
    String teacherId,
    String classId,
  ) => _classes(teacherId).doc(classId).collection('attendance');

  @override
  Future<Map<String, String>> getClassAttendance({
    required String teacherId,
    required String classId,
    required String dateKey,
  }) async {
    final snapshot = await _attendance(teacherId, classId).doc(dateKey).get();
    final rawStatuses = snapshot.data()?['statuses'];
    if (rawStatuses is! Map<String, dynamic>) return const {};
    return {
      for (final entry in rawStatuses.entries)
        if (entry.value is String) entry.key: entry.value as String,
    };
  }

  @override
  Future<void> saveClassAttendance({
    required String teacherId,
    required String classId,
    required String dateKey,
    required Map<String, String> statuses,
  }) async {
    final document = _attendance(teacherId, classId).doc(dateKey);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(document);
      transaction.set(document, {
        'dateKey': dateKey,
        'teacherId': teacherId,
        'statuses': statuses,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}

final teacherClassRepositoryProvider = Provider<TeacherClassRepository>((ref) {
  return FirestoreTeacherClassRepository(FirebaseFirestore.instance);
});
