import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../models/user_model.dart';

class FirebaseAuthSource {
  FirebaseAuthSource({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth,
      _firestore = firestore;

  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get firebaseAuth => _firebaseAuth ?? FirebaseAuth.instance;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // LOGIN
  // ------------------------------------------------------------

  Future<UserModel?> signIn(String email, String password) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user?.uid;

      if (uid == null) {
        return null;
      }

      final doc = await firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw Exception(
          'No user profile was found for this account. '
          'Please contact the admin.',
        );
      }

      final user = UserModel.fromFirestore(uid, doc.data() ?? {});

      if (user.role.trim().isEmpty) {
        throw Exception(
          'Your account role is missing. '
          'Please contact the administrator.',
        );
      }

      if (!['student', 'teacher', 'admin'].contains(user.role.toLowerCase())) {
        throw Exception('This account role is not supported in this app.');
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw Exception(_firebaseErrorMessage(error.code, error.message));
    } catch (error) {
      if (error.toString().contains('No Firebase App') ||
          error.toString().contains('Firebase')) {
        throw Exception(
          'Firebase is not configured yet. '
          'Complete the Firebase setup and replace the '
          'placeholder config in lib/firebase_options.dart.',
        );
      }

      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw Exception(_firebaseErrorMessage(error.code, error.message));
    }
  }

  // ------------------------------------------------------------
  // TEACHER REGISTRATION
  // ------------------------------------------------------------

  Future<UserModel?> registerTeacher({
    required String fullName,
    required String email,
    required String password,
    String? schoolInvitationCode,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user?.uid;

      if (uid == null) {
        throw Exception(
          'Teacher registration failed before a user record '
          'was created.',
        );
      }

      final payload = {
        'id': uid,
        'name': fullName.trim(),
        'email': email.trim(),
        'role': 'teacher',
        'approvalStatus': 'pending',
        'profileCompleted': false,
        'schoolInvitationCode': schoolInvitationCode?.trim() ?? '',
        'schoolId': '',
        'designation': '',
        'teacherId': '',
        'subjects': <String>[],
        'classSections': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // IMPORTANT:
      // Registration creates the user document for the first time.
      await firestore.collection('users').doc(uid).set(payload);

      final user = await getCurrentUser();

      if (user == null) {
        throw Exception(
          'The new teacher account was created, '
          'but the profile could not be loaded.',
        );
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw Exception(_firebaseErrorMessage(error.code, error.message));
    } catch (error) {
      if (error.toString().contains('Firebase')) {
        throw Exception(
          'Firebase is not configured yet. '
          'Complete the Firebase setup and replace the '
          'placeholder config in lib/firebase_options.dart.',
        );
      }

      if (error is Exception) {
        rethrow;
      }

      throw Exception('Teacher registration failed. Please try again.');
    }
  }

  // ------------------------------------------------------------
  // SAVE TEACHER PROFILE
  // ------------------------------------------------------------

  Future<UserModel?> saveTeacherProfile({
    required String fullName,
    required String schoolId,
    required String designation,
    required String teacherId,
    List<String>? subjects,
    List<String>? classSections,
    String? photoUrl,
  }) async {
    final firebaseUser = firebaseAuth.currentUser;

    if (firebaseUser == null) {
      throw Exception('You are not signed in. Please log in again.');
    }

    final trimmedName = fullName.trim();
    final trimmedSchoolId = schoolId.trim();
    final trimmedDesignation = designation.trim();
    final trimmedTeacherId = teacherId.trim();

    if (trimmedName.isEmpty ||
        trimmedSchoolId.isEmpty ||
        trimmedDesignation.isEmpty ||
        trimmedTeacherId.isEmpty) {
      throw const FormatException(
        'Please fill in all required profile details '
        'before saving.',
      );
    }

    final cleanedSubjects = (subjects ?? const <String>[])
        .map((subject) => subject.trim())
        .where((subject) => subject.isNotEmpty)
        .toList();

    final cleanedSections = (classSections ?? const <String>[])
        .map((section) => section.trim())
        .where((section) => section.isNotEmpty)
        .toList();

    final userDoc = firestore.collection('users').doc(firebaseUser.uid);
    final existingDoc = await userDoc.get();

    final userData = {
      'name': trimmedName,
      'email': firebaseUser.email ?? '',
      'role': existingDoc.exists
          ? ((existingDoc.data()?['role'] as String?) ?? 'teacher')
          : 'teacher',
      'schoolId': trimmedSchoolId,
      'designation': trimmedDesignation,
      'teacherId': trimmedTeacherId,
      'subjects': cleanedSubjects,
      'classSections': cleanedSections,
      if (photoUrl != null && photoUrl.trim().isNotEmpty)
        'photoUrl': photoUrl.trim(),
      'profileCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!existingDoc.exists) {
      await userDoc.set({
        ...userData,
        'approvalStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await userDoc.set(userData, SetOptions(merge: true));
    }

    return getCurrentUser();
  }

  // ------------------------------------------------------------
  // GET CURRENT USER
  // ------------------------------------------------------------

  Future<UserModel?> getCurrentUser() async {
    try {
      final firebaseUser = firebaseAuth.currentUser;

      if (firebaseUser == null) {
        return null;
      }

      final doc = await firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      final user = UserModel.fromFirestore(firebaseUser.uid, doc.data() ?? {});

      if (user.role.trim().isEmpty) {
        return null;
      }

      return user;
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------

  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (_) {
      // Firebase may not be initialized in local demo mode.
    }
  }

  // ------------------------------------------------------------
  // FIREBASE AUTH ERROR MESSAGES
  // ------------------------------------------------------------

  String _firebaseErrorMessage(String code, String? message) {
    switch (code) {
      case 'invalid-email':
        return 'The email address is invalid.';

      case 'email-already-in-use':
        return 'An account with this email already exists.';

      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';

      case 'user-not-found':
        return 'No account was found with that email.';

      case 'wrong-password':
        return 'The password is incorrect.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';

      case 'invalid-credential':
        return 'The provided credentials are invalid.';

      default:
        return message ?? 'An unexpected sign-in error occurred.';
    }
  }
}
