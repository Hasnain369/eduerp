import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TeacherAssignment {
  const TeacherAssignment({
    required this.id,
    required this.date,
    required this.subject,
    required this.topic,
  });

  final String id;
  final DateTime date;
  final String subject;
  final String topic;

  factory TeacherAssignment.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final rawDate = data['date'];
    final date = switch (rawDate) {
      Timestamp value => value.toDate(),
      DateTime value => value,
      String value => DateTime.tryParse(value) ?? DateTime.now(),
      _ => DateTime.now(),
    };
    return TeacherAssignment(
      id: id,
      date: date,
      subject: (data['subject'] as String? ?? '').trim(),
      topic: (data['topic'] as String? ?? '').trim(),
    );
  }
}

abstract interface class TeacherAssignmentRepository {
  Future<List<TeacherAssignment>> getAssignments({
    required String schoolId,
    required String teacherId,
  });

  Future<void> createAssignment({
    required String schoolId,
    required String teacherId,
    required DateTime date,
    required String subject,
    required String topic,
  });
}

class FirestoreTeacherAssignmentRepository
    implements TeacherAssignmentRepository {
  FirestoreTeacherAssignmentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<TeacherAssignment>> getAssignments({
    required String schoolId,
    required String teacherId,
  }) async {
    final snapshot = await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .where('teacherId', isEqualTo: teacherId)
        .get();
    final assignments = snapshot.docs
        .map((doc) => TeacherAssignment.fromFirestore(doc.id, doc.data()))
        .toList();
    assignments.sort((first, second) => second.date.compareTo(first.date));
    return assignments;
  }

  @override
  Future<void> createAssignment({
    required String schoolId,
    required String teacherId,
    required DateTime date,
    required String subject,
    required String topic,
  }) async {
    final assignmentDate = DateTime(date.year, date.month, date.day);
    await _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .add({
          'schoolId': schoolId,
          'teacherId': teacherId,
          'date': Timestamp.fromDate(assignmentDate),
          'subject': subject.trim(),
          'topic': topic.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}

final teacherAssignmentRepositoryProvider =
    Provider<TeacherAssignmentRepository>((ref) {
      return FirestoreTeacherAssignmentRepository(FirebaseFirestore.instance);
    });
