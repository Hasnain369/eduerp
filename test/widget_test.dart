import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project/app.dart';
import 'package:project/core/widgets/dashboard_scaffold.dart';
import 'package:project/core/widgets/school_drawer.dart';
import 'package:project/core/widgets/stat_card.dart';

void main() {
  testWidgets('App shows splash screen with SchoolHub branding', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));

    expect(find.text('SchoolHub'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });

  testWidgets('Stat cards fit narrow and wide dashboard tiles', (tester) async {
    for (final size in [const Size(150, 230), const Size(280, 190)]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: const StatCard(
                  label: 'Academic Performance',
                  value: '92%',
                  subtitle: 'A+ Grade',
                  icon: Icons.trending_up_rounded,
                  color: Colors.blue,
                  trailing: Chip(label: Text('Excellent')),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('teacher navigation shows the teacher mark and logout', (
    tester,
  ) async {
    var didLogout = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu),
              ),
            ),
          ),
          drawer: SchoolDrawer(
            role: 'teacher',
            activeRoute: 'dashboard',
            onLogout: () => didLogout = true,
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('T'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    await tester.tap(find.text('Logout'));
    await tester.pumpAndSettle();
    expect(didLogout, isTrue);
  });

  testWidgets('dashboard navigation preserves a back route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: '/dashboard',
        onGenerateRoute: (settings) => switch (settings.name) {
          '/dashboard' => MaterialPageRoute<void>(
            builder: (_) => DashboardScaffold(
              title: 'Dashboard',
              role: 'Teacher',
              activeRoute: '/dashboard',
              userName: 'Teacher',
              userDetail: 'Teacher',
              destinations: const [
                DashboardDestination(
                  label: 'Dashboard',
                  icon: Icons.dashboard_outlined,
                  route: '/dashboard',
                ),
                DashboardDestination(
                  label: 'Classes',
                  icon: Icons.class_outlined,
                  route: '/classes',
                ),
              ],
              onLogout: () {},
              body: const Text('Dashboard content'),
            ),
          ),
          '/classes' => MaterialPageRoute<void>(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Classes')),
              body: Text('Class content'),
            ),
          ),
          _ => null,
        },
      ),
    );

    await tester.tap(find.byTooltip('Open navigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Classes'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard content'), findsOneWidget);
  });

  testWidgets(
    'Splash screen redirects to login when user is not authenticated',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: App()));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Welcome Back (خوش آمدید)'), findsOneWidget);
    },
  );
}
