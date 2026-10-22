import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../sources/firebase/firebase_auth_source.dart';

class AuthRepository {
  AuthRepository(this._source);

  final FirebaseAuthSource _source;

  Future<UserModel?> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw const FormatException('Email and password are required.');
    }

    try {
      return await _source.signIn(email, password);
    } catch (error) {
      if (error.toString().contains('Firebase is not configured')) {
        throw Exception(
          'Firebase is not configured yet. Complete the Firebase setup in lib/firebase_options.dart and platform config files.',
        );
      }
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final trimmedEmail = email.trim();
    if (!trimmedEmail.contains('@')) {
      throw const FormatException('Enter your email address first.');
    }
    await _source.sendPasswordResetEmail(trimmedEmail);
  }

  Future<UserModel?> registerTeacher({
    required String fullName,
    required String email,
    required String password,
    String? schoolInvitationCode,
  }) async {
    if (fullName.trim().isEmpty ||
        email.trim().isEmpty ||
        password.trim().isEmpty) {
      throw const FormatException('Please complete all registration fields.');
    }

    return _source.registerTeacher(
      fullName: fullName,
      email: email,
      password: password,
      schoolInvitationCode: schoolInvitationCode,
    );
  }

  Future<UserModel?> saveTeacherProfile({
    required String fullName,
    required String schoolId,
    required String designation,
    required String teacherId,
    List<String>? subjects,
    List<String>? classSections,
    String? photoUrl,
  }) async {
    return _source.saveTeacherProfile(
      fullName: fullName,
      schoolId: schoolId,
      designation: designation,
      teacherId: teacherId,
      subjects: subjects,
      classSections: classSections,
      photoUrl: photoUrl,
    );
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      return await _source.getCurrentUser();
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _source.signOut();
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuthSource());
});
