import 'package:flutter/material.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_chrome.dart';
import '../../widgets/brand_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();

  int currentPage = 0;

  final List<_SlideData> slides = const [
    _SlideData(
      title: 'Track. Book. Ride.',
      subtitle:
          'Live tracking, easy booking and safe journeys across the city.',
      icon: Icons.route,
    ),
    _SlideData(
      title: 'Choose Your Route',
      subtitle:
          'Find available buses instantly and plan your trip effortlessly.',
      icon: Icons.location_on,
    ),
    _SlideData(
      title: 'Safe & Reliable Travel',
      subtitle:
          'Real-time updates, secure bookings and dependable transport.',
      icon: Icons.verified_user,
    ),
  ];

  void _nextPage() {
    if (currentPage < slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.roleSelection,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BrandMark(compact: true),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.roleSelection,
                    );
                  },
                  child: const Text('Skip'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (value) {
                  setState(() {
                    currentPage = value;
                  });
                },
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppTheme.panel,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFF2B2B2B),
                          ),
                        ),
                        child: Icon(
                          slide.icon,
                          size: 90,
                          color: AppTheme.accent,
                        ),
                      ),

                      const SizedBox(height: 40),

                      Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        slide.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.muted,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                slides.length,
                (index) => Container(
                  width: currentPage == index ? 24 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: currentPage == index
                        ? AppTheme.accent
                        : Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            GradientButton(
              label: currentPage == slides.length - 1
                  ? 'Get Started'
                  : 'Next',
              icon: currentPage == slides.length - 1
                  ? Icons.check
                  : Icons.arrow_forward,
              onPressed: _nextPage,
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideData {
  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}