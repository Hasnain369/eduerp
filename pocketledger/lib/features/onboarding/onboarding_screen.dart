import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'income_page.dart';
import 'name_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String? _name;
  bool _isSaving = false;

  Future<void> _complete(double income) async {
    setState(() => _isSaving = true);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('profile_name', _name!);
    await preferences.setString('profile_salary', income.toString());
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : _name == null
                  ? NamePage(onContinue: (name) => setState(() => _name = name))
                  : IncomePage(
                      onComplete: _complete,
                      onBack: () => setState(() => _name = null),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
