import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/city_runner_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_chrome.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final driver = app.driverUser;
    final bus = app.driverDashboard?.bus;
    final driverName = driver?.displayName ?? 'Driver';
    final driverId = driver?.username ?? 'DRV-001';
    final isOnline = bus?.isActive ?? false;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // ── Header ─────────────────────────────────────────────────
              Row(
                children: [
                  IconCircleButton(
                    icon: Icons.menu_rounded,
                    onPressed: () => _openMenu(context, driverName),
                    size: 46,
                  ),
                  const Spacer(),
                  IconCircleButton(
                    icon: Icons.notifications_outlined,
                    onPressed: () => _openNotifications(context),
                    size: 46,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Driver profile ─────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.elevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isOnline
                            ? Colors.green.withValues(alpha: 0.6)
                            : const Color(0xFF2B2B2B),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppTheme.text,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontFamily: 'Poppins',
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          driverName,
                          style: const TextStyle(
                            color: AppTheme.text,
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'ID: $driverId',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontFamily: 'Poppins',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Online toggle ──────────────────────────────────────────
              _OnlineToggle(
                isOnline: isOnline,
                onToggle: bus == null
                    ? null
                    : () => context.read<AppProvider>().toggleBusStatus(),
              ),

              const SizedBox(height: 24),

              // ── Stats row ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: "Today's Trips",
                      value: '6',
                      icon: Icons.route_rounded,
                      iconColor: AppTheme.accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      label: "Earnings",
                      value: '₹1,240',
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: Colors.green,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Upcoming ride card ─────────────────────────────────────
              const Text(
                'Upcoming Ride',
                style: TextStyle(
                  color: AppTheme.text,
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              CityPanel(
                child: Column(
                  children: [
                    _RouteRow(
                      icon: Icons.radio_button_checked_rounded,
                      iconColor: AppTheme.accent,
                      label: 'Pickup',
                      value: bus?.stops.isNotEmpty == true
                          ? bus!.stops.first.name
                          : 'Gangtok Bus Stand',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(width: 18),
                        Container(
                          width: 2,
                          height: 20,
                          color: const Color(0xFF2B2B2B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _RouteRow(
                      icon: Icons.location_on_rounded,
                      iconColor: Colors.white,
                      label: 'Destination',
                      value: bus?.stops.isNotEmpty == true
                          ? bus!.stops.last.name
                          : 'Ranipool',
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2B2B2B), height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: AppTheme.muted,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bus?.etaMinutes != null
                              ? 'ETA: ${bus!.etaMinutes} min'
                              : 'Scheduled: 10:30 AM',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontFamily: 'Poppins',
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            bus?.isActive == true ? 'Active' : 'Scheduled',
                            style: const TextStyle(
                              color: AppTheme.accent,
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Go to current location button ──────────────────────────
              PrimaryButton(
                label: 'Go to Current Location',
                icon: Icons.my_location_rounded,
                onPressed: () =>
                    context.read<AppProvider>().syncDriverLocationNow(),
                busy: app.busyAction == 'driver-sync',
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _openMenu(BuildContext context, String driverName) {
    showAppMenuSheet(
      context,
      name: driverName,
      subtitle: 'Driver',
      actions: [
        MenuAction(
          icon: Icons.route_rounded,
          label: 'Trip History',
          onTap: () => _showComingSoon(context, 'Trip History'),
        ),
        MenuAction(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          onTap: () => _openChangePassword(context),
        ),
        MenuAction(
          icon: Icons.help_outline_rounded,
          label: 'Help & Support',
          onTap: () => _showComingSoon(context, 'Help & Support'),
        ),
        MenuAction(
          icon: Icons.logout_rounded,
          label: 'Log Out',
          danger: true,
          onTap: () async {
            await context.read<AppProvider>().logout(UserRole.driver);
            if (!context.mounted) return;
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.roleSelection,
              (_) => false,
            );
          },
        ),
      ],
    );
  }

  void _openNotifications(BuildContext context) {
    showNotificationsSheet(
      context,
      items: const [
        NotificationItemData(
          icon: Icons.person_pin_circle_rounded,
          title: 'New ride request',
          subtitle: 'A passenger is waiting at Gangtok Bus Stand.',
          time: 'now',
          accent: true,
        ),
        NotificationItemData(
          icon: Icons.event_seat_rounded,
          title: 'Seat map updated',
          subtitle: '3 seats were booked on your current route.',
          time: '10m ago',
        ),
        NotificationItemData(
          icon: Icons.info_outline_rounded,
          title: 'Shift reminder',
          subtitle: 'Your shift starts at 10:30 AM.',
          time: 'Yesterday',
        ),
      ],
    );
  }

  void _openChangePassword(BuildContext context) {
    final current = TextEditingController();
    final next = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.panel,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Change Password',
          style: TextStyle(color: AppTheme.text, fontFamily: 'Poppins'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CityTextField(
              controller: current,
              hint: 'Current password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            CityTextField(
              controller: next,
              hint: 'New password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.muted, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () async {
              final app = context.read<AppProvider>();
              await app.changePassword(current.text, next.text);
              final failed = app.errorMessage != null;
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    failed ? app.errorMessage! : 'Password updated.',
                  ),
                ),
              );
              if (failed) app.clearMessages();
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppTheme.accent,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature is coming soon.')));
  }
}

// ─── Online toggle ────────────────────────────────────────────────────────────
class _OnlineToggle extends StatelessWidget {
  const _OnlineToggle({required this.isOnline, required this.onToggle});

  final bool isOnline;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 72,
        decoration: BoxDecoration(
          color: isOnline
              ? Colors.green.withValues(alpha: 0.12)
              : AppTheme.elevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isOnline
                ? Colors.green.withValues(alpha: 0.4)
                : const Color(0xFF2B2B2B),
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withValues(alpha: 0.2)
                      : AppTheme.panel,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOnline
                        ? Colors.green.withValues(alpha: 0.5)
                        : const Color(0xFF2B2B2B),
                  ),
                ),
                child: Icon(
                  isOnline
                      ? Icons.wifi_tethering_rounded
                      : Icons.wifi_tethering_off_rounded,
                  color: isOnline ? Colors.green : AppTheme.muted,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOnline ? 'You are Online' : 'You are Offline',
                      style: TextStyle(
                        color: isOnline ? Colors.green : AppTheme.text,
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      isOnline ? 'Accepting ride requests' : 'Tap to go online',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Toggle switch
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : const Color(0xFF2B2B2B),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment: isOnline
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
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

// ─── Stat card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return CityPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.text,
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontFamily: 'Poppins',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Route row ────────────────────────────────────────────────────────────────
class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontFamily: 'Poppins',
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.text,
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
