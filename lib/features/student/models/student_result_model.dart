import 'package:cloud_firestore/cloud_firestore.dart';

class StudentResult {
  const StudentResult({
    required this.id,
    required this.subject,
    required this.title,
    required this.teacherName,
    required this.marksObtained,
    required this.totalMarks,
    required this.type, // 'Unit Test', 'Class Mid-Term', 'Monthly Review' etc.
    required this.gradedAt,
    this.classSection = '',
    this.schoolId = '',
  });

  final String id;
  final String subject;
  final String title;
  final String teacherName;
  final double marksObtained;
  final double totalMarks;
  final String type;
  final DateTime gradedAt;
  final String classSection;
  final String schoolId;

  double get percentage =>
      totalMarks > 0 ? (marksObtained / totalMarks) * 100 : 0;

  String get grade {
    final pct = percentage;
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    if (pct >= 40) return 'D';
    return 'F';
  }

  factory StudentResult.fromFirestore(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic raw) {
      return switch (raw) {
        Timestamp t => t.toDate(),
        DateTime d => d,
        String s => DateTime.tryParse(s) ?? DateTime.now(),
        _ => DateTime.now(),
      };
    }

    return StudentResult(
      id: id,
      subject: (data['subject'] as String? ?? '').trim(),
      title: (data['title'] as String? ?? '').trim(),
      teacherName: (data['teacherName'] as String? ?? '').trim(),
      marksObtained: ((data['marksObtained'] as num?) ?? 0).toDouble(),
      totalMarks: ((data['totalMarks'] as num?) ?? 25).toDouble(),
      type: (data['type'] as String? ?? 'Assessment').trim(),
      gradedAt: parseDate(data['gradedAt'] ?? data['createdAt']),
      classSection: (data['classSection'] as String? ?? '').trim(),
      schoolId: (data['schoolId'] as String? ?? '').trim(),
    );
  }
}
