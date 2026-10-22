import 'package:flutter/material.dart';

const _green = Color(0xFF079B70);

class NamePage extends StatefulWidget {
  const NamePage({super.key, required this.onContinue});

  final ValueChanged<String> onContinue;

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      widget.onContinue(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BrandMark(),
          const SizedBox(height: 32),
          Text(
            'Let’s get to know you',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'What should we call you?',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _continue(),
            decoration: const InputDecoration(
              labelText: 'Your name',
              hintText: 'e.g. Alex',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Please enter your name'
                : null,
          ),
          const SizedBox(height: 22),
          _ContinueButton(label: 'Continue', onPressed: _continue),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.eco, color: _green, size: 30),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
