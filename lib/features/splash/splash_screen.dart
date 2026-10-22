import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _dotsController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late AnimationController _bgCircleController;

  // Logo animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;

  // Text animations
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;
  late Animation<double> _urduOpacity;
  late Animation<Offset> _urduSlide;

  // Progress animations
  late Animation<double> _progressValue;
  late Animation<double> _progressOpacity;

  // Dots animation
  late Animation<double> _dot1Scale;
  late Animation<double> _dot2Scale;
  late Animation<double> _dot3Scale;

  // Sparkle animation
  late Animation<double> _sparkleOpacity;
  late Animation<double> _sparkleScale;
  late Animation<double> _sparkleRotation;

  // Background circle animation
  late Animation<double> _bgCircleScale;

  // Loading text cycling
  final List<String> _loadingTexts = [
    'Loading classroom...',
    'Preparing lessons...',
    'Getting things ready...',
  ];
  int _loadingTextIndex = 0;
  Timer? _loadingTextTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _cycleLoadingText();

    // Navigate after splash duration
    Future.delayed(const Duration(milliseconds: 4500), () {
      _navigate();
    });
  }

  void _initAnimations() {
    // Background circle controller
    _bgCircleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _bgCircleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgCircleController, curve: Curves.easeOut),
    );

    // Logo controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Sparkle controller
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _sparkleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 30),
    ]).animate(_sparkleController);
    _sparkleScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 60),
    ]).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeOut),
    );
    _sparkleRotation = Tween<double>(begin: -0.2, end: 0.2).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    // Text controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.25, 0.75, curve: Curves.easeIn),
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.25, 0.85, curve: Curves.easeOut),
      ),
    );
    _urduOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _urduSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // Progress controller
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    _progressValue = Tween<double>(begin: 0.0, end: 0.72).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
    _progressOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // Dots controller
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    _dot1Scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: const Interval(0.0, 0.33, curve: Curves.easeInOut),
      ),
    );
    _dot2Scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: const Interval(0.33, 0.66, curve: Curves.easeInOut),
      ),
    );
    _dot3Scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: const Interval(0.66, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Pulse controller
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  void _startAnimations() async {
    // Start background circle immediately
    _bgCircleController.forward();

    // Logo appears first
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _logoController.forward();

    // Sparkle after logo appears
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _sparkleController.forward();

    // Text fades in after logo
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) _textController.forward();

    // Progress bar starts
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) _progressController.forward();
  }

  void _cycleLoadingText() {
    _loadingTextTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (mounted) {
        setState(() {
          _loadingTextIndex = (_loadingTextIndex + 1) % _loadingTexts.length;
        });
      }
    });
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    try {
      final authNotifier = ref.read(authStateNotifierProvider.notifier);
      await authNotifier.initialize();

      if (!mounted) return;

      final authState = ref.read(authStateNotifierProvider);
      final destination = authState.isAuthenticated && authState.user != null
          ? switch (authState.user!.role.toLowerCase()) {
              'admin' => AppRouter.adminDashboard,
              'teacher' => AppRouter.teacherDashboard,
              _ => AppRouter.studentDashboard,
            }
          : AppRouter.login;

      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(destination, (route) => false);
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _dotsController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    _bgCircleController.dispose();
    _loadingTextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A3A8F),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A3A8F),
                  Color(0xFF1E3FA0),
                  Color(0xFF1A3A8F),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Subtle geometric circle patterns (background)
          AnimatedBuilder(
            animation: _bgCircleController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size.width, size.height),
                painter: _BackgroundCirclesPainter(
                  progress: _bgCircleScale.value,
                  pulse: _pulseController.value,
                ),
              );
            },
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo section
                _buildLogoSection(),

                const SizedBox(height: 28),

                // Title & subtitles
                _buildTextSection(),

                const Spacer(flex: 3),

                // Loading section
                _buildLoadingSection(),

                const SizedBox(height: 24),

                // Footer
                _buildFooter(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _sparkleController]),
      builder: (context, child) {
        return SlideTransition(
          position: _logoSlide,
          child: FadeTransition(
            opacity: _logoOpacity,
            child: ScaleTransition(
              scale: _logoScale,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // White rounded box
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 30,
                          spreadRadius: 2,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: const Color(0xFF3B6FE0).withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: -4,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: const _GraduationCapIcon(),
                      ),
                    ),
                  ),

                  // Sparkle star top-right
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Transform.rotate(
                      angle: _sparkleRotation.value,
                      child: Opacity(
                        opacity: _sparkleOpacity.value,
                        child: Transform.scale(
                          scale: _sparkleScale.value,
                          child: const _SparkleIcon(
                            size: 24,
                            color: Color(0xFFFFCC33),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextSection() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return Column(
          children: [
            // App name
            SlideTransition(
              position: _titleSlide,
              child: FadeTransition(
                opacity: _titleOpacity,
                child: const Text(
                  'Educative',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    height: 1.1,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // English subtitle
            SlideTransition(
              position: _subtitleSlide,
              child: FadeTransition(
                opacity: _subtitleOpacity,
                child: Text(
                  'Learn. Teach. Grow.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Urdu subtitle
            SlideTransition(
              position: _urduSlide,
              child: FadeTransition(
                opacity: _urduOpacity,
                child: Text(
                  'سیکھیں، سکھائیں، آگے بڑھیں',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontSize: 20,
                    fontFamily: 'NotoNastaliqUrdu',
                    fontWeight: FontWeight.w600,
                    height: 1.8,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingSection() {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _dotsController]),
      builder: (context, child) {
        return FadeTransition(
          opacity: _progressOpacity,
          child: Column(
            children: [
              // Loading text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _loadingTexts[_loadingTextIndex],
                  key: ValueKey(_loadingTextIndex),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Stack(
                  children: [
                    // Track
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Fill
                    AnimatedBuilder(
                      animation: _progressController,
                      builder: (context, _) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return Container(
                              height: 4,
                              width:
                                  constraints.maxWidth * _progressValue.value,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFAA00),
                                    Color(0xFFFFCC33),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFAA00)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Animated dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(_dot1Scale.value, const Color(0xFFFFAA00)),
                  const SizedBox(width: 8),
                  _buildDot(
                      _dot2Scale.value, Colors.white.withValues(alpha: 0.5)),
                  const SizedBox(width: 8),
                  _buildDot(
                      _dot3Scale.value, Colors.white.withValues(alpha: 0.5)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDot(double scale, Color color) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return AnimatedBuilder(
      animation: _textController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _urduOpacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Divider(
                  color: Colors.white.withValues(alpha: 0.15),
                  thickness: 0.8,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Made for Punjab schools',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '  •  ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11.5,
                      ),
                    ),
                    Text(
                      'پنجاب کے اسکولوں کے لیے تیار کردہ',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11.5,
                        fontFamily: 'NotoNastaliqUrdu',
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'v1.0.0',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '  •  ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'Punjab Taleem Portal (SED)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.50),
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Custom graduation cap icon painter
// ─────────────────────────────────────────────
class _GraduationCapIcon extends StatelessWidget {
  const _GraduationCapIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, double.infinity),
      painter: _GradCapPainter(),
    );
  }
}

class _GradCapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Colors
    const darkBlue = Color(0xFF1A3A8F);
    const medBlue = Color(0xFF2B5CE6);
    const goldColor = Color(0xFFFFCC33);

    // ── Open book base ──
    // Left page of book
    final leftBook = Path()
      ..moveTo(w * 0.14, h * 0.56)
      ..quadraticBezierTo(w * 0.10, h * 0.48, w * 0.12, h * 0.42)
      ..lineTo(w * 0.48, h * 0.50)
      ..lineTo(w * 0.48, h * 0.72)
      ..quadraticBezierTo(w * 0.28, h * 0.68, w * 0.14, h * 0.56)
      ..close();
    canvas.drawPath(leftBook, Paint()..color = medBlue);

    // Right page of book
    final rightBook = Path()
      ..moveTo(w * 0.86, h * 0.56)
      ..quadraticBezierTo(w * 0.90, h * 0.48, w * 0.88, h * 0.42)
      ..lineTo(w * 0.52, h * 0.50)
      ..lineTo(w * 0.52, h * 0.72)
      ..quadraticBezierTo(w * 0.72, h * 0.68, w * 0.86, h * 0.56)
      ..close();
    canvas.drawPath(rightBook, Paint()..color = const Color(0xFF2B5CE6));

    // Book spine line
    canvas.drawLine(
      Offset(w * 0.50, h * 0.42),
      Offset(w * 0.50, h * 0.72),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );

    // ── Mortarboard cap (flat top) ──
    final capPath = Path()
      ..moveTo(w * 0.50, h * 0.14) // top
      ..lineTo(w * 0.88, h * 0.34) // right
      ..lineTo(w * 0.50, h * 0.44) // bottom
      ..lineTo(w * 0.12, h * 0.34) // left
      ..close();
    canvas.drawPath(capPath, Paint()..color = darkBlue);

    // Cap top highlight
    final highlightPath = Path()
      ..moveTo(w * 0.50, h * 0.14)
      ..lineTo(w * 0.88, h * 0.34)
      ..lineTo(w * 0.68, h * 0.38)
      ..lineTo(w * 0.50, h * 0.20)
      ..lineTo(w * 0.32, h * 0.38)
      ..lineTo(w * 0.12, h * 0.34)
      ..close();
    canvas.drawPath(
      highlightPath,
      Paint()..color = Colors.white.withValues(alpha: 0.12),
    );

    // ── Tassel ──
    // Rope going from right side down
    final tasselPath = Path()
      ..moveTo(w * 0.76, h * 0.36);
    tasselPath.cubicTo(
      w * 0.80, h * 0.42,
      w * 0.78, h * 0.52,
      w * 0.76, h * 0.58,
    );
    canvas.drawPath(
      tasselPath,
      Paint()
        ..color = goldColor
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    // Tassel end blob
    canvas.drawCircle(
      Offset(w * 0.76, h * 0.62),
      w * 0.048,
      Paint()..color = goldColor,
    );

    // Small tassel fringe lines
    final fringePaint = Paint()
      ..color = goldColor
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final angle = -math.pi / 4 + (i * math.pi / 6);
      final cx = w * 0.76 + math.cos(angle) * w * 0.048;
      final cy = h * 0.62 + math.sin(angle) * h * 0.048;
      canvas.drawLine(
        Offset(cx, cy),
        Offset(
          cx + math.cos(angle) * w * 0.04,
          cy + math.sin(angle) * h * 0.05,
        ),
        fringePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// Sparkle / star icon
// ─────────────────────────────────────────────
class _SparkleIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _SparkleIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SparklePainter(color: color),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final Color color;
  const _SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r1 = size.width * 0.48;
    final r2 = size.width * 0.18;
    const arms = 4;

    final path = Path();
    for (int i = 0; i < arms * 2; i++) {
      final angle = (math.pi / arms) * i - math.pi / 2;
      final r = i.isEven ? r1 : r2;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────
// Background geometric circles painter
// ─────────────────────────────────────────────
class _BackgroundCirclesPainter extends CustomPainter {
  final double progress;
  final double pulse;

  const _BackgroundCirclesPainter({required this.progress, required this.pulse});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.36;

    // Draw concentric circles with subtle opacity
    final radii = [
      size.width * 0.38,
      size.width * 0.55,
      size.width * 0.72,
    ];
    for (final r in radii) {
      canvas.drawCircle(
        Offset(cx, cy),
        r * progress,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color =
              Colors.white.withValues(alpha: (0.06 + pulse * 0.03) * progress),
      );
    }

    // Cross lines (compass-like)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 * progress)
      ..strokeWidth = 0.7;

    final maxR = size.width * 0.75 * progress;
    // Horizontal
    canvas.drawLine(Offset(cx - maxR, cy), Offset(cx + maxR, cy), linePaint);
    // Vertical
    canvas.drawLine(Offset(cx, cy - maxR), Offset(cx, cy + maxR), linePaint);
    // Diagonals
    final d = maxR * 0.7;
    canvas.drawLine(
        Offset(cx - d, cy - d), Offset(cx + d, cy + d), linePaint);
    canvas.drawLine(
        Offset(cx + d, cy - d), Offset(cx - d, cy + d), linePaint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundCirclesPainter old) =>
      old.progress != progress || old.pulse != pulse;
}
