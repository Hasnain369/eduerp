class StudentProgress {
  const StudentProgress({
    required this.totalDays,
    required this.presentDays,
    required this.totalAssignments,
    required this.submittedOnTime,
    required this.lateSubmissions,
  });

  final int totalDays;
  final int presentDays;
  final int totalAssignments;
  final int submittedOnTime;
  final int lateSubmissions;

  double get attendancePercent =>
      totalDays > 0 ? (presentDays / totalDays) * 100 : 0;

  double get onTimePercent =>
      totalAssignments > 0 ? (submittedOnTime / totalAssignments) * 100 : 0;

  String get attendanceLabel {
    final pct = attendancePercent;
    if (pct >= 90) return 'Excellent';
    if (pct >= 75) return 'Good';
    if (pct >= 60) return 'Average';
    return 'Poor';
  }

  String get gradeLabel {
    final pct = attendancePercent;
    if (pct >= 90) return 'A';
    if (pct >= 80) return 'B+';
    if (pct >= 70) return 'B';
    if (pct >= 60) return 'C';
    return 'D';
  }

  static const StudentProgress empty = StudentProgress(
    totalDays: 0,
    presentDays: 0,
    totalAssignments: 0,
    submittedOnTime: 0,
    lateSubmissions: 0,
  );
}
