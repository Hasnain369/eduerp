import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketledger/features/splash/splash_screen.dart' as splash;
import 'package:pocketledger/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('first launch completes setup and can add a transaction', (
    tester,
  ) async {
    await tester.pumpWidget(const PocketLedgerApp());
    expect(find.byKey(const Key('splash-logo')), findsOneWidget);
    expect(find.text('Bank-Grade Security • v1.0.0'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('Let’s get to know you'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Alex');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Your income'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '3500');
    await tester.tap(find.text('Finish setup'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Transactions'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Add Transaction'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '42.50');
    await tester.enterText(find.byType(TextFormField).at(1), 'Groceries');
    await tester.scrollUntilVisible(
      find.text('Save'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('- PKR 42.5'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Grocer');
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'not found');
    await tester.pumpAndSettle();
    expect(find.text('No matching transactions.'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Income').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '200');
    await tester.enterText(find.byType(TextFormField).at(1), 'Allowance');
    await tester.scrollUntilVisible(
      find.text('Save'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('+ PKR 200'), findsOneWidget);

    await tester.tap(find.text('Income').last);
    await tester.pumpAndSettle();
    expect(find.text('Allowance'), findsOneWidget);
    expect(find.text('Groceries'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Groceries'));
    final groceriesCard = find.ancestor(
      of: find.text('Groceries'),
      matching: find.byType(Dismissible),
    );
    await tester.drag(groceriesCard, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete transaction?'), findsOneWidget);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsNothing);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Alex 👋'), findsOneWidget);
    expect(find.text('PKR 3,657.5'), findsOneWidget);
    expect(find.text('Spending Overview'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Recent Transactions'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('Groceries'), findsOneWidget);

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Currency'), findsOneWidget);

    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Alex New');
    await tester.enterText(find.byType(TextField).at(1), '4000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Alex New'), findsOneWidget);
    expect(find.text('Total income · PKR 4,200'), findsOneWidget);

    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();
    expect(find.text('USD (US Dollar)'), findsOneWidget);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Settings').first)).brightness,
      Brightness.dark,
    );

    await tester.tap(find.text('Categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add category'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Travel');
    await tester.tap(find.text('Add').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Travel'),
      150,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Travel'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('About PocketLedger'), findsOneWidget);
  });

  testWidgets('the splash uses the requested system brightness', (
    tester,
  ) async {
    var continued = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: splash.SplashScreen(onContinue: () => continued = true),
      ),
    );

    expect(find.byKey(const Key('splash-logo')), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(splash.SplashScreen))).brightness,
      Brightness.dark,
    );
    expect(
      tester.getCenter(find.byKey(const Key('splash-logo'))).dx,
      closeTo(
        MediaQuery.sizeOf(
              tester.element(find.byType(splash.SplashScreen)),
            ).width /
            2,
        1,
      ),
    );
    final initialProgress = tester.getSize(
      find.byKey(const Key('splash-progress-highlight')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    final advancingProgress = tester.getSize(
      find.byKey(const Key('splash-progress-highlight')),
    );
    expect(advancingProgress.width, greaterThan(initialProgress.width));
    expect(advancingProgress.width, lessThan(114));

    await tester.pump(const Duration(milliseconds: 800));
    expect(continued, isTrue);
    expect(
      tester.getSize(find.byKey(const Key('splash-progress-highlight'))).width,
      closeTo(114, 0.1),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('reports filter periods and compare actual transaction totals', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 8));
    final twoWeeksAgo = now.subtract(const Duration(days: 15));
    final lastMonth = DateTime(now.year, now.month - 1, 15);
    final transactions = [
      LedgerTransaction(
        id: 'current',
        title: 'Groceries',
        amount: 250,
        isIncome: false,
        category: 'Food',
        date: now,
      ),
      LedgerTransaction(
        id: 'last-week',
        title: 'Bus',
        amount: 100,
        isIncome: false,
        category: 'Transport',
        date: lastWeek,
      ),
      LedgerTransaction(
        id: 'two-weeks-ago',
        title: 'Dinner',
        amount: 200,
        isIncome: false,
        category: 'Food',
        date: twoWeeksAgo,
      ),
      LedgerTransaction(
        id: 'last-month',
        title: 'Books',
        amount: 75,
        isIncome: false,
        category: 'Education',
        date: lastMonth,
      ),
    ];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('profile_name', 'Alex');
    await preferences.setString('profile_salary', '10000');
    await preferences.setString(
      'ledger_transactions',
      jsonEncode(
        transactions.map((transaction) => transaction.toJson()).toList(),
      ),
    );
    final yearlyTotal = transactions
        .where((transaction) => transaction.date.year == now.year)
        .fold<double>(0, (total, transaction) => total + transaction.amount);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: LedgerShell(themeMode: ThemeMode.light, onThemeChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Total Spending'), findsOneWidget);
    expect(find.text('Income vs Expenses'), findsNothing);

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();
    expect(find.text('250'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('150%'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Previous week'));
    await tester.pumpAndSettle();
    expect(find.text('100'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('50%'),
      ),
      findsOneWidget,
    );
    final decreaseIcon = tester.widget<Icon>(
      find.byIcon(Icons.arrow_downward_rounded),
    );
    expect(decreaseIcon.color, const Color(0xFF0AA879));

    await tester.tap(find.byTooltip('Next week'));
    await tester.pumpAndSettle();
    expect(find.text('250'), findsWidgets);

    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();
    expect(find.text(yearlyTotal.toInt().toString()), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Spending by Category'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Food'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Income vs Expenses'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Income'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
  });

  testWidgets('Reports remain readable in dark mode on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('profile_salary', '10000');
    await preferences.setString(
      'ledger_transactions',
      jsonEncode([
        LedgerTransaction(
          id: 'dark-expense',
          title: 'Groceries',
          amount: 25,
          isIncome: false,
          category: 'Food',
          date: DateTime.now(),
        ).toJson(),
      ]),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LedgerShell(themeMode: ThemeMode.dark, onThemeChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();
    expect(find.text('Total Spending'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Income vs Expenses'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Income'), findsOneWidget);
  });
}
