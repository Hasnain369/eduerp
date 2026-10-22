import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project/core/routes/app_router.dart';
import 'package:project/features/teacher/dashboard/teacher_dashboard.dart';

void main() {
  testWidgets('new teacher dashboard is responsive and excludes old panels', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(child: _TeacherPortalTestApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Punjab Taleem Portal'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text("Today's Schedule"),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("Today's Schedule"), findsOneWidget);
    expect(find.text('Sign in to view your schedule.'), findsOneWidget);
    expect(find.text('Mark Done'), findsNothing);
    expect(find.text('Mark Attendance'), findsNothing);
    expect(find.text('Needs Grading'), findsNothing);
    expect(find.text('Class Snapshot'), findsNothing);
    expect(find.text('Timetable'), findsOneWidget);
    expect(find.text('Attendance'), findsWidgets);
    expect(find.text('Menu'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('notifications opens a blank page with persistent navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _TeacherPortalTestApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Punjab Taleem Portal'), findsOneWidget);
    expect(find.byTooltip('Notifications'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Timetable'), findsOneWidget);
    expect(find.text('Attendance'), findsWidgets);
    expect(find.text('Menu'), findsOneWidget);
    expect(find.text("Today's Schedule"), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu opens profile setup inside the teacher portal shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: _TeacherPortalTestApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile Setup'));
    await tester.pumpAndSettle();

    expect(find.text('Teacher profile'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Timetable'), findsOneWidget);
    expect(find.text('Attendance'), findsWidgets);
    expect(find.text('Menu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TeacherPortalTestApp extends StatelessWidget {
  const _TeacherPortalTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const TeacherDashboard(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
