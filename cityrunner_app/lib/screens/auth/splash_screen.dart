import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/app_chrome.dart';
import '../../widgets/brand_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PhoneFrame(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BusHeroArt(size: 170),
            const SizedBox(height: 16),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900),
                children: [
                  TextSpan(text: 'CITY'),
                  TextSpan(text: 'RUNNER', style: TextStyle(color: AppTheme.accent)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Text(AppConstants.tagline, style: TextStyle(color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
