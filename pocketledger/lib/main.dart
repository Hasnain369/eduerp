import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/onboarding/onboarding_screen.dart' as onboarding;
import 'features/splash/splash_screen.dart' as splash;

void main() {
  runApp(const PocketLedgerApp());
}

const _green = Color(0xFF079B70);
const _mint = Color(0xFF36C99C);
final _navigatorKey = GlobalKey<NavigatorState>();

class PocketLedgerApp extends StatefulWidget {
  const PocketLedgerApp({super.key});

  @override
  State<PocketLedgerApp> createState() => _PocketLedgerAppState();
}

class _PocketLedgerAppState extends State<PocketLedgerApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString('theme_mode');
    if (!mounted) return;
    setState(() {
      _themeMode = switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'PocketLedger',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: splash.SplashScreen(
        onContinue: () async {
          final preferences = await SharedPreferences.getInstance();
          final hasProfile =
              preferences.getString('profile_name') != null &&
              preferences.getString('profile_salary') != null;
          _navigatorKey.currentState!.pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) => hasProfile
                  ? LedgerShell(
                      themeMode: _themeMode,
                      onThemeChanged: _changeThemeMode,
                    )
                  : onboarding.OnboardingScreen(
                      onComplete: () {
                        _navigatorKey.currentState!.pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => LedgerShell(
                              themeMode: _themeMode,
                              onThemeChanged: _changeThemeMode,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _changeThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('theme_mode', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: _green,
      brightness: brightness,
      surface: isDark ? const Color(0xFF101B18) : Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? const Color(0xFF101B18)
          : const Color(0xFFF8FCFA),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF1B2924) : const Color(0xFFF2F7F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF31433C) : const Color(0xFFE0EAE4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
      ),
    );
  }
}

class LedgerTransaction {
  LedgerTransaction({
    required this.title,
    required this.amount,
    required this.isIncome,
    required this.category,
    required this.date,
    required this.id,
    this.note = '',
  });

  final String id;
  final String title;
  final double amount;
  final bool isIncome;
  final String category;
  final DateTime date;
  final String note;

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'amount': amount,
    'isIncome': isIncome,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
  };

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    final isIncome = json['isIncome'] as bool;
    final savedCategory =
        json['category'] as String? ?? (isIncome ? 'Income' : 'Others');
    return LedgerTransaction(
      id:
          json['id'] as String? ??
          '${json['date'] ?? 'legacy'}-${json['title'] ?? 'transaction'}-${json['amount'] ?? 0}',
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      isIncome: isIncome,
      category: savedCategory == 'Other' ? 'Others' : savedCategory,
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      note: json['note'] as String? ?? '',
    );
  }
}

class LedgerCategory {
  const LedgerCategory({
    required this.name,
    required this.color,
    required this.icon,
  });

  final String name;
  final Color color;
  final IconData icon;

  Map<String, Object> toJson() => {
    'name': name,
    'color': color.toARGB32(),
    'icon': icon.codePoint,
  };

  factory LedgerCategory.fromJson(Map<String, dynamic> json) {
    return LedgerCategory(
      name: json['name'] as String,
      color: Color(json['color'] as int),
      icon: IconData(json['icon'] as int, fontFamily: 'MaterialIcons'),
    );
  }
}

const _defaultCategories = <LedgerCategory>[
  LedgerCategory(
    name: 'Food',
    color: Color(0xFFFF4545),
    icon: Icons.restaurant,
  ),
  LedgerCategory(
    name: 'Transport',
    color: Color(0xFFFF4545),
    icon: Icons.directions_bus_filled_rounded,
  ),
  LedgerCategory(
    name: 'Shopping',
    color: Color(0xFFFF8A00),
    icon: Icons.shopping_bag_outlined,
  ),
  LedgerCategory(
    name: 'Education',
    color: Color(0xFF6366F1),
    icon: Icons.school_rounded,
  ),
  LedgerCategory(
    name: 'Bills',
    color: Color(0xFF3B82F6),
    icon: Icons.receipt_long_outlined,
  ),
  LedgerCategory(
    name: 'Health',
    color: Color(0xFFEF476F),
    icon: Icons.favorite_border_rounded,
  ),
  LedgerCategory(
    name: 'Entertainment',
    color: Color(0xFF8B5CF6),
    icon: Icons.tv_outlined,
  ),
  LedgerCategory(
    name: 'Others',
    color: Color(0xFF94A3B8),
    icon: Icons.more_horiz_rounded,
  ),
];

const _currencies = <(String, String)>[
  ('PKR', 'Pakistan Rupee'),
  ('USD', 'US Dollar'),
  ('EUR', 'Euro'),
  ('GBP', 'British Pound'),
  ('INR', 'Indian Rupee'),
  ('AED', 'UAE Dirham'),
  ('SAR', 'Saudi Riyal'),
  ('CAD', 'Canadian Dollar'),
  ('AUD', 'Australian Dollar'),
  ('JPY', 'Japanese Yen'),
  ('CNY', 'Chinese Yuan'),
];

class LedgerShell extends StatefulWidget {
  const LedgerShell({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<LedgerShell> createState() => _LedgerShellState();
}

class _LedgerShellState extends State<LedgerShell> {
  int _selectedIndex = 0;
  final List<LedgerTransaction> _transactions = [];
  List<LedgerCategory> _categories = _defaultCategories;
  String _profileName = '';
  double _monthlySalary = 0;
  String _currencyCode = 'PKR';
  late ThemeMode _themeMode = widget.themeMode;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadLedger();
  }

  Future<void> _loadLedger() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedTransactions = preferences.getString('ledger_transactions');
    final encodedCategories = preferences.getString('ledger_categories');
    final loadedTransactions = encodedTransactions == null
        ? <LedgerTransaction>[]
        : (jsonDecode(encodedTransactions) as List<dynamic>)
              .map(
                (transaction) => LedgerTransaction.fromJson(
                  transaction as Map<String, dynamic>,
                ),
              )
              .toList();
    final customCategories = encodedCategories == null
        ? <LedgerCategory>[]
        : (jsonDecode(encodedCategories) as List<dynamic>)
              .map(
                (category) =>
                    LedgerCategory.fromJson(category as Map<String, dynamic>),
              )
              .toList();
    if (!mounted) return;
    setState(() {
      _profileName = preferences.getString('profile_name') ?? '';
      _monthlySalary =
          double.tryParse(preferences.getString('profile_salary') ?? '') ?? 0;
      _currencyCode = preferences.getString('currency_code') ?? 'PKR';
      _categories = [
        ..._defaultCategories,
        ...customCategories.where(
          (custom) =>
              !_defaultCategories.any((preset) => preset.name == custom.name),
        ),
      ];
      _transactions
        ..clear()
        ..addAll(loadedTransactions);
    });
  }

  Future<void> _addTransaction() async {
    final transaction = await Navigator.of(context).push<LedgerTransaction>(
      MaterialPageRoute<LedgerTransaction>(
        builder: (_) => AddTransactionPage(
          categories: _categories,
          currencyCode: _currencyCode,
        ),
      ),
    );
    if (transaction == null || !mounted) return;
    setState(() {
      _transactions.insert(0, transaction);
      _selectedIndex = 1;
    });
    await _persistTransactions();
  }

  Future<void> _deleteTransaction(LedgerTransaction transaction) async {
    final index = _transactions.indexWhere((item) => item.id == transaction.id);
    if (index == -1) return;
    setState(() => _transactions.removeAt(index));
    await _persistTransactions();
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Transaction deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              setState(() {
                _transactions.insert(
                  index.clamp(0, _transactions.length),
                  transaction,
                );
              });
              _persistTransactions();
            },
          ),
        ),
      );
  }

  Future<void> _persistTransactions() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'ledger_transactions',
      jsonEncode(_transactions.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> _updateProfile(String name, double income) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('profile_name', name);
    await preferences.setString('profile_salary', income.toString());
    if (!mounted) return;
    setState(() {
      _profileName = name;
      _monthlySalary = income;
    });
  }

  Future<void> _updateCurrency(String code) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('currency_code', code);
    if (!mounted) return;
    setState(() => _currencyCode = code);
  }

  Future<void> _addCategory(LedgerCategory category) async {
    if (_categories.any(
      (existing) => existing.name.toLowerCase() == category.name.toLowerCase(),
    )) {
      _showMessage('A category with that name already exists.');
      return;
    }
    final updated = [..._categories, category];
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'ledger_categories',
      jsonEncode(
        updated
            .where(
              (entry) => !_defaultCategories.any(
                (preset) => preset.name == entry.name,
              ),
            )
            .map((entry) => entry.toJson())
            .toList(),
      ),
    );
    if (!mounted) return;
    setState(() => _categories = updated);
  }

  Future<void> _exportTransactions() async {
    try {
      final csv = _transactionsToCsv(_transactions);
      final savedPath = await FilePicker.saveFile(
        fileName: 'pocketledger-transactions.csv',
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        bytes: Uint8List.fromList(utf8.encode(csv)),
      );
      if (!mounted || savedPath == null) return;
      _showMessage('CSV exported successfully.');
    } on PlatformException catch (error) {
      _showMessage('Could not export CSV: ${error.message ?? error.code}');
    } on MissingPluginException {
      _showMessage('CSV export is not available on this platform.');
    }
  }

  Future<void> _restoreTransactions() async {
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
        allowMultiple: false,
      );
      if (selection == null) return;
      final file = selection.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        _showMessage('Could not read the selected CSV file.');
        return;
      }
      final imported = _transactionsFromCsv(utf8.decode(bytes));
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        'ledger_transactions',
        jsonEncode(
          imported.map((transaction) => transaction.toJson()).toList(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _transactions
          ..clear()
          ..addAll(imported);
      });
      _showMessage('${imported.length} transactions restored.');
    } on FormatException {
      _showMessage('That file is not a valid PocketLedger CSV backup.');
    } on PlatformException catch (error) {
      _showMessage('Could not restore CSV: ${error.message ?? error.code}');
    } on MissingPluginException {
      _showMessage('CSV restore is not available on this platform.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dashboardBackground = isDark
        ? const Color(0xFF091525)
        : const Color(0xFFF6F8FB);
    final tileBackground = isDark ? const Color(0xFF142337) : Colors.white;
    final primaryText = isDark
        ? const Color(0xFFF4F7FC)
        : const Color(0xFF101C31);
    final secondaryText = isDark
        ? const Color(0xFF9AAAC0)
        : const Color(0xFF91A2BA);
    final monthTransactions = _transactions.where((transaction) {
      return transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month;
    }).toList();
    final monthExpenses = monthTransactions
        .where((transaction) => !transaction.isIncome)
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final monthIncome =
        _monthlySalary +
        monthTransactions
            .where((transaction) => transaction.isIncome)
            .fold<double>(
              0,
              (total, transaction) => total + transaction.amount,
            );
    final categoryTotals = {
      for (final category in _categories.map((entry) => entry.name))
        category: monthTransactions
            .where(
              (transaction) =>
                  !transaction.isIncome && transaction.category == category,
            )
            .fold<double>(
              0,
              (total, transaction) => total + transaction.amount,
            ),
    };
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final recentTransactions = _transactions.where((transaction) {
      final transactionDay = DateUtils.dateOnly(transaction.date);
      return transactionDay == today || transactionDay == yesterday;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: dashboardBackground,
      body: SafeArea(
        bottom: false,
        child: _selectedIndex == 0
            ? _HomeDashboard(
                profileName: _profileName,
                balance: monthIncome - monthExpenses,
                income: monthIncome,
                expenses: monthExpenses,
                categoryTotals: categoryTotals,
                categories: _categories,
                recentTransactions: recentTransactions,
                currencyCode: _currencyCode,
                selectedMonth: _selectedMonth,
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onMonthChanged: (month) => setState(() {
                  _selectedMonth = month;
                }),
                onViewAll: () => setState(() => _selectedIndex = 1),
              )
            : _selectedIndex == 1
            ? _TransactionsPage(
                transactions: _transactions,
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onDelete: _deleteTransaction,
                currencyCode: _currencyCode,
                categories: _categories,
              )
            : _selectedIndex == 2
            ? _ReportsPage(
                transactions: _transactions,
                categories: _categories,
                monthlySalary: _monthlySalary,
                currencyCode: _currencyCode,
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
              )
            : _selectedIndex == 3
            ? _SettingsPage(
                profileName: _profileName,
                monthlySalary: _monthlySalary,
                totalIncome:
                    _monthlySalary +
                    _transactions
                        .where((transaction) => transaction.isIncome)
                        .fold<double>(
                          0,
                          (total, transaction) => total + transaction.amount,
                        ),
                currencyCode: _currencyCode,
                themeMode: _themeMode,
                categories: _categories,
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onProfileSave: _updateProfile,
                onCurrencyChanged: _updateCurrency,
                onThemeChanged: (mode) {
                  setState(() => _themeMode = mode);
                  widget.onThemeChanged(mode);
                },
                onAddCategory: _addCategory,
                onExport: _exportTransactions,
                onRestore: _restoreTransactions,
              )
            : const SizedBox.expand(),
      ),
      bottomNavigationBar: _BottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
        onAdd: _addTransaction,
      ),
    );
  }
}

enum _ReportPeriod { weekly, monthly, yearly }

class _ReportsPage extends StatefulWidget {
  const _ReportsPage({
    required this.transactions,
    required this.categories,
    required this.monthlySalary,
    required this.currencyCode,
    required this.tileBackground,
    required this.primaryText,
    required this.secondaryText,
  });

  final List<LedgerTransaction> transactions;
  final List<LedgerCategory> categories;
  final double monthlySalary;
  final String currencyCode;
  final Color tileBackground;
  final Color primaryText;
  final Color secondaryText;

  @override
  State<_ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<_ReportsPage> {
  _ReportPeriod _period = _ReportPeriod.monthly;
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  DateTime get _periodStart {
    switch (_period) {
      case _ReportPeriod.weekly:
        final date = DateUtils.dateOnly(_selectedDate);
        return date.subtract(Duration(days: date.weekday - 1));
      case _ReportPeriod.monthly:
        return DateTime(_selectedDate.year, _selectedDate.month);
      case _ReportPeriod.yearly:
        return DateTime(_selectedDate.year);
    }
  }

  DateTime get _periodEnd {
    switch (_period) {
      case _ReportPeriod.weekly:
        return _periodStart.add(const Duration(days: 7));
      case _ReportPeriod.monthly:
        return DateTime(_periodStart.year, _periodStart.month + 1);
      case _ReportPeriod.yearly:
        return DateTime(_periodStart.year + 1);
    }
  }

  DateTime get _previousStart {
    switch (_period) {
      case _ReportPeriod.weekly:
        return _periodStart.subtract(const Duration(days: 7));
      case _ReportPeriod.monthly:
        return DateTime(_periodStart.year, _periodStart.month - 1);
      case _ReportPeriod.yearly:
        return DateTime(_periodStart.year - 1);
    }
  }

  DateTime get _previousEnd => _periodStart;

  void _movePeriod(int amount) {
    setState(() {
      _selectedDate = switch (_period) {
        _ReportPeriod.weekly => _selectedDate.add(Duration(days: amount * 7)),
        _ReportPeriod.monthly => DateTime(
          _selectedDate.year,
          _selectedDate.month + amount,
          1,
        ),
        _ReportPeriod.yearly => DateTime(
          _selectedDate.year + amount,
          _selectedDate.month,
          1,
        ),
      };
    });
  }

  Future<void> _pickPeriod() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      helpText: switch (_period) {
        _ReportPeriod.weekly => 'Choose a date in the week',
        _ReportPeriod.monthly => 'Choose a month',
        _ReportPeriod.yearly => 'Choose a year',
      },
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedDate = DateUtils.dateOnly(selected));
  }

  double _expensesBetween(DateTime start, DateTime end) {
    return widget.transactions
        .where(
          (transaction) =>
              !transaction.isIncome &&
              !transaction.date.isBefore(start) &&
              transaction.date.isBefore(end),
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);
  }

  double _incomeBetween(DateTime start, DateTime end) {
    final recordedIncome = widget.transactions
        .where(
          (transaction) =>
              transaction.isIncome &&
              !transaction.date.isBefore(start) &&
              transaction.date.isBefore(end),
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final regularIncome = switch (_period) {
      _ReportPeriod.weekly => widget.monthlySalary * 7 / 30.4375,
      _ReportPeriod.monthly => widget.monthlySalary,
      _ReportPeriod.yearly => widget.monthlySalary * 12,
    };
    return regularIncome + recordedIncome;
  }

  String get _periodName => switch (_period) {
    _ReportPeriod.weekly => 'week',
    _ReportPeriod.monthly => 'month',
    _ReportPeriod.yearly => 'year',
  };

  String get _periodLabel {
    switch (_period) {
      case _ReportPeriod.weekly:
        final end = _periodEnd.subtract(const Duration(days: 1));
        return '${DateFormat('MMM d').format(_periodStart)} – '
            '${DateFormat('MMM d').format(end)}\n${_periodStart.year}';
      case _ReportPeriod.monthly:
        return '${DateFormat('MMMM').format(_periodStart)}\n${_periodStart.year}';
      case _ReportPeriod.yearly:
        return '${_periodStart.year}';
    }
  }

  List<_ReportBar> _makeBars(List<LedgerTransaction> transactions) {
    final buckets = <_ReportBar>[];
    switch (_period) {
      case _ReportPeriod.weekly:
        for (var index = 0; index < 7; index++) {
          final start = _periodStart.add(Duration(days: index));
          final end = start.add(const Duration(days: 1));
          buckets.add(
            _ReportBar(
              label: '${DateFormat('MMM').format(start)}\n${start.day}',
              amount: _expensesIn(transactions, start, end),
            ),
          );
        }
      case _ReportPeriod.monthly:
        final daysInMonth = _periodEnd.difference(_periodStart).inDays;
        final numberOfWeeks = (daysInMonth + 6) ~/ 7;
        for (var index = 0; index < numberOfWeeks; index++) {
          final start = _periodStart.add(Duration(days: index * 7));
          final endDay = (start.day + 7).clamp(1, daysInMonth + 1).toInt();
          final end = DateTime(start.year, start.month, endDay);
          buckets.add(
            _ReportBar(
              label: '${start.day}-${endDay - 1}',
              amount: _expensesIn(transactions, start, end),
            ),
          );
        }
      case _ReportPeriod.yearly:
        for (var month = 1; month <= 12; month++) {
          final start = DateTime(_periodStart.year, month);
          final end = DateTime(_periodStart.year, month + 1);
          buckets.add(
            _ReportBar(
              label: DateFormat('MMM').format(start),
              amount: _expensesIn(transactions, start, end),
            ),
          );
        }
    }
    return buckets;
  }

  double _expensesIn(
    List<LedgerTransaction> transactions,
    DateTime start,
    DateTime end,
  ) {
    return transactions
        .where(
          (transaction) =>
              !transaction.isIncome &&
              !transaction.date.isBefore(start) &&
              transaction.date.isBefore(end),
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF142337)
        : const Color(0xFFE9EEF5);
    final muted = widget.secondaryText;
    final expenses = _expensesBetween(_periodStart, _periodEnd);
    final previousExpenses = _expensesBetween(_previousStart, _previousEnd);
    final income = _incomeBetween(_periodStart, _periodEnd);
    final currentTransactions = widget.transactions.where((transaction) {
      return !transaction.date.isBefore(_periodStart) &&
          transaction.date.isBefore(_periodEnd);
    }).toList();
    final categoryTotals = <String, double>{};
    for (final transaction in currentTransactions) {
      if (!transaction.isIncome) {
        categoryTotals.update(
          transaction.category,
          (total) => total + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }
    final reportCategories =
        categoryTotals.entries.where((entry) => entry.value > 0).toList()
          ..sort((first, second) => second.value.compareTo(first.value));
    final totalCategorySpending = reportCategories.fold<double>(
      0,
      (total, entry) => total + entry.value,
    );
    final bars = _makeBars(currentTransactions);
    final maxBar = bars.fold<double>(
      0,
      (maximum, bar) => math.max(maximum, bar.amount),
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                'Reports',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: widget.primaryText,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                height: 58,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    for (final period in _ReportPeriod.values)
                      Expanded(
                        child: _periodButton(
                          period,
                          period.name[0].toUpperCase() +
                              period.name.substring(1),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Previous $_periodName',
                    onPressed: () => _movePeriod(-1),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      color: muted,
                      size: 30,
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: 'Select $_periodName',
                      child: InkWell(
                        onTap: _pickPeriod,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _periodLabel,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: widget.primaryText,
                                    fontSize: 20,
                                    height: 1.25,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: muted,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Next $_periodName',
                    onPressed: () => _movePeriod(1),
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: muted,
                      size: 30,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _reportCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            'Total Spending',
                            style: TextStyle(
                              color: muted,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SpendingChangePill(
                          current: expenses,
                          previous: previousExpenses,
                          periodName: _periodName,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      widget.currencyCode,
                      style: TextStyle(
                        color: widget.primaryText,
                        fontSize: 20,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatMoney(expenses),
                      style: TextStyle(
                        color: widget.primaryText,
                        fontSize: 33,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _ReportBarChart(
                      bars: bars,
                      maximum: maxBar,
                      primaryText: widget.primaryText,
                      secondaryText: muted,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _reportCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending by Category',
                      style: TextStyle(
                        color: widget.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final chartSize = constraints.maxWidth < 390
                            ? 142.0
                            : 170.0;
                        final chart = SizedBox(
                          width: chartSize,
                          height: chartSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: Size.square(chartSize),
                                painter: _DonutChartPainter(
                                  categoryTotals: categoryTotals,
                                  categories: reportCategories
                                      .map(
                                        (entry) => LedgerCategory(
                                          name: entry.key,
                                          color: _reportCategoryColor(
                                            entry.key,
                                            widget.categories,
                                          ),
                                          icon: _categoryIcon(
                                            entry.key,
                                            widget.categories,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  colors: reportCategories
                                      .map(
                                        (entry) => _reportCategoryColor(
                                          entry.key,
                                          widget.categories,
                                        ),
                                      )
                                      .toList(),
                                  trackColor: isDark
                                      ? const Color(0xFF26364A)
                                      : const Color(0xFFE7EDF4),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.currencyCode,
                                    style: TextStyle(
                                      color: widget.primaryText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    _formatMoney(totalCategorySpending),
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: widget.primaryText,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    'Total Spent',
                                    style: TextStyle(
                                      color: muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                        if (reportCategories.isEmpty) {
                          return Column(
                            children: [
                              chart,
                              const SizedBox(height: 8),
                              Text(
                                'No spending in this period.',
                                style: TextStyle(color: muted, fontSize: 13),
                              ),
                            ],
                          );
                        }
                        final legend = Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final entry in reportCategories)
                              _ReportCategoryRow(
                                name: entry.key,
                                amount: entry.value,
                                total: totalCategorySpending,
                                color: _reportCategoryColor(
                                  entry.key,
                                  widget.categories,
                                ),
                                primaryText: widget.primaryText,
                                secondaryText: muted,
                              ),
                          ],
                        );
                        if (constraints.maxWidth < 390) {
                          return Column(
                            children: [
                              chart,
                              const SizedBox(height: 16),
                              legend,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            chart,
                            const SizedBox(width: 12),
                            Expanded(child: legend),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _reportCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income vs Expenses',
                      style: TextStyle(
                        color: widget.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _IncomeExpenseRow(
                      title: 'Income',
                      amount: income,
                      maximum: math.max(income, expenses),
                      currencyCode: widget.currencyCode,
                      color: _green,
                      primaryText: widget.primaryText,
                      secondaryText: muted,
                      trackColor: background,
                    ),
                    const SizedBox(height: 20),
                    _IncomeExpenseRow(
                      title: 'Expenses',
                      amount: expenses,
                      maximum: math.max(income, expenses),
                      currencyCode: widget.currencyCode,
                      color: const Color(0xFFF0444A),
                      primaryText: widget.primaryText,
                      secondaryText: muted,
                      trackColor: background,
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _periodButton(_ReportPeriod period, String label) {
    final isSelected = period == _period;
    return Semantics(
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: () => setState(() => _period = period),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _mint : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : widget.secondaryText,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportCard(BuildContext context, {required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.tileBackground,
        borderRadius: BorderRadius.circular(27),
        border: isDark ? Border.all(color: const Color(0xFF1D2D42)) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF24364B).withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: child,
    );
  }
}

class _ReportBar {
  const _ReportBar({required this.label, required this.amount});

  final String label;
  final double amount;
}

class _ReportBarChart extends StatelessWidget {
  const _ReportBarChart({
    required this.bars,
    required this.maximum,
    required this.primaryText,
    required this.secondaryText,
    required this.isDark,
  });

  final List<_ReportBar> bars;
  final double maximum;
  final Color primaryText;
  final Color secondaryText;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final guideColor = isDark
        ? const Color(0xFF26364A)
        : const Color(0xFFF0F3F7);
    return SizedBox(
      height: 175,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slotWidth = constraints.maxWidth / bars.length;
          final barWidth = math.min(36.0, slotWidth * 0.55);
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 34,
                child: Container(height: 1, color: guideColor),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var index = 0; index < bars.length; index++)
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: barWidth,
                            height: maximum == 0
                                ? 4
                                : math.max(
                                    8,
                                    126 * bars[index].amount / maximum,
                                  ),
                            decoration: BoxDecoration(
                              color:
                                  bars[index].amount == maximum && maximum > 0
                                  ? _green
                                  : _mint,
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 30,
                child: Row(
                  children: [
                    for (final bar in bars)
                      Expanded(
                        child: Text(
                          bar.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: bars.length > 7 ? 9 : 11,
                            height: 1.25,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SpendingChangePill extends StatelessWidget {
  const _SpendingChangePill({
    required this.current,
    required this.previous,
    required this.periodName,
  });

  final double current;
  final double previous;
  final String periodName;

  @override
  Widget build(BuildContext context) {
    final change = current - previous;
    final increased = change > 0;
    final decreased = change < 0;
    final color = increased
        ? const Color(0xFFF0444A)
        : decreased
        ? const Color(0xFF0AA879)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final background = increased
        ? const Color(0xFFFFEEEE)
        : decreased
        ? const Color(0xFFE9FBF3)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final percentage = previous == 0
        ? (current == 0 ? '0%' : 'New')
        : '${(change.abs() / previous * 100).round()}%';
    final arrow = increased
        ? Icons.arrow_upward_rounded
        : decreased
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(arrow, size: 13, color: color),
            ),
            TextSpan(
              text: ' $percentage  vs last $periodName',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ReportCategoryRow extends StatelessWidget {
  const _ReportCategoryRow({
    required this.name,
    required this.amount,
    required this.total,
    required this.color,
    required this.primaryText,
    required this.secondaryText,
  });

  final String name;
  final double amount;
  final double total;
  final Color color;
  final Color primaryText;
  final Color secondaryText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: secondaryText, fontSize: 14),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(amount / total * 100).round()}%',
            style: TextStyle(color: primaryText, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _IncomeExpenseRow extends StatelessWidget {
  const _IncomeExpenseRow({
    required this.title,
    required this.amount,
    required this.maximum,
    required this.currencyCode,
    required this.color,
    required this.primaryText,
    required this.secondaryText,
    required this.trackColor,
  });

  final String title;
  final double amount;
  final double maximum;
  final String currencyCode;
  final Color color;
  final Color primaryText;
  final Color secondaryText;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: secondaryText, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _formatCurrency(amount, currencyCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: color == _green ? const Color(0xFF009B6E) : color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final progress = maximum == 0 ? 0.0 : amount / maximum;
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: 9,
                    color: trackColor,
                  ),
                  Container(
                    width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                    height: 9,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

Color _reportCategoryColor(String name, List<LedgerCategory> categories) {
  return switch (name) {
    'Food' => const Color(0xFF6366F1),
    'Transport' => const Color(0xFFF97316),
    'Education' => const Color(0xFFF59E0B),
    'Shopping' => const Color(0xFFA855F7),
    'Others' => const Color(0xFF06B6D4),
    _ => _categoryColor(name, categories),
  };
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.profileName,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.categoryTotals,
    required this.categories,
    required this.recentTransactions,
    required this.selectedMonth,
    required this.currencyCode,
    required this.tileBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.onMonthChanged,
    required this.onViewAll,
  });
  final String profileName;
  final double balance;
  final double income;
  final double expenses;
  final Map<String, double> categoryTotals;
  final List<LedgerCategory> categories;
  final List<LedgerTransaction> recentTransactions;
  final DateTime selectedMonth;
  final String currencyCode;
  final Color tileBackground;
  final Color primaryText;
  final Color secondaryText;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthColor = isDark ? const Color(0xFF9AAAC0) : _green;
    final totalSpentText = expenses;
    final totalCategorySpend = categoryTotals.values.fold<double>(
      0,
      (total, amount) => total + amount,
    );
    final months = List.generate(
      12,
      (index) => DateTime(DateTime.now().year, DateTime.now().month - index),
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: TextStyle(fontSize: 15, color: secondaryText),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${profileName.isEmpty ? 'Welcome' : profileName} 👋',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tileBackground,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0 : 0.06,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.notifications_none_rounded,
                          color: _green,
                          size: 26,
                        ),
                        Positioned(
                          top: 12,
                          right: 13,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _mint,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _BalanceCard(
                balance: balance,
                income: income,
                expenses: expenses,
                currencyCode: currencyCode,
              ),
              const SizedBox(height: 24),
              _SpendingCard(
                months: months,
                onMonthChanged: onMonthChanged,
                categoryTotals: categoryTotals,
                categories: categories,
                totalCategorySpend: totalCategorySpend,
                totalSpentText: totalSpentText,
                selectedMonth: selectedMonth,
                currencyCode: currencyCode,
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                monthColor: monthColor,
                isDark: isDark,
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Transactions',
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      foregroundColor: _green,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (recentTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: tileBackground,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'No transactions today or yesterday.',
                    style: TextStyle(color: secondaryText, fontSize: 14),
                  ),
                )
              else
                ...recentTransactions
                    .take(5)
                    .map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RecentTransactionTile(
                          transaction: transaction,
                          tileBackground: tileBackground,
                          primaryText: primaryText,
                          secondaryText: secondaryText,
                          currencyCode: currencyCode,
                          categories: categories,
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expenses,
    required this.currencyCode,
  });

  final double balance;
  final double income;
  final double expenses;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paleText = isDark ? const Color(0xFF8DD9CC) : const Color(0xFFD7FFF3);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 23, 24, 21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF06453F), Color(0xFF0D2B42)]
              : const [Color(0xFF0BA276), Color(0xFF20BCA7)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: isDark ? Border.all(color: const Color(0xFF11605A)) : null,
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: isDark ? 0.08 : 0.10),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total Balance',
                  style: TextStyle(color: paleText, fontSize: 16),
                ),
              ),
              Container(
                width: 52,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            _formatCurrency(balance, currencyCode),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 31,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 19),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.22)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  label: 'Income',
                  amount: income,
                  currencyCode: currencyCode,
                  icon: Icons.arrow_upward_rounded,
                  paleText: paleText,
                ),
              ),
              Expanded(
                child: _BalanceMetric(
                  label: 'Expenses',
                  amount: expenses,
                  currencyCode: currencyCode,
                  icon: Icons.arrow_downward_rounded,
                  paleText: paleText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.amount,
    required this.icon,
    required this.paleText,
    required this.currencyCode,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color paleText;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: paleText),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: paleText, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          _formatCurrency(amount, currencyCode),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SpendingCard extends StatelessWidget {
  const _SpendingCard({
    required this.months,
    required this.onMonthChanged,
    required this.categoryTotals,
    required this.categories,
    required this.totalCategorySpend,
    required this.totalSpentText,
    required this.selectedMonth,
    required this.currencyCode,
    required this.tileBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.monthColor,
    required this.isDark,
  });

  final List<DateTime> months;
  final ValueChanged<DateTime> onMonthChanged;
  final Map<String, double> categoryTotals;
  final List<LedgerCategory> categories;
  final double totalCategorySpend;
  final double totalSpentText;
  final DateTime selectedMonth;
  final String currencyCode;
  final Color tileBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color monthColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    const darkChartColors = [
      Color(0xFF22C8D6),
      Color(0xFFFF6584),
      Color(0xFFFFC52E),
      Color(0xFF818CF8),
      Color(0xFF2DD4A3),
      Color(0xFF60A5FA),
      Color(0xFFF472B6),
      Color(0xFF34D399),
    ];
    final chartColors = isDark
        ? List.generate(
            categories.length,
            (index) => darkChartColors[index % darkChartColors.length],
          )
        : categories.map((category) => category.color).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
      decoration: BoxDecoration(
        color: tileBackground,
        borderRadius: BorderRadius.circular(27),
        border: isDark ? Border.all(color: const Color(0xFF1D2D42)) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF24364B).withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spending Overview',
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<DateTime>(
                  value: months.firstWhere(
                    (month) => _sameMonth(month, selectedMonth),
                    orElse: () => months.first,
                  ),
                  isDense: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: monthColor),
                  style: TextStyle(
                    color: monthColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  items: months
                      .map(
                        (month) => DropdownMenuItem(
                          value: month,
                          child: Text(
                            _sameMonth(month, DateTime.now())
                                ? 'This Month'
                                : DateFormat('MMM yyyy').format(month),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (month) {
                    if (month != null) onMonthChanged(month);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = constraints.maxWidth < 370 ? 150.0 : 170.0;
              return Row(
                children: [
                  SizedBox(
                    width: chartSize,
                    height: chartSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size.square(chartSize),
                          painter: _DonutChartPainter(
                            categoryTotals: categoryTotals,
                            categories: categories,
                            colors: chartColors,
                            trackColor: isDark
                                ? const Color(0xFF26364A)
                                : const Color(0xFFE7EDF4),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatCurrency(totalSpentText, currencyCode),
                              maxLines: 1,
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Total Spent',
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        for (var index = 0; index < categories.length; index++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            child: _CategoryLegendRow(
                              name: categories[index].name,
                              color: chartColors[index],
                              amount:
                                  categoryTotals[categories[index].name] ?? 0,
                              total: totalCategorySpend,
                              primaryText: primaryText,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

bool _sameMonth(DateTime first, DateTime second) {
  return first.year == second.year && first.month == second.month;
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.categoryTotals,
    required this.categories,
    required this.colors,
    required this.trackColor,
  });

  final Map<String, double> categoryTotals;
  final List<LedgerCategory> categories;
  final List<Color> colors;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.105;
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    final total = categoryTotals.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );
    if (total == 0) return;

    var startAngle = -math.pi / 2;
    for (var index = 0; index < categories.length; index++) {
      final amount = categoryTotals[categories[index].name] ?? 0;
      if (amount <= 0) continue;
      final sweepAngle = amount / total * math.pi * 2;
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.categoryTotals != categoryTotals ||
        oldDelegate.categories != categories ||
        oldDelegate.colors != colors ||
        oldDelegate.trackColor != trackColor;
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({
    required this.name,
    required this.color,
    required this.amount,
    required this.total,
    required this.primaryText,
  });

  final String name;
  final Color color;
  final double amount;
  final double total;
  final Color primaryText;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (amount / total * 100).round();
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$percent%',
          style: TextStyle(
            color: primaryText,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RecentTransactionTile extends StatelessWidget {
  const _RecentTransactionTile({
    required this.transaction,
    required this.tileBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.currencyCode,
    required this.categories,
  });

  final LedgerTransaction transaction;
  final Color tileBackground;
  final Color primaryText;
  final Color secondaryText;
  final String currencyCode;
  final List<LedgerCategory> categories;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = transaction.isIncome
        ? const Color(0xFF00B981)
        : (isDark ? const Color(0xFFFF647C) : const Color(0xFFFF4545));
    final iconColor = transaction.isIncome
        ? const Color(0xFF00A879)
        : _categoryColor(transaction.category, categories);
    final icon = transaction.isIncome
        ? Icons.account_balance_wallet_outlined
        : _categoryIcon(transaction.category, categories);
    final transactionDay = DateUtils.dateOnly(transaction.date);
    final today = DateUtils.dateOnly(DateTime.now());
    final day = transactionDay == today
        ? 'Today'
        : transactionDay == today.subtract(const Duration(days: 1))
        ? 'Yesterday'
        : DateFormat('MMM d, yyyy').format(transaction.date);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: tileBackground,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: const Color(0xFF1D2D42)) : null,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: const Color(0xFF24364B).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.17 : 0.08),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: iconColor, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: primaryText,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.isIncome ? 'Income' : transaction.category} · $day',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: secondaryText, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${transaction.isIncome ? '+' : '-'} ${_formatCurrency(transaction.amount, currencyCode)}',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

enum _TransactionFilter { all, income, expenses }

class _TransactionsPage extends StatefulWidget {
  const _TransactionsPage({
    required this.transactions,
    required this.tileBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.onDelete,
    required this.currencyCode,
    required this.categories,
  });

  final List<LedgerTransaction> transactions;
  final Color tileBackground;
  final Color primaryText;
  final Color secondaryText;
  final ValueChanged<LedgerTransaction> onDelete;
  final String currencyCode;
  final List<LedgerCategory> categories;

  @override
  State<_TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<_TransactionsPage> {
  final _searchController = TextEditingController();
  _TransactionFilter _filter = _TransactionFilter.all;
  String? _categoryFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = widget.transactions.where(_matchesFilter).toList()
      ..sort((first, second) => second.date.compareTo(first.date));
    final monthGroups = <DateTime, List<LedgerTransaction>>{};
    for (final transaction in filtered) {
      final month = DateTime(transaction.date.year, transaction.date.month);
      monthGroups.putIfAbsent(month, () => []).add(transaction);
    }

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 0),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Transactions',
              style: TextStyle(
                color: widget.primaryText,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: TextField(
                      key: const ValueKey('transaction-search'),
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(color: widget.primaryText, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: TextStyle(
                          color: widget.secondaryText,
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: widget.secondaryText,
                          size: 25,
                        ),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: widget.secondaryText,
                                ),
                              ),
                        filled: true,
                        fillColor: widget.tileBackground,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF25364A)
                                : const Color(0xFFE3EAF2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0xFF25364A)
                                : const Color(0xFFE3EAF2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: _green,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 54,
                  height: 54,
                  child: OutlinedButton(
                    key: const ValueKey('transaction-category-filter'),
                    onPressed: _showCategoryFilter,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: widget.tileBackground,
                      foregroundColor: widget.secondaryText,
                      padding: EdgeInsets.zero,
                      side: BorderSide(
                        color: isDark
                            ? const Color(0xFF25364A)
                            : const Color(0xFFE3EAF2),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: _categoryFilter == null
                          ? widget.secondaryText
                          : _green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                _filterChip('All', _TransactionFilter.all),
                const SizedBox(width: 8),
                _filterChip('Income', _TransactionFilter.income),
                const SizedBox(width: 8),
                _filterChip('Expenses', _TransactionFilter.expenses),
              ],
            ),
          ),
        ),
        if (filtered.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),
            sliver: SliverToBoxAdapter(
              child: Text(
                widget.transactions.isEmpty
                    ? 'No transactions yet.'
                    : 'No matching transactions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: widget.secondaryText, fontSize: 14),
              ),
            ),
          )
        else
          for (final entry in monthGroups.entries) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        DateFormat('MMMM yyyy').format(entry.key).toUpperCase(),
                        style: TextStyle(
                          color: widget.primaryText.withValues(alpha: 0.82),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.35,
                        ),
                      ),
                    ),
                    Text(
                      'Total: ${_formatCurrency(_groupTotal(entry.value), widget.currencyCode)}',
                      style: TextStyle(
                        color: widget.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              sliver: SliverList.separated(
                itemCount: entry.value.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final transaction = entry.value[index];
                  return Dismissible(
                    key: ValueKey(transaction.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (_) => _confirmDelete(context),
                    onDismissed: (_) => widget.onDelete(transaction),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 22),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4545),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                    ),
                    child: _RecentTransactionTile(
                      transaction: transaction,
                      tileBackground: widget.tileBackground,
                      primaryText: widget.primaryText,
                      secondaryText: widget.secondaryText,
                      currencyCode: widget.currencyCode,
                      categories: widget.categories,
                    ),
                  );
                },
              ),
            ),
          ],
        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  bool _matchesFilter(LedgerTransaction transaction) {
    if (_filter == _TransactionFilter.income && !transaction.isIncome) {
      return false;
    }
    if (_filter == _TransactionFilter.expenses && transaction.isIncome) {
      return false;
    }
    if (_categoryFilter != null && transaction.category != _categoryFilter) {
      return false;
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return transaction.title.toLowerCase().contains(query) ||
        transaction.category.toLowerCase().contains(query) ||
        _formatMoney(transaction.amount).contains(query);
  }

  double _groupTotal(List<LedgerTransaction> transactions) {
    final relevant = transactions.where((transaction) {
      if (_filter == _TransactionFilter.income) return transaction.isIncome;
      return !transaction.isIncome;
    });
    return relevant.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );
  }

  Widget _filterChip(String label, _TransactionFilter filter) {
    final selected = _filter == filter;
    return ChoiceChip(
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(label),
      ),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = filter),
      labelStyle: TextStyle(
        color: selected
            ? Colors.white
            : widget.primaryText.withValues(alpha: 0.82),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: widget.tileBackground,
      selectedColor: _green,
      side: BorderSide(
        color: selected
            ? _green
            : Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF25364A)
            : const Color(0xFFE2EAF2),
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(vertical: 6),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This transaction will be removed from your ledger.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF4545),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _showCategoryFilter() async {
    final categories = {
      for (final transaction in widget.transactions)
        if (!transaction.isIncome) transaction.category,
    }.toList()..sort();
    final category = await showModalBottomSheet<String?>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All categories'),
              trailing: _categoryFilter == null
                  ? const Icon(Icons.check, color: _green)
                  : null,
              onTap: () => Navigator.pop(context, ''),
            ),
            for (final category in categories)
              ListTile(
                title: Text(category),
                trailing: _categoryFilter == category
                    ? const Icon(Icons.check, color: _green)
                    : null,
                onTap: () => Navigator.pop(context, category),
              ),
          ],
        ),
      ),
    );
    if (category == null) return;
    setState(() => _categoryFilter = category.isEmpty ? null : category);
  }
}

IconData _categoryIcon(String category, List<LedgerCategory> categories) {
  final saved = categories.where((entry) => entry.name == category);
  if (saved.isNotEmpty) return saved.first.icon;
  return switch (category) {
    'Food' => Icons.restaurant,
    'Transport' => Icons.directions_bus_filled_rounded,
    'Shopping' => Icons.shopping_bag_outlined,
    'Education' => Icons.school_rounded,
    'Bills' => Icons.receipt_long_outlined,
    'Health' => Icons.favorite_border_rounded,
    'Entertainment' => Icons.tv_outlined,
    _ => Icons.more_horiz_rounded,
  };
}

Color _categoryColor(String category, List<LedgerCategory> categories) {
  final saved = categories.where((entry) => entry.name == category);
  return saved.isNotEmpty ? saved.first.color : const Color(0xFF94A3B8);
}

String _formatMoney(double amount) {
  return NumberFormat('#,##0.##').format(amount);
}

String _formatCurrency(double amount, String currencyCode) {
  return '$currencyCode ${_formatMoney(amount)}';
}

String _transactionsToCsv(List<LedgerTransaction> transactions) {
  final rows = <List<String>>[
    ['id', 'title', 'amount', 'type', 'category', 'date', 'note'],
    for (final transaction in transactions)
      [
        transaction.id,
        transaction.title,
        transaction.amount.toString(),
        transaction.isIncome ? 'income' : 'expense',
        transaction.category,
        transaction.date.toIso8601String(),
        transaction.note,
      ],
  ];
  return rows.map((row) => row.map(_escapeCsvField).join(',')).join('\r\n');
}

String _escapeCsvField(String value) {
  if (!value.contains(',') &&
      !value.contains('"') &&
      !value.contains('\n') &&
      !value.contains('\r')) {
    return value;
  }
  return '"${value.replaceAll('"', '""')}"';
}

List<LedgerTransaction> _transactionsFromCsv(String csv) {
  final rows = _parseCsv(csv);
  const expectedHeader = [
    'id',
    'title',
    'amount',
    'type',
    'category',
    'date',
    'note',
  ];
  if (rows.isEmpty || rows.first.length != expectedHeader.length) {
    throw const FormatException('Invalid PocketLedger CSV header.');
  }
  final header = rows.first.map((field) => field.trim().toLowerCase()).toList();
  if (!_listEquals(header, expectedHeader)) {
    throw const FormatException('Unexpected PocketLedger CSV columns.');
  }
  return [
    for (final row in rows.skip(1))
      if (row.any((field) => field.isNotEmpty)) _transactionFromCsvRow(row),
  ];
}

LedgerTransaction _transactionFromCsvRow(List<String> row) {
  if (row.length != 7) {
    throw const FormatException('Invalid transaction row.');
  }
  final type = row[3].trim().toLowerCase();
  final amount = double.tryParse(row[2].trim());
  final date = DateTime.tryParse(row[5].trim());
  if ((type != 'income' && type != 'expense') ||
      amount == null ||
      amount <= 0 ||
      date == null ||
      row[0].isEmpty ||
      row[1].trim().isEmpty ||
      row[4].trim().isEmpty) {
    throw const FormatException('Invalid transaction data.');
  }
  return LedgerTransaction(
    id: row[0],
    title: row[1],
    amount: amount,
    isIncome: type == 'income',
    category: row[4],
    date: date,
    note: row[6],
  );
}

List<List<String>> _parseCsv(String csv) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var index = 0; index < csv.length; index++) {
    final character = csv[index];
    if (quoted) {
      if (character == '"') {
        if (index + 1 < csv.length && csv[index + 1] == '"') {
          field.write('"');
          index++;
        } else {
          quoted = false;
        }
      } else {
        field.write(character);
      }
    } else if (character == '"' && field.isEmpty) {
      quoted = true;
    } else if (character == ',') {
      row.add(field.toString());
      field.clear();
    } else if (character == '\n' || character == '\r') {
      if (character == '\r' &&
          index + 1 < csv.length &&
          csv[index + 1] == '\n') {
        index++;
      }
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else {
      field.write(character);
    }
  }
  if (quoted) throw const FormatException('Unclosed CSV quote.');
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

bool _listEquals(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.profileName,
    required this.monthlySalary,
    required this.totalIncome,
    required this.currencyCode,
    required this.themeMode,
    required this.categories,
    required this.tileBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.onProfileSave,
    required this.onCurrencyChanged,
    required this.onThemeChanged,
    required this.onAddCategory,
    required this.onExport,
    required this.onRestore,
  });

  final String profileName;
  final double monthlySalary;
  final double totalIncome;
  final String currencyCode;
  final ThemeMode themeMode;
  final List<LedgerCategory> categories;
  final Color tileBackground;
  final Color primaryText;
  final Color secondaryText;
  final Future<void> Function(String, double) onProfileSave;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<ThemeMode> onThemeChanged;
  final Future<void> Function(LedgerCategory) onAddCategory;
  final Future<void> Function() onExport;
  final Future<void> Function() onRestore;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Settings',
              style: TextStyle(
                color: primaryText,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          sliver: SliverToBoxAdapter(
            child: Material(
              color: tileBackground,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () => _editProfile(context),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 19,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 31,
                        backgroundColor: _green,
                        child: Text(
                          _initials(profileName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Total income · ${_formatCurrency(totalIncome, currencyCode)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: secondaryText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: secondaryText, size: 25),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _SettingsTile(
                icon: Icons.currency_exchange_rounded,
                title: 'Currency',
                subtitle: _currencyName(currencyCode),
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onTap: () => _selectCurrency(context),
              ),
              _SettingsTile(
                icon: themeMode == ThemeMode.dark
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
                title: 'Theme',
                subtitle: switch (themeMode) {
                  ThemeMode.dark => 'Dark Mode',
                  ThemeMode.light => 'Light Mode',
                  ThemeMode.system => 'System Default',
                },
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onTap: () => _selectTheme(context),
              ),
              _SettingsTile(
                icon: Icons.assignment_outlined,
                title: 'Categories',
                subtitle: 'Manage your categories',
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onTap: () => _manageCategories(context),
              ),
              _SettingsTile(
                icon: Icons.file_download_outlined,
                title: 'Export Data',
                subtitle: 'Download your transactions',
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onTap: onExport,
              ),
              _SettingsTile(
                icon: Icons.cloud_download_outlined,
                title: 'Backup & Restore',
                subtitle: 'Keep your data safe',
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onTap: onRestore,
              ),
              _SettingsTile(
                icon: Icons.location_on_outlined,
                title: 'Help & Support',
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About PocketLedger',
                tileBackground: tileBackground,
                primaryText: primaryText,
                secondaryText: secondaryText,
                onTap: () => _showAbout(context),
                isLast: true,
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final result = await showDialog<(String, double)>(
      context: context,
      builder: (_) => _EditProfileDialog(
        name: profileName,
        income: monthlySalary,
        currencyCode: currencyCode,
        primaryText: primaryText,
        secondaryText: secondaryText,
      ),
    );
    if (result != null) await onProfileSave(result.$1, result.$2);
  }

  Future<void> _selectCurrency(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Choose currency',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final currency in _currencies)
              ListTile(
                title: Text(currency.$1),
                subtitle: Text(currency.$2),
                trailing: currency.$1 == currencyCode
                    ? const Icon(Icons.check_circle, color: _green)
                    : null,
                onTap: () => Navigator.pop(context, currency.$1),
              ),
          ],
        ),
      ),
    );
    if (selected != null) onCurrencyChanged(selected);
  }

  Future<void> _selectTheme(BuildContext context) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Choose theme',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            for (final mode in ThemeMode.values)
              ListTile(
                leading: Icon(switch (mode) {
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                  ThemeMode.system => Icons.settings_brightness_outlined,
                }),
                title: Text(switch (mode) {
                  ThemeMode.light => 'Light Mode',
                  ThemeMode.dark => 'Dark Mode',
                  ThemeMode.system => 'System Default',
                }),
                trailing: mode == themeMode
                    ? const Icon(Icons.check_circle, color: _green)
                    : null,
                onTap: () => Navigator.pop(context, mode),
              ),
          ],
        ),
      ),
    );
    if (selected != null) onThemeChanged(selected);
  }

  Future<void> _manageCategories(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _CategoryManagerSheet(
        categories: categories,
        onAddCategory: onAddCategory,
      ),
    );
  }

  Future<void> _showAbout(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About PocketLedger'),
        content: const Text(
          'PocketLedger helps you keep track of your money in one simple place. '
          'Record income and expenses, then review your balance and spending by category. '
          'Your profile, preferences, and transactions are stored on your device. '
          'Export or restore your transactions as a CSV whenever you need a backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static String _currencyName(String code) {
    final currency = _currencies.firstWhere((entry) => entry.$1 == code);
    return '${currency.$1} (${currency.$2})';
  }

  static String _initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty);
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.tileBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.onTap,
    this.subtitle,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color tileBackground;
  final Color primaryText;
  final Color secondaryText;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Material(
        color: tileBackground,
        borderRadius: BorderRadius.circular(23),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(23),
          child: SizedBox(
            height: subtitle == null ? 84 : 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1B2A3E)
                          : const Color(0xFFF7F9FC),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF25364A)
                            : const Color(0xFFEDF1F6),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF36465D),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: primaryText,
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: secondaryText),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.name,
    required this.income,
    required this.currencyCode,
    required this.primaryText,
    required this.secondaryText,
  });

  final String name;
  final double income;
  final String currencyCode;
  final Color primaryText;
  final Color secondaryText;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final _nameController = TextEditingController(text: widget.name);
  late final _incomeController = TextEditingController(
    text: _formatMoney(widget.income),
  );

  @override
  void dispose() {
    _nameController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final income = double.tryParse(_incomeController.text.trim());
    if (name.isEmpty || income == null || income <= 0) return;
    Navigator.pop(context, (name, income));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Profile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _incomeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Monthly income',
              prefixText: '${widget.currencyCode} ',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _CategoryManagerSheet extends StatefulWidget {
  const _CategoryManagerSheet({
    required this.categories,
    required this.onAddCategory,
  });

  final List<LedgerCategory> categories;
  final Future<void> Function(LedgerCategory) onAddCategory;

  @override
  State<_CategoryManagerSheet> createState() => _CategoryManagerSheetState();
}

class _CategoryManagerSheetState extends State<_CategoryManagerSheet> {
  late final List<LedgerCategory> _categories = [...widget.categories];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Categories',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final category in _categories)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: category.color.withValues(alpha: 0.12),
                        child: Icon(category.icon, color: category.color),
                      ),
                      title: Text(category.name),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final category = await showDialog<LedgerCategory>(
                    context: context,
                    builder: (_) => const _AddCategoryDialog(),
                  );
                  if (category != null) {
                    final duplicate = _categories.any(
                      (entry) =>
                          entry.name.toLowerCase() ==
                          category.name.toLowerCase(),
                    );
                    if (!duplicate) {
                      await widget.onAddCategory(category);
                      if (mounted) setState(() => _categories.add(category));
                    }
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('Add category'),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  const _AddCategoryDialog();

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameController = TextEditingController();
  static const _icons = <IconData>[
    Icons.restaurant,
    Icons.directions_bus_filled_rounded,
    Icons.shopping_bag_outlined,
    Icons.school_rounded,
    Icons.receipt_long_outlined,
    Icons.favorite_border_rounded,
    Icons.tv_outlined,
    Icons.more_horiz_rounded,
    Icons.pets_outlined,
    Icons.fitness_center_rounded,
    Icons.flight_rounded,
    Icons.home_outlined,
  ];
  static const _colors = <Color>[
    Color(0xFFFF4545),
    Color(0xFFFF8A00),
    Color(0xFF6366F1),
    Color(0xFF3B82F6),
    Color(0xFF079B70),
    Color(0xFF8B5CF6),
    Color(0xFFEF476F),
    Color(0xFF64748B),
  ];
  int _selectedIcon = 0;
  int _selectedColor = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      LedgerCategory(
        name: name,
        icon: _icons[_selectedIcon],
        color: _colors[_selectedColor],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Category name'),
            ),
            const SizedBox(height: 18),
            const Text('Choose an icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var index = 0; index < _icons.length; index++)
                  IconButton(
                    onPressed: () => setState(() => _selectedIcon = index),
                    style: IconButton.styleFrom(
                      backgroundColor: _selectedIcon == index
                          ? _green.withValues(alpha: 0.14)
                          : null,
                    ),
                    color: _selectedIcon == index
                        ? _green
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    icon: Icon(_icons[index]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Choose a color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              children: [
                for (var index = 0; index < _colors.length; index++)
                  GestureDetector(
                    onTap: () => setState(() => _selectedColor = index),
                    child: Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: _colors[index],
                        shape: BoxShape.circle,
                        border: _selectedColor == index
                            ? Border.all(
                                color: Theme.of(context).colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.selectedIndex,
    required this.onSelected,
    required this.onAdd,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final inactive = colors.onSurfaceVariant;
    final items = [
      (Icons.home_rounded, 'Home'),
      (Icons.menu_rounded, 'Transactions'),
      (Icons.bar_chart_rounded, 'Reports'),
      (Icons.settings_outlined, 'Settings'),
    ];
    return Material(
      color: colors.surface,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 76,
          child: Row(
            children: [
              _navItem(0, items[0], inactive),
              _navItem(1, items[1], inactive),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: FloatingActionButton(
                      onPressed: onAdd,
                      elevation: 4,
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: const CircleBorder(),
                      child: const Icon(Icons.add, size: 40),
                    ),
                  ),
                ),
              ),
              _navItem(2, items[2], inactive),
              _navItem(3, items[3], inactive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, (IconData, String) item, Color inactive) {
    final selected = selectedIndex == index;
    final color = selected ? _green : inactive;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.$2,
        child: InkWell(
          onTap: () => onSelected(index),
          child: SizedBox(
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.$1, color: color, size: 25),
                const SizedBox(height: 3),
                Text(
                  item.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({
    super.key,
    required this.categories,
    required this.currencyCode,
  });

  final List<LedgerCategory> categories;
  final String currencyCode;

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isIncome = false;
  String? _category;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final category = _category ?? widget.categories.first.name;
    Navigator.of(context).pop(
      LedgerTransaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        amount: double.parse(_amountController.text.trim()),
        isIncome: _isIncome,
        category: _isIncome ? 'Income' : category,
        date: _date,
        note: _noteController.text.trim(),
      ),
    );
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (selected != null) setState(() => _date = selected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF091525)
        : const Color(0xFFF6F8FB);
    final cardColor = isDark ? const Color(0xFF142337) : Colors.white;
    final primary = isDark ? const Color(0xFFF4F7FC) : const Color(0xFF101C31);
    final secondary = isDark
        ? const Color(0xFF9AAAC0)
        : const Color(0xFF687B96);
    final accent = _isIncome ? _green : const Color(0xFFF34245);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: primary,
                        size: 22,
                      ),
                    ),
                  ),
                  Text(
                    'Add Transaction',
                    style: TextStyle(
                      color: primary,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    Container(
                      height: 62,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: cardColor.withValues(alpha: isDark ? 0.55 : 0.7),
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Row(
                        children: [
                          _typeChoice(
                            label: 'Expense',
                            value: false,
                            activeColor: const Color(0xFFF34245),
                            primary: primary,
                          ),
                          _typeChoice(
                            label: 'Income',
                            value: true,
                            activeColor: _green,
                            primary: primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 27),
                    _fieldLabel('Amount', secondary),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      style: TextStyle(color: primary, fontSize: 20),
                      decoration: _fieldDecoration(
                        hintText: '0.00',
                        cardColor: cardColor,
                        isDark: isDark,
                        primary: primary,
                        suffix: Text(
                          widget.currencyCode,
                          style: TextStyle(
                            color: primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');
                        return amount == null || amount <= 0
                            ? 'Enter an amount greater than zero'
                            : null;
                      },
                    ),
                    const SizedBox(height: 24),
                    _fieldLabel('Title', secondary),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(color: primary, fontSize: 17),
                      decoration: _fieldDecoration(
                        hintText: 'e.g. Lunch',
                        cardColor: cardColor,
                        isDark: isDark,
                        primary: primary,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a title'
                          : null,
                    ),
                    if (!_isIncome) ...[
                      const SizedBox(height: 25),
                      _fieldLabel('Category', secondary),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.categories.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 9,
                              mainAxisSpacing: 9,
                              mainAxisExtent: 91,
                            ),
                        itemBuilder: (context, index) {
                          final category = widget.categories[index];
                          final selected =
                              (_category ?? widget.categories.first.name) ==
                              category.name;
                          final categoryColor = category.color;
                          return InkWell(
                            onTap: () =>
                                setState(() => _category = category.name),
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              decoration: BoxDecoration(
                                color: cardColor,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selected
                                      ? accent
                                      : isDark
                                      ? const Color(0xFF25364A)
                                      : const Color(0xFFE3EAF2),
                                  width: selected ? 1.7 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? categoryColor.withValues(
                                              alpha: 0.10,
                                            )
                                          : (isDark
                                                ? const Color(0xFF1B2A3E)
                                                : const Color(0xFFF6F8FB)),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    child: Icon(
                                      category.icon,
                                      color: selected
                                          ? categoryColor
                                          : secondary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    child: Text(
                                      category.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected
                                            ? accent
                                            : primary.withValues(alpha: 0.85),
                                        fontSize: 11,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                    _fieldLabel('Date', secondary),
                    const SizedBox(height: 9),
                    Material(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          height: 58,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF25364A)
                                  : const Color(0xFFE3EAF2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat('MMM d, yyyy').format(_date),
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.calendar_month_outlined,
                                color: secondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _fieldLabel('Note (Optional)', secondary),
                    const SizedBox(height: 9),
                    TextField(
                      controller: _noteController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: 2,
                      style: TextStyle(color: primary),
                      decoration: _fieldDecoration(
                        hintText: 'Add a note...',
                        cardColor: cardColor,
                        isDark: isDark,
                        primary: primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 62,
                      child: FilledButton(
                        onPressed: _save,
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(19),
                          ),
                          elevation: isDark ? 0 : 2,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChoice({
    required String label,
    required bool value,
    required Color activeColor,
    required Color primary,
  }) {
    final selected = _isIncome == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isIncome = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : primary.withValues(alpha: 0.72),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String label, Color color) {
    return Text(label, style: TextStyle(color: color, fontSize: 14));
  }

  InputDecoration _fieldDecoration({
    required String hintText,
    required Color cardColor,
    required bool isDark,
    required Color primary,
    Widget? suffix,
  }) {
    final borderSide = BorderSide(
      color: isDark ? const Color(0xFF25364A) : const Color(0xFFE0E7F0),
    );
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: const Color(0xFF91A2BA), fontSize: 16),
      suffixIcon: suffix == null
          ? null
          : Padding(padding: const EdgeInsets.only(right: 18), child: suffix),
      suffixIconConstraints: const BoxConstraints(minHeight: 0),
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _green, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF34245)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFF34245), width: 1.4),
      ),
    );
  }
}
