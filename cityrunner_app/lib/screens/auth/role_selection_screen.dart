import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../models/city_runner_models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/app_chrome.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected = UserRole.passenger;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    return PhoneFrame(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),

            // Back button
            Align(
              alignment: Alignment.centerLeft,
              child: IconCircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onPressed: () => Navigator.pop(context),
                size: 44,
                iconSize: 18,
              ),
            ),

            const SizedBox(height: 32),

            // Heading
            const Text(
              'Choose Your Role',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.text,
                fontFamily: 'Poppins',
                fontSize: 30,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Select a role to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.muted,
                fontFamily: 'Poppins',
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 40),

            // Passenger card
            _RoleCard(
              title: 'Passenger',
              subtitle: 'Book tickets and track your bus.',
              icon: Icons.person_outline_rounded,
              selected: _selected == UserRole.passenger,
              onTap: () => setState(() => _selected = UserRole.passenger),
            ),

            const SizedBox(height: 16),

            // Driver card
            _RoleCard(
              title: 'Driver',
              subtitle: 'Drive, manage and track your trips.',
              icon: Icons.drive_eta_outlined,
              selected: _selected == UserRole.driver,
              onTap: () => setState(() => _selected = UserRole.driver),
            ),

            const SizedBox(height: 16),

            // Admin card (compact)
            _RoleCard(
              title: 'Admin',
              subtitle: 'Fleet and system management.',
              icon: Icons.admin_panel_settings_outlined,
              selected: _selected == UserRole.admin,
              onTap: () => setState(() => _selected = UserRole.admin),
              compact: true,
            ),

            const SizedBox(height: 40),

            // Continue button
            PrimaryButton(
              label: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: _selected == null
                  ? null
                  : () {
                      final role = _selected!;
                      app.selectRole(role);

                      if (role == UserRole.passenger) {
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.passengerHome);
                      } else if (role == UserRole.driver) {
                        if (app.driverToken == null) {
                          Navigator.pushNamed(context, AppRoutes.login,
                              arguments: UserRole.driver);
                        } else {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.driverDashboard);
                        }
                      } else {
                        if (app.adminToken == null) {
                          Navigator.pushNamed(context, AppRoutes.login,
                              arguments: UserRole.admin);
                        } else {
                          Navigator.pushReplacementNamed(
                              context, AppRoutes.adminDashboard);
                        }
                      }
                    },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact ? 28.0 : 38.0;
    final containerSize = widget.compact ? 56.0 : 72.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.all(widget.compact ? 16 : 20),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppTheme.accent.withValues(alpha: 0.06)
                : AppTheme.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.selected
                  ? AppTheme.accent
                  : const Color(0xFF2B2B2B),
              width: widget.selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.selected
                    ? AppTheme.accent.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: widget.selected
                      ? AppTheme.accent.withValues(alpha: 0.15)
                      : AppTheme.elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.selected
                        ? AppTheme.accent.withValues(alpha: 0.3)
                        : const Color(0xFF2B2B2B),
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.selected ? AppTheme.accent : AppTheme.text,
                  size: iconSize,
                ),
              ),

              const SizedBox(width: 18),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: AppTheme.text,
                        fontFamily: 'Poppins',
                        fontSize: widget.compact ? 16 : 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Selection indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.selected ? AppTheme.accent : Colors.transparent,
                  border: Border.all(
                    color: widget.selected
                        ? AppTheme.accent
                        : const Color(0xFF3A3A3A),
                    width: 2,
                  ),
                ),
                child: widget.selected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}