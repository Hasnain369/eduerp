import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student_assignment_model.dart';
import '../models/student_progress_model.dart';
import '../models/student_result_model.dart';

class StudentRepository {
  StudentRepository(this._firestore);

  final FirebaseFirestore _firestore;

  // Assignments assigned to a specific class section
  Stream<List<StudentAssignment>> assignmentsStream({
    required String schoolId,
    required String classSection,
  }) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('assignments')
        .where('classSection', isEqualTo: classSection)
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => StudentAssignment.fromFirestore(doc.id, doc.data()),
              )
              .toList(),
        );
  }

  // Results for a specific student (stored under students/{uid}/results)
  Stream<List<StudentResult>> resultsStream({
    required String studentUid,
    required String schoolId,
    required String classSection,
  }) {
    return _firestore
        .collection('schools')
        .doc(schoolId)
        .collection('results')
        .where('classSection', isEqualTo: classSection)
        .orderBy('gradedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => StudentResult.fromFirestore(doc.id, doc.data()))
              .toList(),
        );
  }

  // Progress: read attendance from schools/{id}/attendance docs
  Future<StudentProgress> getProgress({
    required String schoolId,
    required String classSection,
    required String studentName,
  }) async {
    try {
      final attendanceSnap = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('attendance')
          .where('classSection', isEqualTo: classSection)
          .get();

      int totalDays = 0;
      int presentDays = 0;

      for (final doc in attendanceSnap.docs) {
        final data = doc.data();
        final records = data['records'] as Map<String, dynamic>?;
        if (records == null) continue;
        totalDays++;
        // Check by student name (key) or by studentId
        for (final entry in records.entries) {
          if (entry.key == studentName ||
              (entry.value is Map &&
                  (entry.value as Map)['name'] == studentName)) {
            final present = entry.value == 'present' ||
                (entry.value is Map &&
                    (entry.value as Map)['status'] == 'present');
            if (present) presentDays++;
            break;
          }
        }
      }

      // Assignment on-time from assignments collection
      final assignSnap = await _firestore
          .collection('schools')
          .doc(schoolId)
          .collection('assignments')
          .where('classSection', isEqualTo: classSection)
          .get();

      final totalAssignments = assignSnap.docs.length;
      int submittedOnTime = 0;
      int lateSubmissions = 0;

      for (final doc in assignSnap.docs) {
        final data = doc.data();
        final submissions = data['submissions'] as Map<String, dynamic>?;
        if (submissions == null) continue;
        for (final entry in submissions.entries) {
          if (entry.key == studentName) {
            final status = (entry.value as Map?)?['status'] as String? ?? '';
            if (status == 'submitted') submittedOnTime++;
            if (status == 'late') lateSubmissions++;
          }
        }
      }

      return StudentProgress(
        totalDays: totalDays,
        presentDays: presentDays,
        totalAssignments: totalAssignments,
        submittedOnTime: submittedOnTime,
        lateSubmissions: lateSubmissions,
      );
    } catch (_) {
      return StudentProgress.empty;
    }
  }
}

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(FirebaseFirestore.instance);
});
