import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import 'widgets/school_auth_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _teacherSelected = false;
  String? _statusMessage;
  bool _resetEmailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _statusMessage = null;
      _resetEmailSent = false;
    });
    final user = await ref
        .read(authStateNotifierProvider.notifier)
        .login(_emailController.text, _passwordController.text);

    if (!mounted) return;
    if (user == null) return;

    final destination = switch (user.role.toLowerCase()) {
      'admin' => AppRouter.adminDashboard,
      'teacher' => AppRouter.teacherDashboard,
      _ => AppRouter.studentDashboard,
    };
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(destination, (route) => false);
  }

  Future<void> _sendPasswordResetEmail() async {
    final isUrdu = ref.read(appLocaleProvider).languageCode == 'ur';
    setState(() {
      _statusMessage = null;
      _resetEmailSent = false;
    });
    final sent = await ref
        .read(authStateNotifierProvider.notifier)
        .sendPasswordResetEmail(_emailController.text);
    if (!mounted) return;
    if (sent) {
      setState(() {
        _statusMessage = isUrdu
            ? 'پاس ورڈ ری سیٹ کرنے کا لنک آپ کے ای میل پر بھیج دیا گیا ہے۔'
            : 'A password reset link has been sent to your email.';
        _resetEmailSent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final isUrdu = ref.watch(appLocaleProvider).languageCode == 'ur';
    final errorMessage = authState.errorMessage ?? _statusMessage;

    return SchoolAuthLayout(
      title: isUrdu ? 'خوش آمدید' : 'Welcome Back (خوش آمدید)',
      subtitle: isUrdu
          ? 'اپنی کلاسوں، نصاب، حاضری اور رپورٹ کارڈز تک رسائی حاصل کریں۔'
          : 'Sign in to access your classes, syllabus,\nattendance & report cards.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SchoolAuthRoleSelector(
              selectedRole: _teacherSelected,
              isUrdu: isUrdu,
              onChanged: (teacher) =>
                  setState(() => _teacherSelected = teacher),
            ),
            const SizedBox(height: 14),
            Text(
              isUrdu ? 'ای میل ایڈریس' : 'Email address',
              style: const TextStyle(
                color: Color(0xFF292A32),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return isUrdu ? 'ای میل درج کریں' : 'Email is required';
                }
                if (!value.contains('@')) {
                  return isUrdu
                      ? 'درست ای میل ایڈریس درج کریں'
                      : 'Enter a valid email address';
                }
                return null;
              },
              decoration: schoolAuthInputDecoration(
                label: '',
                icon: Icons.email_outlined,
              ),
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isUrdu ? 'پاس ورڈ' : 'Password',
                    style: const TextStyle(
                      color: Color(0xFF292A32),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: authState.isLoading
                      ? null
                      : _sendPasswordResetEmail,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFF263AA6),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(
                    isUrdu ? 'پاس ورڈ بھول گئے؟' : 'Forgot? / بھول گئے؟',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
              autofillHints: const [AutofillHints.password],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isUrdu ? 'پاس ورڈ درج کریں' : 'Password is required';
                }
                if (value.length < 6) {
                  return isUrdu
                      ? 'کم از کم 6 حروف درج کریں'
                      : 'Use at least 6 characters';
                }
                return null;
              },
              decoration: schoolAuthInputDecoration(
                label: '',
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  tooltip: _showPassword
                      ? (isUrdu ? 'پاس ورڈ چھپائیں' : 'Hide password')
                      : (isUrdu ? 'پاس ورڈ دکھائیں' : 'Show password'),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                  ),
                ),
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 11),
              _AuthMessage(message: errorMessage, isSuccess: _resetEmailSent),
            ],
            const SizedBox(height: 14),
            schoolAuthPrimaryButton(
              label: isUrdu ? 'لاگ اِن کریں' : 'Log in',
              onPressed: authState.isLoading ? null : _submit,
              icon: authState.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_forward, size: 17),
            ),
            const SizedBox(height: 9),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    isUrdu ? 'اکاؤنٹ نہیں ہے؟ ' : 'Don’t have an account? ',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Color(0xFF626575),
                      fontSize: 11,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pushNamed(AppRouter.registerTeacher),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFF263AA6),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(isUrdu ? 'سائن اپ' : 'Sign up'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? const Color(0xFF30805A) : const Color(0xFFE44848);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFE8F5EC) : const Color(0xFFFFE0DF),
        border: Border.all(
          color: isSuccess ? const Color(0xFFB9DFC5) : const Color(0xFFFFB6B2),
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 10,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
