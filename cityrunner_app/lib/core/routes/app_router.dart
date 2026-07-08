import 'package:flutter/material.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/booking/seat_selection_screen.dart';
import '../../screens/driver/driver_dashboard_screen.dart';
import '../../screens/passenger/passenger_home_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/tracking/tracking_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const roleSelection = '/role-selection';
  static const passengerHome = '/passenger';
  static const driverDashboard = '/driver';
  static const adminDashboard = '/admin';
  static const seatSelection = '/booking/seats';
  static const tracking = '/tracking';
}

class AppRouter {
  const AppRouter._();

  static final navigatorKey = GlobalKey<NavigatorState>();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) {
        switch (settings.name) {
          case AppRoutes.onboarding:
            return const OnboardingScreen();
          case AppRoutes.login:
            return const LoginScreen();
          case AppRoutes.roleSelection:
            return const RoleSelectionScreen();
          case AppRoutes.passengerHome:
            return const PassengerHomeScreen();
          case AppRoutes.seatSelection:
            return const SeatSelectionScreen();
          case AppRoutes.tracking:
            return const TrackingScreen();
          case AppRoutes.driverDashboard:
            return const DriverDashboardScreen();
          case AppRoutes.adminDashboard:
            return const AdminDashboardScreen();
          case AppRoutes.splash:
          default:
            return const SplashScreen();
        }
      },
    );
  }
}
