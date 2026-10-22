enum TeacherAccessState {
  notLoggedIn,
  profileMissing,
  profileIncomplete,
  pendingApproval,
  approvedNoSchool,
  approvedNoClasses,
  approvedNoSubjects,
  approvedReady,
  studentAccount,
  invalidRole,
}

class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.approvalStatus = 'approved',
    this.schoolId = '',
    this.designation = '',
    this.teacherId = '',
    this.classSections = const <String>[],
    this.subjects = const <String>[],
    this.profileCompleted = false,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String approvalStatus;
  final String schoolId;
  final String designation;
  final String teacherId;
  final List<String> classSections;
  final List<String> subjects;
  final bool profileCompleted;
  final String? photoUrl;

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    final role = ((data['role'] as String?) ?? 'student').trim();
    final name = ((data['name'] as String?) ?? '').trim();
    final rawApprovalStatus =
        ((data['approvalStatus'] as String?) ??
                (role.toLowerCase() == 'teacher' ? 'pending' : 'approved'))
            .trim();
    final subjects = <String>[];
    final sections = <String>[];

    if (data['subjects'] is List) {
      for (final item in data['subjects'] as List) {
        if (item is String && item.trim().isNotEmpty) {
          subjects.add(item.trim());
        }
      }
    }
    if (data['classSections'] is List) {
      for (final item in data['classSections'] as List) {
        if (item is String && item.trim().isNotEmpty) {
          sections.add(item.trim());
        }
      }
    }

    return UserModel(
      id: id,
      name: name.isNotEmpty ? name : 'Unknown User',
      email: (data['email'] as String?) ?? '',
      role: role.isEmpty ? 'student' : role,
      approvalStatus: rawApprovalStatus.isEmpty ? 'pending' : rawApprovalStatus,
      schoolId: (data['schoolId'] as String?) ?? '',
      designation: (data['designation'] as String?) ?? '',
      teacherId: (data['teacherId'] as String?) ?? '',
      classSections: sections,
      subjects: subjects,
      profileCompleted: data['profileCompleted'] == true,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      approvalStatus: map['approvalStatus'] ?? 'approved',
      schoolId: map['schoolId'] ?? '',
      designation: map['designation'] ?? '',
      teacherId: map['teacherId'] ?? '',
      classSections: _parseStringList(map['classSections']),
      subjects: _parseStringList(map['subjects']),
      profileCompleted: map['profileCompleted'] == true,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'approvalStatus': approvalStatus,
      'schoolId': schoolId,
      'designation': designation,
      'teacherId': teacherId,
      'classSections': classSections,
      'subjects': subjects,
      'profileCompleted': profileCompleted,
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  bool get isStudent => role.toLowerCase() == 'student';
  bool get isTeacher => role.toLowerCase() == 'teacher';
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isApproved =>
      approvalStatus.toLowerCase() == 'approved' ||
      approvalStatus.toLowerCase() == 'active';
  bool get isPendingApproval => approvalStatus.toLowerCase() == 'pending';
  bool get isRejected => approvalStatus.toLowerCase() == 'rejected';
  bool get hasProtectedAccess => isApproved || !isTeacher;
  bool get hasSchoolAssignment => schoolId.trim().isNotEmpty;
  bool get hasAssignedClasses => classSections.isNotEmpty;
  bool get hasAssignedSubjects => subjects.isNotEmpty;

  TeacherAccessState get teacherAccessState {
    if (role.trim().isEmpty) {
      return TeacherAccessState.profileMissing;
    }

    if (isStudent) {
      return TeacherAccessState.studentAccount;
    }

    if (!isTeacher) {
      return TeacherAccessState.invalidRole;
    }

    if (!profileCompleted) {
      return TeacherAccessState.profileIncomplete;
    }

    if (isPendingApproval) {
      return TeacherAccessState.pendingApproval;
    }

    if (!isApproved) {
      return TeacherAccessState.invalidRole;
    }

    if (!hasSchoolAssignment) {
      return TeacherAccessState.approvedNoSchool;
    }

    if (!hasAssignedClasses) {
      return TeacherAccessState.approvedNoClasses;
    }

    if (!hasAssignedSubjects) {
      return TeacherAccessState.approvedNoSubjects;
    }

    return TeacherAccessState.approvedReady;
  }

  bool get canAccessTeacherFeatures =>
      teacherAccessState == TeacherAccessState.approvedReady;
}
