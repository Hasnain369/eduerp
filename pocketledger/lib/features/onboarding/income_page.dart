import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _green = Color(0xFF079B70);

class IncomePage extends StatefulWidget {
  const IncomePage({super.key, required this.onComplete, required this.onBack});

  final ValueChanged<double> onComplete;
  final VoidCallback onBack;

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      widget.onComplete(double.parse(_controller.text.trim()));
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
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: _green,
              size: 28,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Your income',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'Add your monthly salary to get started.',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _continue(),
            decoration: const InputDecoration(
              labelText: 'Monthly salary',
              hintText: 'e.g. 3,500',
              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              suffixText: 'per month',
            ),
            validator: (value) {
              final amount = double.tryParse(value?.trim() ?? '');
              return amount == null || amount <= 0
                  ? 'Enter a salary greater than zero'
                  : null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _continue,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Finish setup'),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: widget.onBack,
              child: const Text('Back'),
            ),
          ),
        ],
      ),
    );
  }
}
