import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus { pending, submitted, late, graded }

class StudentAssignment {
  const StudentAssignment({
    required this.id,
    required this.title,
    required this.subject,
    required this.teacherName,
    required this.dueDate,
    required this.assignedDate,
    required this.type,
    this.status = AssignmentStatus.pending,
    this.description = '',
    this.classSection = '',
    this.schoolId = '',
    this.submittedAt,
    this.fileUrl,
  });

  final String id;
  final String title;
  final String subject;
  final String teacherName;
  final DateTime dueDate;
  final DateTime assignedDate;
  final String type; // 'Assignment', 'Homework', 'Online Quiz', etc.
  final AssignmentStatus status;
  final String description;
  final String classSection;
  final String schoolId;
  final DateTime? submittedAt;
  final String? fileUrl;

  bool get isOverdue =>
      status == AssignmentStatus.pending && dueDate.isBefore(DateTime.now());

  Duration get timeUntilDue => dueDate.difference(DateTime.now());

  String get dueDateLabel {
    final now = DateTime.now();
    final diff = dueDate.difference(now);
    if (diff.isNegative) return 'Overdue';
    if (diff.inHours < 1) return 'Due in ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Due in ${diff.inHours} hours';
    if (diff.inDays == 1) return 'Due tomorrow';
    return 'Due in ${diff.inDays} days';
  }

  factory StudentAssignment.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime parseDate(dynamic raw) {
      return switch (raw) {
        Timestamp t => t.toDate(),
        DateTime d => d,
        String s => DateTime.tryParse(s) ?? DateTime.now(),
        _ => DateTime.now(),
      };
    }

    AssignmentStatus parseStatus(String? s) {
      return switch (s?.toLowerCase()) {
        'submitted' => AssignmentStatus.submitted,
        'late' => AssignmentStatus.late,
        'graded' => AssignmentStatus.graded,
        _ => AssignmentStatus.pending,
      };
    }

    return StudentAssignment(
      id: id,
      title: (data['title'] as String? ?? '').trim(),
      subject: (data['subject'] as String? ?? '').trim(),
      teacherName: (data['teacherName'] as String? ?? '').trim(),
      dueDate: parseDate(data['dueDate']),
      assignedDate: parseDate(data['assignedDate'] ?? data['createdAt']),
      type: (data['type'] as String? ?? 'Assignment').trim(),
      status: parseStatus(data['status'] as String?),
      description: (data['description'] as String? ?? '').trim(),
      classSection: (data['classSection'] as String? ?? '').trim(),
      schoolId: (data['schoolId'] as String? ?? '').trim(),
      submittedAt:
          data['submittedAt'] != null ? parseDate(data['submittedAt']) : null,
      fileUrl: data['fileUrl'] as String?,
    );
  }
}
