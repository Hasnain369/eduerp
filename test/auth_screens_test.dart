import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project/core/providers/locale_provider.dart';
import 'package:project/core/routes/app_router.dart';
import 'package:project/core/theme/app_theme.dart';
import 'package:project/features/auth/login_screen.dart';
import 'package:project/features/auth/register_screen.dart';

void main() {
  testWidgets('login screen adapts to narrow and wide layouts', (tester) async {
    for (final size in [const Size(320, 640), const Size(900, 850)]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const ProviderScope(child: _AuthTestApp()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back (خوش آمدید)'), findsOneWidget);
      expect(find.text('Email address'), findsWidgets);
      expect(find.text('Sign up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

  });

  testWidgets('language selector switches auth copy to Urdu', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: _AuthTestApp()));

    await tester.tap(find.text('اردو'));
    await tester.pumpAndSettle();

    expect(find.text('خوش آمدید'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(Scaffold))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('signup action opens the styled teacher registration screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: _AuthTestApp()));

    await tester.ensureVisible(find.text('Sign up'));
    await tester.tap(find.text('Sign up'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Create teacher account'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _AuthTestApp extends ConsumerWidget {
  const _AuthTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: locale.languageCode == 'ur'
          ? AppTheme.lightTheme.copyWith(
              textTheme: AppTheme.lightTheme.textTheme.apply(
                fontFamily: 'NotoNastaliqUrdu',
              ),
            )
          : AppTheme.lightTheme,
      onGenerateRoute: AppRouter.generateRoute,
      home: const LoginScreen(),
    );
  }
}
