import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _goToOnboarding() {
    Navigator.pushNamed(context, AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Bus hero image
                Hero(
                  tag: 'busHero',
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.38,
                    child: const _TopViewBus(),
                  ),
                ),

                const SizedBox(height: 36),

                // CITYRUNNER logo
                RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'CITY'),
                      TextSpan(
                        text: 'RUNNER',
                        style: TextStyle(color: AppTheme.accent),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  AppConstants.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 3),

                // Page indicators
                const PageIndicators(count: 3, current: 0),

                const SizedBox(height: 28),

                // Let's Go button
                _LetsGoButton(onPressed: _goToOnboarding),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Top-view luxury bus drawn with CustomPainter ────────────────────────────
class _TopViewBus extends StatelessWidget {
  const _TopViewBus();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TopViewBusPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _TopViewBusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * 0.88), width: w * 0.55, height: h * 0.08),
      shadowPaint,
    );

    // Body
    final bodyPaint = Paint()..color = Colors.white;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.04, w * 0.56, h * 0.82),
      const Radius.circular(28),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Roof panel (slightly darker)
    final roofPaint = Paint()..color = const Color(0xFFE8E8E8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.26, h * 0.08, w * 0.48, h * 0.72),
        const Radius.circular(22),
      ),
      roofPaint,
    );

    // Orange accent stripe
    final stripePaint = Paint()..color = AppTheme.accent;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.22, h * 0.38, w * 0.56, h * 0.06),
      stripePaint,
    );

    // Windows – left column
    final windowPaint = Paint()..color = const Color(0xFF1A2530);
    final windowHighlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final windowPositions = [0.10, 0.20, 0.50, 0.60, 0.70];
    for (final yFrac in windowPositions) {
      final wr = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.27, h * yFrac, w * 0.20, h * 0.07),
        const Radius.circular(5),
      );
      canvas.drawRRect(wr, windowPaint);
      canvas.drawRRect(wr, windowHighlight);

      final wr2 = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.53, h * yFrac, w * 0.20, h * 0.07),
        const Radius.circular(5),
      );
      canvas.drawRRect(wr2, windowPaint);
      canvas.drawRRect(wr2, windowHighlight);
    }

    // Front windshield
    final windshieldPaint = Paint()..color = const Color(0xFF1A2530);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.79, w * 0.40, h * 0.05),
        const Radius.circular(6),
      ),
      windshieldPaint,
    );

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF1A1A1A);
    final wheelHighlightPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final wheels = [
      Offset(w * 0.22, h * 0.22),
      Offset(w * 0.78, h * 0.22),
      Offset(w * 0.22, h * 0.65),
      Offset(w * 0.78, h * 0.65),
    ];
    for (final wh in wheels) {
      canvas.drawCircle(wh, w * 0.07, wheelPaint);
      canvas.drawCircle(wh, w * 0.07, wheelHighlightPaint);
      canvas.drawCircle(wh, w * 0.03, Paint()..color = const Color(0xFF444444));
    }

    // Center line detail
    final linePaint = Paint()
      ..color = const Color(0xFFD0D0D0)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(w * 0.50, h * 0.08),
      Offset(w * 0.50, h * 0.80),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Let's Go button ─────────────────────────────────────────────────────────
class _LetsGoButton extends StatefulWidget {
  const _LetsGoButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_LetsGoButton> createState() => _LetsGoButtonState();
}

class _LetsGoButtonState extends State<_LetsGoButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Let's Go",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 12),
              Icon(
                Icons.directions_bus_rounded,
                color: Colors.black,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}