import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/locale_provider.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    return MaterialApp(
      title: 'SchoolHub',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: locale.languageCode == 'ur'
          ? AppTheme.lightTheme.copyWith(
              textTheme: AppTheme.lightTheme.textTheme.apply(
                fontFamily: 'NotoNastaliqUrdu',
              ),
              primaryTextTheme: AppTheme.lightTheme.primaryTextTheme.apply(
                fontFamily: 'NotoNastaliqUrdu',
              ),
            )
          : AppTheme.lightTheme,
      onGenerateRoute: AppRouter.generateRoute,
      home: const SplashScreen(),
    );
  }
}
