import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/locale_provider.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import 'widgets/school_auth_layout.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = await ref
        .read(authStateNotifierProvider.notifier)
        .registerTeacher(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          schoolInvitationCode: _invitationCodeController.text,
        );

    if (!mounted) return;
    if (user == null) return;

    final isUrdu = ref.read(appLocaleProvider).languageCode == 'ur';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isUrdu
              ? 'استاد کا اکاؤنٹ بن گیا۔ جاری رکھنے کے لیے پروفائل مکمل کریں۔'
              : 'Teacher account created. Complete your profile to continue.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRouter.teacherDashboard, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateNotifierProvider);
    final isUrdu = ref.watch(appLocaleProvider).languageCode == 'ur';

    return SchoolAuthLayout(
      title: isUrdu ? 'استاد کا اکاؤنٹ بنائیں' : 'Create teacher account',
      subtitle: isUrdu
          ? 'اساتذہ کے لیے رجسٹریشن۔ اکاؤنٹ اسکول منتظم کی منظوری سے فعال ہوگا۔'
          : 'Registration for educators. New accounts remain pending until approved by a school administrator.',
      maxWidth: 470,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FieldLabel(text: isUrdu ? 'پورا نام' : 'Full name'),
            const SizedBox(height: 5),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              validator: (value) => value == null || value.trim().isEmpty
                  ? (isUrdu ? 'پورا نام درج کریں' : 'Full name is required')
                  : null,
              decoration: schoolAuthInputDecoration(
                label: '',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(height: 10),
            _FieldLabel(text: isUrdu ? 'ای میل ایڈریس' : 'Email address'),
            const SizedBox(height: 5),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
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
            const SizedBox(height: 10),
            _FieldLabel(text: isUrdu ? 'پاس ورڈ' : 'Password'),
            const SizedBox(height: 5),
            TextFormField(
              controller: _passwordController,
              obscureText: !_showPassword,
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
            const SizedBox(height: 10),
            _FieldLabel(text: isUrdu ? 'پاس ورڈ کی تصدیق کریں' : 'Confirm password'),
            const SizedBox(height: 5),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: !_showConfirmPassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return isUrdu
                      ? 'پاس ورڈ کی تصدیق کریں'
                      : 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return isUrdu
                      ? 'پاس ورڈ ایک جیسے نہیں ہیں'
                      : 'Passwords do not match';
                }
                return null;
              },
              decoration: schoolAuthInputDecoration(
                label: '',
                icon: Icons.lock_reset_outlined,
                suffixIcon: IconButton(
                  tooltip: _showConfirmPassword
                      ? (isUrdu ? 'پاس ورڈ چھپائیں' : 'Hide confirmation')
                      : (isUrdu ? 'پاس ورڈ دکھائیں' : 'Show confirmation'),
                  onPressed: () => setState(
                    () => _showConfirmPassword = !_showConfirmPassword,
                  ),
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 19,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _FieldLabel(
              text: isUrdu
                  ? 'اسکول دعوتی کوڈ (اختیاری)'
                  : 'School invitation code (optional)',
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: _invitationCodeController,
              decoration: schoolAuthInputDecoration(
                label: '',
                icon: Icons.vpn_key_outlined,
              ),
            ),
            if (authState.errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0DF),
                  border: Border.all(color: const Color(0xFFFFB6B2)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  authState.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 13),
            schoolAuthPrimaryButton(
              label: authState.isLoading
                  ? (isUrdu ? 'اکاؤنٹ بنایا جا رہا ہے…' : 'Creating account…')
                  : (isUrdu ? 'سائن اپ' : 'Sign up'),
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
            const SizedBox(height: 4),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.login,
                    (route) => false,
                  ),
              child: Text(isUrdu ? 'لاگ اِن پر واپس جائیں' : 'Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF292A32),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
