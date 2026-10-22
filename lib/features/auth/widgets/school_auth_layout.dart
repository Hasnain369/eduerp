import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/locale_provider.dart';

const _ink = Color(0xFF282A36);
const _indigo = Color(0xFF3949AB);
const _muted = Color(0xFF77798A);

class SchoolAuthLayout extends StatelessWidget {
  const SchoolAuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.maxWidth = 470,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 12.0 : 22.0;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 12,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _AuthorityHeader(),
                        const SizedBox(height: 16),
                        const _SchoolBrand(),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 21,
                            height: 1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(
                            constraints.maxWidth < 380 ? 12 : 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE9E9EF),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A25294A),
                                blurRadius: 16,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: child,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AuthorityHeader extends ConsumerWidget {
  const _AuthorityHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUrdu = ref.watch(appLocaleProvider).languageCode == 'ur';
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Color(0xFFE9EAF8),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.account_balance, color: _indigo, size: 17),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Govt. of Punjab',
                style: TextStyle(
                  color: _ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              Text(
                'School Education Dept',
                style: TextStyle(color: _muted, fontSize: 9, height: 1.3),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F3F7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE6E6EC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguageOption(
                label: 'EN',
                selected: !isUrdu,
                onTap: () => ref.read(appLocaleProvider.notifier).state =
                    const Locale('en'),
              ),
              _LanguageOption(
                label: 'اردو',
                selected: isUrdu,
                onTap: () => ref.read(appLocaleProvider.notifier).state =
                    const Locale('ur'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? _indigo : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _ink,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SchoolBrand extends StatelessWidget {
  const _SchoolBrand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _indigo,
                borderRadius: BorderRadius.circular(13),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x263949AB),
                    blurRadius: 9,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Colors.white,
                size: 31,
              ),
            ),
            Positioned(
              bottom: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB21D),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Text(
                  'Punjab',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 9,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        const Text(
          'Educative',
          style: TextStyle(
            color: _indigo,
            fontSize: 20,
            height: 1.3,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 1),
        const Text(
          "Empowering Punjab's Classrooms • تعلیم سب کے لیے",
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 9, height: 1.6),
        ),
      ],
    );
  }
}

class SchoolAuthRoleSelector extends StatelessWidget {
  const SchoolAuthRoleSelector({
    super.key,
    required this.selectedRole,
    required this.onChanged,
    required this.isUrdu,
  });

  final bool selectedRole;
  final ValueChanged<bool> onChanged;
  final bool isUrdu;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _roleOption(
            value: false,
            label: isUrdu ? 'طالب علم / Student' : 'Student / طالب علم',
            icon: Icons.person_outline,
          ),
          _roleOption(
            value: true,
            label: isUrdu ? 'استاد / Teacher' : 'Teacher / استاد',
            icon: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }

  Widget _roleOption({
    required bool value,
    required String label,
    required IconData icon,
  }) {
    final selected = selectedRole == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? _indigo : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : _muted),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : _ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration schoolAuthInputDecoration({
  required String label,
  required IconData icon,
  String? helperText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label.isEmpty ? null : label,
    helperText: helperText,
    helperStyle: const TextStyle(color: _muted, fontSize: 10),
    prefixIcon: Icon(icon, size: 19, color: const Color(0xFF55596B)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF4F4F7),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFE3E3E9)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFE3E3E9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: _indigo, width: 1.3),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFE44848)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: Color(0xFFE44848), width: 1.3),
    ),
  );
}

Widget schoolAuthPrimaryButton({
  required String label,
  required VoidCallback? onPressed,
  Widget? icon,
}) {
  return SizedBox(
    height: 46,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: _indigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (icon != null) ...[const SizedBox(width: 8), icon],
        ],
      ),
    ),
  );
}
