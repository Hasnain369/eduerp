import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthState {
  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.errorMessage,
  });

  final UserModel? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
    );
  }

  factory AuthState.initial() => const AuthState();
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier(this._authRepository) : super(AuthState.initial());

  final AuthRepository _authRepository;

  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.getCurrentUser();
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: user != null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<UserModel?> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.login(email, password);
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: user != null,
      );
      return user;
    } on Exception catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: message,
      );
      return null;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _authRepository.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false, errorMessage: null);
      return true;
    } on Exception catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<UserModel?> registerTeacher({
    required String fullName,
    required String email,
    required String password,
    String? schoolInvitationCode,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.registerTeacher(
        fullName: fullName,
        email: email,
        password: password,
        schoolInvitationCode: schoolInvitationCode,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: user != null,
      );
      return user;
    } on Exception catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        errorMessage: message,
      );
      return null;
    }
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
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final user = await _authRepository.saveTeacherProfile(
        fullName: fullName,
        schoolId: schoolId,
        designation: designation,
        teacherId: teacherId,
        subjects: subjects,
        classSections: classSections,
        photoUrl: photoUrl,
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        isAuthenticated: user != null,
      );
      return user;
    } on Exception catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: message);
      return null;
    }
  }

  Future<void> refreshCurrentUser() async {
    final user = await _authRepository.getCurrentUser();
    if (user == null) {
      state = AuthState.initial();
      return;
    }
    state = state.copyWith(user: user, isAuthenticated: true);
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await _authRepository.logout();
    state = AuthState.initial();
  }

  void setAuthenticatedUser(UserModel user) {
    state = state.copyWith(
      user: user,
      isAuthenticated: true,
      isLoading: false,
      errorMessage: null,
    );
  }
}

final authStateNotifierProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>(
      (ref) => AuthStateNotifier(ref.read(authRepositoryProvider)),
    );
