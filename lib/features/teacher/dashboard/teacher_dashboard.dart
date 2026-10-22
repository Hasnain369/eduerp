import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/locale_provider.dart';
import '../../../data/repositories/teacher_planner_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import 'teacher_dashboard_provider.dart';
import '../teacher_portal_routes.dart';
import '../teacher_section_screen.dart';

const _blue = Color(0xFF3448B0);
const _ink = Color(0xFF20212B);
const _muted = Color(0xFF747688);

class TeacherDashboard extends ConsumerStatefulWidget {
  const TeacherDashboard({super.key});

  @override
  ConsumerState<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends ConsumerState<TeacherDashboard> {
  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final user =
        ref.watch(authStateNotifierProvider).user ??
        UserModel(
          id: '',
          name: 'Mr. Tariq',
          email: '',
          role: 'teacher',
          approvalStatus: 'pending',
        );
    final isUrdu = ref.watch(appLocaleProvider).languageCode == 'ur';
    final schedule = user.id.isEmpty
        ? null
        : ref.watch(teacherDashboardSummaryProvider(user.id));

    return TeacherPortalScaffold(
      activeRoute: TeacherPortalRoutes.home,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 350;
          final horizontalPadding = constraints.maxWidth > 620 ? 22.0 : 14.0;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              18,
            ),
            children: [
              _SyncBanner(
                isUrdu: isUrdu,
                onSync: () => _message(
                  context,
                  isUrdu ? 'ہم آہنگی مکمل ہوگئی' : 'Sync complete',
                ),
              ),
              const SizedBox(height: 10),
              _TeacherCard(user: user, isUrdu: isUrdu),
              const SizedBox(height: 18),
              _QuickActions(isNarrow: isNarrow, isUrdu: isUrdu),
              const SizedBox(height: 18),
              _ScheduleHeading(
                isUrdu: isUrdu,
                totalCount: schedule?.valueOrNull?.todaysLectures.length ?? 0,
                remainingCount:
                    schedule?.valueOrNull?.todaysLectures
                        .where(
                          (lecture) =>
                              lecture.status != PlannerLectureStatus.done,
                        )
                        .length ??
                    0,
              ),
              const SizedBox(height: 9),
              if (schedule == null)
                const _ScheduleEmpty(message: 'Sign in to view your schedule.')
              else
                schedule.when(
                  data: (summary) => summary.todaysLectures.isEmpty
                      ? _ScheduleEmpty(
                          message: isUrdu
                              ? 'آج کے لیے کوئی سبق منصوبہ بند نہیں ہے۔'
                              : 'No lectures planned for today.',
                          onPlan: () => Navigator.of(
                            context,
                          ).pushNamed(TeacherPortalRoutes.planLecture),
                        )
                      : Column(
                          key: const ValueKey('today-schedule'),
                          children: [
                            for (
                              var index = 0;
                              index < summary.todaysLectures.length;
                              index++
                            )
                              _AnimatedPeriod(
                                period: _Period.fromLecture(
                                  summary.todaysLectures[index],
                                  index,
                                  live:
                                      summary.todaysLectures[index].status !=
                                          PlannerLectureStatus.done &&
                                      summary.todaysLectures
                                          .take(index)
                                          .every(
                                            (lecture) =>
                                                lecture.status ==
                                                PlannerLectureStatus.done,
                                          ),
                                  next:
                                      summary.todaysLectures[index].status !=
                                          PlannerLectureStatus.done &&
                                      summary.todaysLectures
                                              .take(index)
                                              .where(
                                                (lecture) =>
                                                    lecture.status !=
                                                    PlannerLectureStatus.done,
                                              )
                                              .length ==
                                          1,
                                ),
                                index: index,
                                isUrdu: isUrdu,
                                isDone:
                                    summary.todaysLectures[index].status ==
                                    PlannerLectureStatus.done,
                                isLast:
                                    index == summary.todaysLectures.length - 1,
                                onMarkDone: () async {
                                  final lecture = summary.todaysLectures[index];
                                  try {
                                    await ref
                                        .read(teacherPlannerRepositoryProvider)
                                        .setLectureStatus(
                                          teacherId: user.id,
                                          lectureId: lecture.id,
                                          status: PlannerLectureStatus.done,
                                        );
                                    ref.invalidate(
                                      teacherDashboardSummaryProvider(user.id),
                                    );
                                    if (context.mounted) {
                                      _message(
                                        context,
                                        isUrdu
                                            ? 'سبق مکمل ہوگیا'
                                            : 'Lesson marked done',
                                      );
                                    }
                                  } catch (error) {
                                    if (context.mounted) {
                                      _message(
                                        context,
                                        error.toString().replaceFirst(
                                          'Exception: ',
                                          '',
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                          ],
                        ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, _) => _ScheduleEmpty(
                    message:
                        'Could not load today’s schedule: ${error.toString().replaceFirst('Exception: ', '')}',
                    onRetry: () => ref.invalidate(
                      teacherDashboardSummaryProvider(user.id),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

void _message(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.isUrdu, required this.onSync});

  final bool isUrdu;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0D9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 15,
            color: Color(0xFF815015),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              isUrdu
                  ? 'آف لائن • آخری ہم آہنگی 25 منٹ پہلے'
                  : 'Working Offline • Last synced 25m ago',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF704718), fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: onSync,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              backgroundColor: Colors.white,
              foregroundColor: _blue,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(isUrdu ? 'ہم آہنگ کریں' : 'Tap to Sync'),
          ),
        ],
      ),
    );
  }
}

class _TeacherCard extends StatelessWidget {
  const _TeacherCard({required this.user, required this.isUrdu});

  final UserModel user;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    final name = user.name.trim().isEmpty ? 'Mr. Tariq' : user.name;
    final designation = user.designation.trim().isEmpty
        ? (isUrdu ? 'سینئر ریاضی کے استاد' : 'Senior Mathematics Teacher')
        : user.designation;
    final school = user.schoolId.trim().isEmpty
        ? 'Govt Model HSS Lahore'
        : user.schoolId;
    final id = user.teacherId.trim().isEmpty ? 'T-84920' : user.teacherId;
    final classes = user.classSections.isEmpty ? 4 : user.classSections.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 13, 13, 12),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFE8E9F5),
                    backgroundImage: user.photoUrl?.isNotEmpty == true
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl?.isNotEmpty == true
                        ? null
                        : const Icon(Icons.person, color: _blue, size: 27),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8A35),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting(isUrdu)}, $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'صبح بخیر، $name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      '$designation • $school',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: Color(0xFFECECF2)),
          ),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              _InfoChip(
                icon: Icons.badge_outlined,
                label: 'ID: $id',
                color: const Color(0xFFF0F0F5),
              ),
              const _InfoChip(
                label: 'Grade 17 (BPS)',
                color: Color(0xFFE4E5FF),
              ),
              _InfoChip(
                icon: Icons.access_time,
                label: isUrdu ? '$classes کلاسیں آج' : '$classes Classes Today',
                color: const Color(0xFFFFE0BE),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _greeting(bool isUrdu) {
  if (isUrdu) return 'خوش آمدید';
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: _ink),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isNarrow, required this.isUrdu});

  final bool isNarrow;
  final bool isUrdu;

  static const _items = [
    _Action(
      'Attendance',
      'حاضری',
      Icons.fact_check_outlined,
      Color(0xFFE1E4FF),
      Color(0xFF171FA0),
      TeacherPortalRoutes.attendance,
    ),
    _Action(
      'Plan Lecture',
      'لیکچر پلان',
      Icons.menu_book_outlined,
      Color(0xFFFFDDB2),
      Color(0xFF8D4C0B),
      TeacherPortalRoutes.planLecture,
    ),
    _Action(
      'Create Quiz',
      'کوئز بنائیں',
      Icons.quiz_outlined,
      Color(0xFFDDE8FF),
      Color(0xFF3348A6),
      TeacherPortalRoutes.createQuiz,
    ),
    _Action(
      'Assignments',
      'اسائنمنٹس',
      Icons.assignment_outlined,
      Color(0xFFECEBF2),
      Color(0xFF38384A),
      TeacherPortalRoutes.assignments,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final columns = isNarrow ? 2 : 4;
    final width = MediaQuery.sizeOf(context).width;
    return GridView.builder(
      itemCount: _items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 9,
        mainAxisSpacing: 9,
        childAspectRatio: columns == 2
            ? 1.4
            : width < 540
            ? 0.65
            : 1.05,
      ),
      itemBuilder: (context, index) {
        final item = _items[index];
        return _ActionCard(
          action: item,
          label: isUrdu ? item.urduLabel : item.label,
        );
      },
    );
  }
}

class _Action {
  const _Action(
    this.label,
    this.urduLabel,
    this.icon,
    this.background,
    this.foreground,
    this.route,
  );

  final String label;
  final String urduLabel;
  final IconData icon;
  final Color background;
  final Color foreground;
  final String route;
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({required this.action, required this.label});

  final _Action action;
  final String label;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: const Color(0x140D1450),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.of(context).pushNamed(widget.action.route),
          onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.action.background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.action.icon,
                    color: widget.action.foreground,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleHeading extends StatelessWidget {
  const _ScheduleHeading({
    required this.isUrdu,
    required this.totalCount,
    required this.remainingCount,
  });

  final bool isUrdu;
  final int totalCount;
  final int remainingCount;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date =
        '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isUrdu ? 'آج کا شیڈول' : "Today's Schedule",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  const Flexible(
                    child: Text(
                      'آج کا شیڈول',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: _blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isUrdu
                    ? '$date • $remainingCount باقی'
                    : '$date • $remainingCount of $totalCount lectures remaining',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: isUrdu ? 'ٹائم ٹیبل' : 'Timetable',
          visualDensity: VisualDensity.compact,
          onPressed: () =>
              Navigator.of(context).pushNamed(TeacherPortalRoutes.timetable),
          icon: const Icon(
            Icons.calendar_month_outlined,
            color: Color(0xFF55596D),
            size: 19,
          ),
        ),
      ],
    );
  }
}

class _ScheduleEmpty extends StatelessWidget {
  const _ScheduleEmpty({required this.message, this.onPlan, this.onRetry});

  final String message;
  final VoidCallback? onPlan;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),
          if (onPlan != null) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onPlan,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Plan a lecture'),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class _Period {
  const _Period({
    required this.id,
    required this.time,
    required this.name,
    required this.className,
    required this.subject,
    required this.topic,
    required this.room,
    this.live = false,
    this.next = false,
  });

  final String id;
  final String time;
  final String name;
  final String className;
  final String subject;
  final String topic;
  final String room;
  final bool live;
  final bool next;

  factory _Period.fromLecture(
    PlannerLecture lecture,
    int index, {
    required bool live,
    required bool next,
  }) => _Period(
    id: lecture.id,
    time:
        '${_formatLectureTime(lecture.startMinutes)} - ${_formatLectureTime(lecture.endMinutes)}',
    name: 'Period ${index + 1}',
    className: lecture.classSection,
    subject: lecture.subject,
    topic: '${lecture.chapter}: ${lecture.topic}',
    room: '',
    live: live,
    next: next,
  );
}

String _formatLectureTime(int minutes) {
  final hour = minutes ~/ 60;
  final minute = (minutes % 60).toString().padLeft(2, '0');
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$displayHour:$minute ${hour >= 12 ? 'PM' : 'AM'}';
}

class _AnimatedPeriod extends StatelessWidget {
  const _AnimatedPeriod({
    required this.period,
    required this.index,
    required this.isUrdu,
    required this.isDone,
    required this.isLast,
    required this.onMarkDone,
  });

  final _Period period;
  final int index;
  final bool isUrdu;
  final bool isDone;
  final bool isLast;
  final VoidCallback onMarkDone;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${period.id}-${isDone ? 'done' : 'planned'}'),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - value)),
          child: child,
        ),
      ),
      child: _PeriodCard(
        period: period,
        isUrdu: isUrdu,
        isDone: isDone,
        onMarkDone: onMarkDone,
        isLast: isLast,
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.period,
    required this.isUrdu,
    required this.isDone,
    required this.onMarkDone,
    required this.isLast,
  });

  final _Period period;
  final bool isUrdu;
  final bool isDone;
  final VoidCallback onMarkDone;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: period.live ? 15 : 11,
                  height: period.live ? 15 : 11,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: period.live ? _blue : const Color(0xFFC7C7D5),
                    shape: BoxShape.circle,
                    border: period.live
                        ? Border.all(color: const Color(0xFFCBCFFF), width: 3)
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFE1E1EA)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x080D1450),
                    blurRadius: 9,
                    offset: Offset(0, 3),
                  ),
                ],
                border: Border.all(
                  color: period.live
                      ? const Color(0xFF3448B0)
                      : isDone
                      ? const Color(0xFFB9E8D3)
                      : const Color(0xFFECECF3),
                  width: period.live ? 1.5 : 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 350),
                      width: period.live ? 4 : 0,
                      color: _blue,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(13, 11, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: period.live
                                      ? _LiveBadge(
                                          label:
                                              '${isUrdu ? 'ابھی جاری' : 'Live Now'} (${period.time})',
                                        )
                                      : Text(
                                          period.time,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: _ink,
                                            fontSize: 11,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 6),
                                if (period.next)
                                  _NextBadge(isUrdu: isUrdu)
                                else if (isDone)
                                  const _DoneBadge()
                                else
                                  Text(
                                    period.name,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${period.className} • ${period.subject}',
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${isUrdu ? 'موضوع' : 'Topic'}: ${period.topic}',
                              style: const TextStyle(
                                color: Color(0xFF535565),
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 10,
                              runSpacing: 3,
                              children: [
                                if (period.room.isNotEmpty)
                                  _ScheduleMeta(
                                    Icons.location_on_outlined,
                                    period.room,
                                  ),
                              ],
                            ),
                            if (!isDone) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton.icon(
                                  onPressed: isDone ? null : onMarkDone,
                                  icon: Icon(
                                    isDone
                                        ? Icons.check_circle_rounded
                                        : Icons.check_circle_outline,
                                    size: 17,
                                  ),
                                  label: Text(
                                    period.live
                                        ? (isUrdu
                                              ? 'حاضری لگائیں'
                                              : 'Mark Attendance')
                                        : (isUrdu
                                              ? 'مکمل کریں'
                                              : 'Mark Done'),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _blue,
                                    foregroundColor: Colors.white,
                                    elevation: 2,
                                    shape: const StadiumBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextBadge extends StatelessWidget {
  const _NextBadge({required this.isUrdu});

  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0BE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isUrdu ? 'اگلا' : 'Next',
        style: const TextStyle(color: Color(0xFF704718), fontSize: 11),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F5E9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF237833),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _DoneBadge extends StatelessWidget {
  const _DoneBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE8F7EF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'Done',
      style: TextStyle(
        color: Color(0xFF16875F),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ScheduleMeta extends StatelessWidget {
  const _ScheduleMeta(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF676A7B)),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(color: _muted, fontSize: 11)),
      ],
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFFECECF3)),
    boxShadow: const [
      BoxShadow(color: Color(0x080D1450), blurRadius: 10, offset: Offset(0, 3)),
    ],
  );
}
