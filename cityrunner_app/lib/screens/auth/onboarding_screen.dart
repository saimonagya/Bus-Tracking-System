import 'package:flutter/material.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Onboarding data
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingPage {
  const _OnboardingPage({
    required this.heading,
    required this.subtitle,
    required this.routeVariant,
  });

  final String heading;
  final String subtitle;
  final int routeVariant; // 0, 1, 2
}

const _pages = [
  _OnboardingPage(
    heading: 'Track. Book. Ride.',
    subtitle: 'Live tracking, easy booking\nand safe journeys.',
    routeVariant: 0,
  ),
  _OnboardingPage(
    heading: 'Choose Your Seat.',
    subtitle: 'Reserve your preferred seat\nbefore boarding.',
    routeVariant: 1,
  ),
  _OnboardingPage(
    heading: 'Travel Smart.',
    subtitle: 'Fast booking. Real-time updates.\nSecure payments.',
    routeVariant: 2,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// OnboardingScreen
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _busController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _busController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _busController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _skip() =>
      Navigator.pushReplacementNamed(context, AppRoutes.roleSelection);

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _skip();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Animated map background (shared across pages)
          Positioned.fill(
            child: CustomPaint(
              painter: _OnboardingMapPainter(
                animation: _busController,
                variant: _currentPage,
              ),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.background.withValues(alpha: 0.02),
                      AppTheme.background.withValues(alpha: 0.06),
                      AppTheme.background.withValues(alpha: 0.82),
                      AppTheme.background,
                    ],
                    stops: const [0, 0.40, 0.70, 1],
                  ),
                ),
              ),
            ),
          ),

          // PageView for copy
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 148),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          page.heading,
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontFamily: 'Poppins',
                            fontSize: 34,
                            height: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          page.subtitle,
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            height: 1.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom navigation bar
          Positioned(
            left: 24,
            right: 24,
            bottom: 36,
            child: Row(
              children: [
                // Skip
                GestureDetector(
                  onTap: _skip,
                  child: const SizedBox(
                    width: 72,
                    height: 50,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: AppTheme.muted,
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Indicators
                PageIndicators(count: _pages.length, current: _currentPage),

                const Spacer(),

                // Next / Get Started
                _OnboardingNextButton(
                  isLast: isLast,
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Next button ─────────────────────────────────────────────────────────────
class _OnboardingNextButton extends StatefulWidget {
  const _OnboardingNextButton({
    required this.isLast,
    required this.onPressed,
  });

  final bool isLast;
  final VoidCallback onPressed;

  @override
  State<_OnboardingNextButton> createState() => _OnboardingNextButtonState();
}

class _OnboardingNextButtonState extends State<_OnboardingNextButton> {
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
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: widget.isLast ? 130 : 72,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFA229), AppTheme.accent],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.22),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: widget.isLast
              ? const Center(
                  child: Text(
                    'Get Started',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map painter with 3 route variants
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingMapPainter extends CustomPainter {
  _OnboardingMapPainter({
    required this.animation,
    required this.variant,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final int variant;

  static const _road = AppTheme.elevated;
  static const _divider = Color(0xFF2B2B2B);

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintRoads(canvas, size);
    _paintRoute(canvas, size);
    _paintMarkers(canvas, size);
    _paintBus(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppTheme.background,
    );
    final gridPaint = Paint()
      ..color = _divider.withValues(alpha: 0.30)
      ..strokeWidth = 1;
    for (var x = -40.0; x < size.width + 80; x += 88) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.width * 0.28, size.height),
        gridPaint,
      );
    }
    for (var y = 58.0; y < size.height * 0.78; y += 96) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 36), gridPaint);
    }
  }

  void _paintRoads(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = _road.withValues(alpha: 0.85)
      ..strokeWidth = 20;
    final linePaint = Paint()
      ..isAntiAlias = true
      ..color = _divider.withValues(alpha: 0.9)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final roads = <Path>[
      Path()
        ..moveTo(-size.width * 0.08, size.height * 0.18)
        ..cubicTo(size.width * 0.22, size.height * 0.12, size.width * 0.35,
            size.height * 0.32, size.width * 0.68, size.height * 0.27)
        ..cubicTo(size.width * 0.9, size.height * 0.24, size.width * 0.92,
            size.height * 0.08, size.width * 1.12, size.height * 0.1),
      Path()
        ..moveTo(size.width * 0.1, -size.height * 0.04)
        ..cubicTo(size.width * 0.2, size.height * 0.22, size.width * 0.18,
            size.height * 0.34, size.width * 0.32, size.height * 0.58)
        ..cubicTo(size.width * 0.45, size.height * 0.78, size.width * 0.46,
            size.height * 0.92, size.width * 0.54, size.height * 1.08),
      Path()
        ..moveTo(-size.width * 0.12, size.height * 0.56)
        ..cubicTo(size.width * 0.2, size.height * 0.46, size.width * 0.5,
            size.height * 0.5, size.width * 0.72, size.height * 0.43)
        ..cubicTo(size.width * 0.92, size.height * 0.36, size.width * 0.96,
            size.height * 0.3, size.width * 1.08, size.height * 0.28),
      Path()
        ..moveTo(size.width * 0.78, -size.height * 0.08)
        ..cubicTo(size.width * 0.7, size.height * 0.2, size.width * 0.82,
            size.height * 0.42, size.width * 0.72, size.height * 0.62)
        ..cubicTo(size.width * 0.64, size.height * 0.8, size.width * 0.8,
            size.height * 0.92, size.width * 0.98, size.height * 1.1),
    ];

    for (final road in roads) {
      canvas.drawPath(road, roadPaint);
      canvas.drawPath(road, linePaint);
    }
  }

  Path _routePath(Size size) {
    switch (variant) {
      case 1:
        return Path()
          ..moveTo(size.width * 0.15, size.height * 0.45)
          ..cubicTo(size.width * 0.3, size.height * 0.2, size.width * 0.55,
              size.height * 0.15, size.width * 0.65, size.height * 0.35)
          ..cubicTo(size.width * 0.75, size.height * 0.55, size.width * 0.88,
              size.height * 0.48, size.width * 0.85, size.height * 0.25);
      case 2:
        return Path()
          ..moveTo(size.width * 0.12, size.height * 0.55)
          ..cubicTo(size.width * 0.25, size.height * 0.35, size.width * 0.4,
              size.height * 0.22, size.width * 0.58, size.height * 0.28)
          ..cubicTo(size.width * 0.76, size.height * 0.34, size.width * 0.85,
              size.height * 0.18, size.width * 0.88, size.height * 0.12);
      default:
        return Path()
          ..moveTo(size.width * 0.22, size.height * 0.32)
          ..cubicTo(size.width * 0.28, size.height * 0.18, size.width * 0.46,
              size.height * 0.18, size.width * 0.52, size.height * 0.34)
          ..cubicTo(size.width * 0.58, size.height * 0.5, size.width * 0.82,
              size.height * 0.42, size.width * 0.78, size.height * 0.2);
    }
  }

  void _paintRoute(Canvas canvas, Size size) {
    final route = _routePath(size);
    final metrics = route.computeMetrics().toList();
    final dotPaint = Paint()
      ..isAntiAlias = true
      ..color = AppTheme.accent
      ..style = PaintingStyle.fill;

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          canvas.drawCircle(tangent.position, 3.5, dotPaint);
        }
        distance += 18;
      }
    }
  }

  void _paintMarkers(Canvas canvas, Size size) {
    final route = _routePath(size);
    final metrics = route.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;

    final startTangent = metric.getTangentForOffset(0);
    final endTangent = metric.getTangentForOffset(metric.length);

    if (startTangent != null) {
      _paintPickupMarker(canvas, startTangent.position);
    }
    if (endTangent != null) {
      _paintDestinationMarker(canvas, endTangent.position);
    }
  }

  void _paintPickupMarker(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = AppTheme.accent.withValues(alpha: 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      8.5,
      Paint()
        ..color = AppTheme.accent
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      8.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  void _paintDestinationMarker(Canvas canvas, Offset center) {
    final pin = Path()
      ..moveTo(center.dx, center.dy + 22)
      ..cubicTo(center.dx - 14, center.dy + 4, center.dx - 13, center.dy - 14,
          center.dx, center.dy - 14)
      ..cubicTo(center.dx + 13, center.dy - 14, center.dx + 14, center.dy + 4,
          center.dx, center.dy + 22)
      ..close();

    canvas.drawPath(
      pin.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(pin, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4.5, Paint()..color = AppTheme.accent);
  }

  void _paintBus(Canvas canvas, Size size) {
    final route = _routePath(size);
    final metrics = route.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final value = Curves.easeInOut.transform(animation.value);
    final tangent = metric.getTangentForOffset(metric.length * value);
    if (tangent == null) return;

    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    canvas.rotate(tangent.angle);
    canvas.translate(-19, -13);

    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 38, 26),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      bodyRect.shift(const Offset(0, 3)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(bodyRect, Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(6, 5, 11, 8), const Radius.circular(3)),
      Paint()..color = AppTheme.elevated,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          const Rect.fromLTWH(21, 5, 11, 8), const Radius.circular(3)),
      Paint()..color = AppTheme.elevated,
    );
    canvas.drawRect(
        const Rect.fromLTWH(5, 17, 28, 3), Paint()..color = AppTheme.accent);
    canvas.drawCircle(
        const Offset(9, 26), 3, Paint()..color = AppTheme.elevated);
    canvas.drawCircle(
        const Offset(29, 26), 3, Paint()..color = AppTheme.elevated);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OnboardingMapPainter old) =>
      old.animation != animation || old.variant != variant;
}
