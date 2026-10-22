import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';

class AdminRepository {
  AdminRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<List<UserModel>> getTeachersForApproval() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'teacher')
        .get();

    final teachers = snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
        .toList();

    teachers.sort((a, b) {
      final approvalRank = a.isApproved ? 1 : 0;
      final approvalRankB = b.isApproved ? 1 : 0;
      final compareApproval = approvalRankB.compareTo(approvalRank);
      if (compareApproval != 0) {
        return compareApproval;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return teachers;
  }

  Future<void> approveTeacher({
    required String uid,
    required String schoolId,
    List<String>? subjects,
    List<String>? classSections,
  }) async {
    final trimmedSchoolId = schoolId.trim();
    if (trimmedSchoolId.isEmpty) {
      throw const FormatException(
        'A school assignment is required before approving a teacher.',
      );
    }

    final cleanedSubjects = (subjects ?? const <String>[])
        .map((subject) => subject.trim())
        .where((subject) => subject.isNotEmpty)
        .toList();

    final cleanedClasses = (classSections ?? const <String>[])
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();

    await _firestore.collection('users').doc(uid).update({
      'approvalStatus': 'approved',
      'profileCompleted': true,
      'schoolId': trimmedSchoolId,
      'subjects': cleanedSubjects,
      'classSections': cleanedClasses,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectTeacher({
    required String uid,
    String reason = 'Teacher application rejected by admin.',
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'approvalStatus': 'rejected',
      'schoolId': '',
      'subjects': <String>[],
      'classSections': <String>[],
      'profileCompleted': false,
      'rejectionReason': reason.trim().isEmpty
          ? 'Teacher application rejected by admin.'
          : reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(FirebaseFirestore.instance);
});
