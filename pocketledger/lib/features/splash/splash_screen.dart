import 'package:flutter/material.dart';

const _green = Color(0xFF079B70);
const _mint = Color(0xFF36C99C);
const _navy = Color(0xFF101C31);
const _splashDuration = Duration(milliseconds: 1400);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: _splashDuration,
    )..forward();
    _continueAfterSplash();
  }

  Future<void> _continueAfterSplash() async {
    await Future<void>.delayed(_splashDuration);
    if (mounted) widget.onContinue();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark ? const Color(0xFFF2F8F5) : _navy;
    final secondary = isDark
        ? const Color(0xFFA8BDB5)
        : const Color(0xFF465B6B);
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F211B)
          : const Color(0xFFF5FBF9),
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.05),
                radius: 1.15,
                colors: isDark
                    ? const [Color(0xFF174D3E), Color(0xFF0F211B)]
                    : const [Color(0xFFD2F8E9), Color(0xFFF5FBF9)],
                stops: const [0, 1],
              ),
            ),
          ),
          Positioned.fill(
            child: CustomPaint(painter: _SplashWavesPainter(isDark: isDark)),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 4),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      key: const Key('splash-logo'),
                      width: 136,
                      height: 136,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFFDAFFF1)
                            : const Color(0xFFF9FFFC),
                        borderRadius: BorderRadius.circular(37),
                        boxShadow: [
                          BoxShadow(
                            color: _green.withValues(
                              alpha: isDark ? 0.2 : 0.16,
                            ),
                            blurRadius: 48,
                            spreadRadius: 5,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [_green, _mint],
                          ),
                          borderRadius: BorderRadius.circular(29),
                        ),
                        child: const Center(
                          child: CustomPaint(
                            size: Size(68, 68),
                            painter: _SplashLeafPainter(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 29),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(
                          color: foreground,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                        children: const [
                          TextSpan(text: 'Pocket'),
                          TextSpan(
                            text: 'Ledger',
                            style: TextStyle(color: _green),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Better Decisions. Brighter Future.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 5),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 114,
                      height: 6,
                      child: AnimatedBuilder(
                        animation: _loadingController,
                        builder: (context, child) => Stack(
                          clipBehavior: Clip.hardEdge,
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF275A49)
                                      : const Color(0xFFBCEFD9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _loadingController.value,
                                heightFactor: 1,
                                child: child,
                              ),
                            ),
                          ],
                        ),
                        child: DecoratedBox(
                          key: const Key('splash-progress-highlight'),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_green, _mint],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 17),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF183B30)
                            : const Color(0xFFF5FFFB),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2D5748)
                              : const Color(0xFFD8F3E7),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.health_and_safety_rounded,
                            color: _green,
                            size: 14,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'Bank-Grade Security • v1.0.0',
                            style: TextStyle(
                              color: secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashLeafPainter extends CustomPainter {
  const _SplashLeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final leaf = Path()
      ..moveTo(size.width * 0.12, size.height * 0.83)
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.42,
        size.width * 0.43,
        size.height * 0.10,
        size.width * 0.89,
        size.height * 0.08,
      )
      ..cubicTo(
        size.width * 0.87,
        size.height * 0.53,
        size.width * 0.56,
        size.height * 0.85,
        size.width * 0.12,
        size.height * 0.83,
      )
      ..close();
    canvas.drawPath(leaf, Paint()..color = Colors.white);
    canvas.drawLine(
      Offset(size.width * 0.17, size.height * 0.78),
      Offset(size.width * 0.68, size.height * 0.27),
      Paint()
        ..color = _green
        ..strokeWidth = size.width * 0.065
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SplashLeafPainter oldDelegate) => false;
}

class _SplashWavesPainter extends CustomPainter {
  const _SplashWavesPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final top = size.height - 94;
    final backWave = Path()
      ..moveTo(0, top + 20)
      ..cubicTo(
        size.width * 0.25,
        top + 39,
        size.width * 0.68,
        top - 3,
        size.width,
        top + 12,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      backWave,
      Paint()
        ..color = isDark ? const Color(0xFF153B30) : const Color(0xFFE4F9F0),
    );

    final frontWave = Path()
      ..moveTo(0, top + 34)
      ..cubicTo(
        size.width * 0.29,
        top + 16,
        size.width * 0.67,
        top + 45,
        size.width,
        top + 25,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      frontWave,
      Paint()
        ..color = isDark ? const Color(0xFF17483A) : const Color(0xFFD9F7EC),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashWavesPainter oldDelegate) {
    return oldDelegate.isDark != isDark;
  }
}
