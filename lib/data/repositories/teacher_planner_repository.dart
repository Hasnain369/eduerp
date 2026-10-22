import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PlannerPeriodStatus { done, skipped, off }

enum PlannerLectureStatus { planned, inProgress, done }

class PlannerLecture {
  const PlannerLecture({
    required this.id,
    required this.dateKey,
    required this.classSection,
    required this.startMinutes,
    required this.endMinutes,
    required this.subject,
    required this.chapter,
    required this.topic,
    required this.objectives,
    this.status = PlannerLectureStatus.planned,
  });

  final String id;
  final String dateKey;
  final String classSection;
  final int startMinutes;
  final int endMinutes;
  final String subject;
  final String chapter;
  final String topic;
  final List<String> objectives;
  final PlannerLectureStatus status;

  factory PlannerLecture.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final status = PlannerLectureStatus.values
        .where((value) => value.name == data['status'])
        .firstOrNull;
    final rawObjectives = data['objectives'];
    return PlannerLecture(
      id: id,
      dateKey: data['dateKey'] as String? ?? '',
      classSection: (data['classSection'] as String? ?? '').trim(),
      startMinutes: data['startMinutes'] as int? ?? 480,
      endMinutes: data['endMinutes'] as int? ?? 525,
      subject: (data['subject'] as String? ?? '').trim(),
      chapter: (data['chapter'] as String? ?? '').trim(),
      topic: (data['topic'] as String? ?? '').trim(),
      objectives: rawObjectives is List
          ? rawObjectives.whereType<String>().toList()
          : const [],
      status: status ?? PlannerLectureStatus.planned,
    );
  }

  Map<String, dynamic> toMap() => {
    'dateKey': dateKey,
    'classSection': classSection,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
    'subject': subject,
    'chapter': chapter,
    'topic': topic,
    'objectives': objectives,
    'status': status.name,
  };
}

class PlannerPeriod {
  const PlannerPeriod({
    required this.id,
    required this.dayOfWeek,
    required this.subject,
    required this.classSection,
    required this.startMinutes,
    required this.endMinutes,
  });

  final String id;
  final int dayOfWeek;
  final String subject;
  final String classSection;
  final int startMinutes;
  final int endMinutes;

  factory PlannerPeriod.fromFirestore(String id, Map<String, dynamic> data) {
    return PlannerPeriod(
      id: id,
      dayOfWeek: data['dayOfWeek'] as int? ?? DateTime.monday,
      subject: (data['subject'] as String? ?? '').trim(),
      classSection: (data['classSection'] as String? ?? '').trim(),
      startMinutes: data['startMinutes'] as int? ?? 480,
      endMinutes: data['endMinutes'] as int? ?? 525,
    );
  }

  Map<String, dynamic> toMap() => {
    'dayOfWeek': dayOfWeek,
    'subject': subject,
    'classSection': classSection,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
  };
}

class PlannerDay {
  const PlannerDay({
    required this.dateKey,
    required this.periodStatuses,
    required this.tasks,
  });

  final String dateKey;
  final Map<String, PlannerPeriodStatus> periodStatuses;
  final List<String> tasks;

  factory PlannerDay.fromFirestore(String dateKey, Map<String, dynamic> data) {
    final statuses = <String, PlannerPeriodStatus>{};
    final rawStatuses = data['periodStatuses'];
    if (rawStatuses is Map) {
      for (final entry in rawStatuses.entries) {
        final status = PlannerPeriodStatus.values
            .where((value) => value.name == entry.value)
            .firstOrNull;
        if (status != null && entry.key is String) {
          statuses[entry.key as String] = status;
        }
      }
    }
    final rawTasks = data['tasks'];
    return PlannerDay(
      dateKey: dateKey,
      periodStatuses: statuses,
      tasks: rawTasks is List
          ? rawTasks.whereType<String>().toList()
          : const <String>[],
    );
  }
}

abstract interface class TeacherPlannerRepository {
  Future<List<PlannerLecture>> getLectures(String teacherId, String dateKey);

  Future<List<PlannerLecture>> getLecturesBetween(
    String teacherId,
    String startDateKey,
    String endDateKey,
  );

  Future<String> saveLecture(String teacherId, PlannerLecture lecture);

  Future<void> deleteLecture(String teacherId, String lectureId);

  Future<void> setLectureStatus({
    required String teacherId,
    required String lectureId,
    required PlannerLectureStatus status,
  });

  Future<List<PlannerPeriod>> getPeriods(String teacherId);

  Future<void> savePeriod(String teacherId, PlannerPeriod period);

  Future<void> deletePeriod(String teacherId, String periodId);

  Future<PlannerDay> getDay(String teacherId, String dateKey);

  Future<List<PlannerDay>> getDaysBetween(
    String teacherId,
    String startDateKey,
    String endDateKey,
  );

  Future<void> setPeriodStatus({
    required String teacherId,
    required String dateKey,
    required String periodId,
    required PlannerPeriodStatus status,
  });

  Future<void> addTask({
    required String teacherId,
    required String dateKey,
    required String task,
  });
}

class FirestoreTeacherPlannerRepository implements TeacherPlannerRepository {
  FirestoreTeacherPlannerRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _periods(String teacherId) =>
      _firestore
          .collection('users')
          .doc(teacherId)
          .collection('plannerPeriods');

  CollectionReference<Map<String, dynamic>> _days(String teacherId) =>
      _firestore.collection('users').doc(teacherId).collection('plannerDays');

  CollectionReference<Map<String, dynamic>> _lectures(String teacherId) =>
      _firestore
          .collection('users')
          .doc(teacherId)
          .collection('plannerLectures');

  @override
  Future<List<PlannerLecture>> getLectures(
    String teacherId,
    String dateKey,
  ) async {
    final snapshot = await _lectures(
      teacherId,
    ).where('dateKey', isEqualTo: dateKey).get();
    final lectures = snapshot.docs
        .map((doc) => PlannerLecture.fromFirestore(doc.id, doc.data()))
        .toList();
    _sortLectures(lectures);
    return lectures;
  }

  @override
  Future<List<PlannerLecture>> getLecturesBetween(
    String teacherId,
    String startDateKey,
    String endDateKey,
  ) async {
    final snapshot = await _lectures(teacherId)
        .where('dateKey', isGreaterThanOrEqualTo: startDateKey)
        .where('dateKey', isLessThanOrEqualTo: endDateKey)
        .get();
    final lectures = snapshot.docs
        .map((doc) => PlannerLecture.fromFirestore(doc.id, doc.data()))
        .toList();
    _sortLectures(lectures);
    return lectures;
  }

  @override
  Future<String> saveLecture(String teacherId, PlannerLecture lecture) async {
    final normalized = PlannerLecture(
      id: lecture.id,
      dateKey: lecture.dateKey,
      classSection: lecture.classSection.trim(),
      startMinutes: lecture.startMinutes,
      endMinutes: lecture.endMinutes,
      subject: lecture.subject.trim(),
      chapter: lecture.chapter.trim(),
      topic: lecture.topic.trim(),
      objectives: lecture.objectives
          .map((objective) => objective.trim())
          .where((objective) => objective.isNotEmpty)
          .toList(),
      status: lecture.status,
    );
    if (normalized.classSection.isEmpty ||
        normalized.subject.isEmpty ||
        normalized.chapter.isEmpty ||
        normalized.topic.isEmpty) {
      throw const FormatException(
        'Class, subject, chapter, and topic are required.',
      );
    }
    if (normalized.startMinutes < 0 ||
        normalized.endMinutes > 24 * 60 ||
        normalized.startMinutes >= normalized.endMinutes) {
      throw const FormatException('End time must be after start time.');
    }
    final collection = _lectures(teacherId);
    final document = normalized.id.isEmpty
        ? collection.doc()
        : collection.doc(normalized.id);
    await document.set({
      ...normalized.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (normalized.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return document.id;
  }

  @override
  Future<void> deleteLecture(String teacherId, String lectureId) async {
    await _lectures(teacherId).doc(lectureId).delete();
  }

  @override
  Future<void> setLectureStatus({
    required String teacherId,
    required String lectureId,
    required PlannerLectureStatus status,
  }) async {
    await _lectures(teacherId).doc(lectureId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _sortLectures(List<PlannerLecture> lectures) {
    lectures.sort((first, second) {
      final dateComparison = first.dateKey.compareTo(second.dateKey);
      return dateComparison != 0
          ? dateComparison
          : first.startMinutes.compareTo(second.startMinutes);
    });
  }

  @override
  Future<List<PlannerPeriod>> getPeriods(String teacherId) async {
    final snapshot = await _periods(teacherId).get();
    final periods = snapshot.docs
        .map((doc) => PlannerPeriod.fromFirestore(doc.id, doc.data()))
        .toList();
    periods.sort((first, second) {
      final dayComparison = first.dayOfWeek.compareTo(second.dayOfWeek);
      return dayComparison != 0
          ? dayComparison
          : first.startMinutes.compareTo(second.startMinutes);
    });
    return periods;
  }

  @override
  Future<void> savePeriod(String teacherId, PlannerPeriod period) async {
    final collection = _periods(teacherId);
    final document = period.id.isEmpty
        ? collection.doc()
        : collection.doc(period.id);
    await document.set({
      ...period.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (period.id.isEmpty) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deletePeriod(String teacherId, String periodId) async {
    await _periods(teacherId).doc(periodId).delete();
  }

  @override
  Future<PlannerDay> getDay(String teacherId, String dateKey) async {
    final snapshot = await _days(teacherId).doc(dateKey).get();
    return PlannerDay.fromFirestore(dateKey, snapshot.data() ?? const {});
  }

  @override
  Future<List<PlannerDay>> getDaysBetween(
    String teacherId,
    String startDateKey,
    String endDateKey,
  ) async {
    final snapshot = await _days(teacherId)
        .where('dateKey', isGreaterThanOrEqualTo: startDateKey)
        .where('dateKey', isLessThanOrEqualTo: endDateKey)
        .get();
    final days = snapshot.docs
        .map((doc) => PlannerDay.fromFirestore(doc.id, doc.data()))
        .toList();
    days.sort((first, second) => first.dateKey.compareTo(second.dateKey));
    return days;
  }

  @override
  Future<void> setPeriodStatus({
    required String teacherId,
    required String dateKey,
    required String periodId,
    required PlannerPeriodStatus status,
  }) async {
    await _days(teacherId).doc(dateKey).set({
      'dateKey': dateKey,
      'periodStatuses': {periodId: status.name},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> addTask({
    required String teacherId,
    required String dateKey,
    required String task,
  }) async {
    final trimmedTask = task.trim();
    if (trimmedTask.isEmpty) {
      throw const FormatException('Plan details are required.');
    }
    await _days(teacherId).doc(dateKey).set({
      'dateKey': dateKey,
      'tasks': FieldValue.arrayUnion([trimmedTask]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

final teacherPlannerRepositoryProvider = Provider<TeacherPlannerRepository>((
  ref,
) {
  return FirestoreTeacherPlannerRepository(FirebaseFirestore.instance);
});

String plannerDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

final lecturePlannerSelectedDateProvider = StateProvider<DateTime?>(
  (ref) => null,
);
